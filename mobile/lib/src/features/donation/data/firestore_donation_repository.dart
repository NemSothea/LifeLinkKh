// ignore_for_file: prefer_initializing_formals — the fields are private and Dart
// forbids a named parameter that starts with an underscore, so the lint's fix does not
// compile here.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/firestore_failure_mapper.dart';
import '../../../core/error/result.dart';
import '../domain/donation.dart';
import '../domain/donation_repository.dart';

/// The signed-in donor's `donations` on Firestore (ADR 0009) — what `GET /donations/me` was.
///
/// Newest first, same as `findByDonorProfileIdOrderByDonatedOnDesc`. The hospital and its
/// district are joined here, one read per distinct hospital: a donor's history is a
/// handful of rows, and denormalizing the names onto each donation would freeze a
/// hospital's old name into every record that mentions it.
final class FirestoreDonationRepository implements DonationRepository {
    FirestoreDonationRepository(this._db, {required String? Function() currentUid})
        : _currentUid = currentUid;

    final FirebaseFirestore _db;
    final String? Function() _currentUid;

    @override
    Future<Result<List<Donation>>> fetchMine() async {
        final uid = _currentUid();
        if (uid == null) return const Failed(UnauthorizedFailure());
        try {
            final snapshot = await _db
                .collection('donations')
                // The rules only allow a donor to read their own, so this filter is also
                // what makes the query permitted at all — a query the rules cannot prove
                // safe is refused whole.
                .where('donorUid', isEqualTo: uid)
                .orderBy('donatedOn', descending: true)
                .get();

            final hospitals = <String, _Hospital?>{};
            final donations = <Donation>[];
            for (final doc in snapshot.docs) {
                final data = doc.data();
                final donatedOn = data['donatedOn'];
                if (donatedOn is! Timestamp) {
                    // No defaults. A donation with a guessed date is the 56-day cooldown lying.
                    throw const FormatException('donation document has no date');
                }
                final hospitalId = data['hospitalId'] as String?;
                final hospital = hospitalId == null
                    ? null
                    : hospitals[hospitalId] ??= await _hospital(hospitalId);
                final date = donatedOn.toDate();
                donations.add(Donation(
                    id: doc.id,
                    donatedOn: DateTime(date.year, date.month, date.day),
                    hospitalName: hospital?.name,
                    hospitalDistrictKm: hospital?.districtKm,
                    hospitalDistrictEn: hospital?.districtEn,
                    bloodRequestId: data['requestId'] as String?,
                ));
            }
            return Success(donations);
        } on FirebaseException catch (error) {
            return Failed(failureFromFirebase(error));
        } on FormatException catch (error) {
            return Failed(UnknownFailure(message: error.message));
        }
    }

    Future<_Hospital?> _hospital(String id) async {
        final hospital = (await _db.collection('hospitals').doc(id).get()).data();
        if (hospital == null) return null;
        final code = hospital['districtCode'] as String?;
        final district = code == null ? null : (await _db.collection('districts').doc(code).get()).data();
        return _Hospital(
            name: hospital['name'] as String?,
            districtKm: district?['nameKm'] as String?,
            districtEn: district?['nameEn'] as String?,
        );
    }
}

final class _Hospital {
    const _Hospital({this.name, this.districtKm, this.districtEn});

    final String? name;
    final String? districtKm;
    final String? districtEn;
}
