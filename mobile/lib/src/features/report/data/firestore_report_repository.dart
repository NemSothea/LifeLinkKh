import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/firestore_failure_mapper.dart';
import '../../../core/error/result.dart';
import '../domain/report_reason.dart';
import '../domain/report_repository.dart';

/// `reports/{requestId}_{uid}` — the same id as the donor's match, which is how the rules
/// know the reporter was alerted to the request, and why a second report is refused.
final class FirestoreReportRepository implements ReportRepository {
    FirestoreReportRepository(this._db, this._currentUid);

    final FirebaseFirestore _db;
    final String? Function() _currentUid;

    /// A write made offline waits for the server; a report is not worth queueing silently,
    /// so past this the donor is told there is no connection and can try again.
    static const Duration _timeout = Duration(seconds: 15);

    @override
    Future<Result<void>> report({
        required String requestId,
        required ReportReason reason,
        String? note,
    }) async {
        final uid = _currentUid();
        if (uid == null) return const Failed(UnauthorizedFailure());
        final trimmed = note?.trim();
        try {
            await _db.doc('reports/${requestId}_$uid').set({
                'requestId': requestId,
                'reporterUid': uid,
                'reason': reason.wireValue,
                'note': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
                'createdAt': FieldValue.serverTimestamp(),
            }).timeout(_timeout);
            return const Success(null);
        } on TimeoutException {
            return const Failed(NetworkFailure());
        } on FirebaseException catch (error) {
            return Failed(failureFromFirebase(error));
        }
    }
}
