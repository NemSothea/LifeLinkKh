// ignore_for_file: prefer_initializing_formals — the fields are private and Dart
// forbids a named parameter that starts with an underscore, so the lint's fix does not
// compile here.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/firestore_failure_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/location/geohash.dart';
import '../domain/blood_type.dart';
import '../domain/district.dart';
import '../domain/donor_profile.dart';
import '../domain/donor_profile_draft.dart';
import '../domain/donor_repository.dart';
import '../domain/eligibility.dart';

/// `donors/{uid}` and `districts` on Firestore (ADR 0009) — what `GET`/`PUT /donors/me`
/// and `GET /districts` were.
///
/// The document shape is `docs/tech-lead/firestore-data-model.md`, and
/// `firebase/firestore.rules` refuses any write that strays from it. The rules require
/// every field on every write, which is why [saveProfile] always writes the whole
/// document rather than the fields the draft changed.
final class FirestoreDonorRepository implements DonorRepository {
    FirestoreDonorRepository(
        this._db, {
        required String? Function() currentUid,
        DateTime Function()? now,
    })  : _currentUid = currentUid,
          _now = now ?? DateTime.now;

    final FirebaseFirestore _db;
    final String? Function() _currentUid;
    final DateTime Function() _now;

    static const String donorsCollection = 'donors';
    static const String districtsCollection = 'districts';

    @override
    Future<Result<DonorProfile?>> fetchProfile() async {
        final uid = _currentUid();
        if (uid == null) return const Failed(UnauthorizedFailure());
        try {
            final snapshot = await _db.collection(donorsCollection).doc(uid).get();
            final data = snapshot.data();
            // No document is "no profile yet", which is where every donor starts — the 404
            // the Dio repository turned into Success(null).
            if (data == null) return const Success(null);
            return Success(await _profileFrom(uid, data));
        } on FirebaseException catch (error) {
            return Failed(failureFromFirebase(error));
        } on FormatException catch (error) {
            return Failed(UnknownFailure(message: error.message));
        }
    }

    @override
    Future<Result<DonorProfile>> saveProfile(DonorProfileDraft draft) async {
        final uid = _currentUid();
        if (uid == null) return const Failed(UnauthorizedFailure());
        final bloodType = draft.bloodType;
        final districtCode = draft.districtCode;
        if (!draft.isComplete || bloodType == null || districtCode == null) {
            return const Failed(ValidationFailure(code: 'INCOMPLETE_PROFILE'));
        }
        if ((draft.latitude == null) != (draft.longitude == null) && draft.updateCoordinates) {
            return const Failed(ValidationFailure(code: 'INCOMPLETE_COORDINATES'));
        }
        try {
            final ref = _db.collection(donorsCollection).doc(uid);
            final existing = (await ref.get()).data();

            // CR-MAPI-004, kept: an edit that never touched location leaves stored GPS alone.
            final keepCoordinates = !draft.updateCoordinates && existing != null;
            final lat = keepCoordinates ? existing['lat'] as num? : draft.latitude;
            final lng = keepCoordinates ? existing['lng'] as num? : draft.longitude;
            final geohash = keepCoordinates
                ? existing['geohash'] as String?
                : (lat != null && lng != null ? encodeGeohash(lat.toDouble(), lng.toDouble()) : null);

            await ref.set({
                'fullName': draft.fullName.trim(),
                'bloodType': bloodType.wireValue,
                'districtCode': districtCode,
                'lastDonationDate': _dateToTimestamp(draft.lastDonationDate),
                'isAvailable': draft.isAvailable,
                'lat': lat,
                'lng': lng,
                'geohash': geohash,
                // The rules pin createdAt to the stored value on update and to the request
                // time on create, so it is carried over, never re-stamped.
                'createdAt': existing?['createdAt'] ?? FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
            });

            final district = await _district(districtCode);
            final lastDonationDate = _dateOnly(draft.lastDonationDate);
            return Success(DonorProfile(
                id: uid,
                fullName: draft.fullName.trim(),
                bloodType: bloodType,
                districtCode: districtCode,
                districtNameKm: district?.nameKm ?? '',
                districtNameEn: district?.nameEn ?? '',
                lastDonationDate: lastDonationDate,
                isAvailable: draft.isAvailable,
                eligibility: Eligibility.forLastDonation(lastDonationDate, _now()),
            ));
        } on FirebaseException catch (error) {
            return Failed(failureFromFirebase(error));
        }
    }

    @override
    Future<Result<List<District>>> fetchDistricts() async {
        try {
            final snapshot = await _db.collection(districtsCollection).orderBy(FieldPath.documentId).get();
            return Success([
                for (final doc in snapshot.docs) _districtFrom(doc.id, doc.data()),
            ]);
        } on FirebaseException catch (error) {
            return Failed(failureFromFirebase(error));
        }
    }

    Future<DonorProfile> _profileFrom(String uid, Map<String, dynamic> data) async {
        final bloodType = BloodType.fromWire(data['bloodType'] as String?);
        final districtCode = data['districtCode'];
        if (bloodType == null || districtCode is! String) {
            // No defaults. A profile with a guessed blood type is a donor who gets matched to
            // the wrong patient.
            throw const FormatException('donor document is not usable');
        }
        final district = await _district(districtCode);
        final lastDonationDate = _timestampToDate(data['lastDonationDate']);
        return DonorProfile(
            id: uid,
            fullName: data['fullName'] as String? ?? '',
            bloodType: bloodType,
            districtCode: districtCode,
            districtNameKm: district?.nameKm ?? '',
            districtNameEn: district?.nameEn ?? '',
            lastDonationDate: lastDonationDate,
            isAvailable: data['isAvailable'] as bool? ?? true,
            eligibility: Eligibility.forLastDonation(lastDonationDate, _now()),
        );
    }

    Future<District?> _district(String code) async {
        final snapshot = await _db.collection(districtsCollection).doc(code).get();
        final data = snapshot.data();
        return data == null ? null : _districtFrom(code, data);
    }

    static District _districtFrom(String code, Map<String, dynamic> data) => District(
        code: code,
        nameKm: data['nameKm'] as String? ?? '',
        nameEn: data['nameEn'] as String? ?? '',
    );

    static DateTime? _dateOnly(DateTime? value) =>
        value == null ? null : DateTime(value.year, value.month, value.day);

    /// A calendar date stored as local midnight. Not UTC midnight: in Phnom Penh (UTC+7)
    /// "today" at UTC midnight is still in the future for the first seven hours of the day,
    /// and the rules refuse a last-donation date in the future.
    static Timestamp? _dateToTimestamp(DateTime? value) {
        final date = _dateOnly(value);
        return date == null ? null : Timestamp.fromDate(date);
    }

    static DateTime? _timestampToDate(Object? value) {
        if (value is! Timestamp) return null;
        return _dateOnly(value.toDate());
    }
}
