import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/donor/domain/blood_type.dart';
import 'package:lifelink_kh/src/features/match/data/firestore_match_repository.dart';
import 'package:lifelink_kh/src/features/match/domain/match.dart';
import 'package:lifelink_kh/src/features/match/domain/match_response_type.dart';
import 'package:lifelink_kh/src/features/match/domain/respond_result.dart';
import 'package:lifelink_kh/src/features/request/data/firestore_request_repository.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

/// The donor's `matches` (ADR 0009) — the Firestore counterpart of
/// `dio_match_repository_test.dart`. The rules that refuse a second answer are tested for
/// real in `firebase/rules-tests/`; here a refusal is thrown by hand to test what the
/// repository makes of it.
void main() {
    late FakeFirebaseFirestore db;
    String? uid;
    late FirestoreMatchRepository repository;

    setUp(() async {
        db = FakeFirebaseFirestore();
        uid = 'sothea';
        repository = FirestoreMatchRepository(
            db,
            FirestoreRequestRepository(db, currentUid: () => uid),
            currentUid: () => uid,
            writeWait: const Duration(milliseconds: 300),
        );
        await db.doc('hospitals/calmette').set({'name': 'Calmette Hospital', 'districtCode': '1202'});
        await db.doc('donors/sothea').set({'fullName': 'Nem Sothea', 'bloodType': 'A+', 'districtCode': '1201'});
        await db.doc('requests/r1').set({
            'createdBy': 'family', 'hospitalId': 'calmette', 'patientBloodType': 'AB+', 'unitsNeeded': 2,
            'urgency': 'CRITICAL', 'status': 'OPEN', 'alertedCount': 1, 'acceptedCount': 0,
            'createdAt': Timestamp.fromDate(DateTime(2026, 9, 26, 10)),
        });
        await db.doc('requests/r1/private/contact').set({'contactName': 'Chea Srey', 'contactPhone': '+85512345678'});
        await db.doc('matches/r1_sothea').set({
            'requestId': 'r1', 'donorUid': 'sothea', 'requesterUid': 'family', 'hospitalId': 'calmette',
            'distanceKm': 0.5, 'notifiedAt': Timestamp.fromDate(DateTime(2026, 9, 26, 10, 1)),
            'response': null, 'respondedAt': null,
        });
    });

    group('fetchMine', () {
        test('my match, with the request, the distance and my blood type — no contact yet', () async {
            final matches = (await repository.fetchMine() as Success<List<Match>>).value;
            expect(matches, hasLength(1));
            final match = matches.single;
            expect(match.matchId, 'r1_sothea');
            expect(match.myBloodType, BloodType.aPositive);
            expect(match.request.patientBloodType, BloodType.abPositive);
            expect(match.request.hospitalName, 'Calmette Hospital');
            expect(match.request.distanceKm, 0.5);
            expect(match.response, isNull);
            // RequestViews: nobody but the creator and an accepted donor sees the contact.
            expect(match.request.requesterContact, isNull);
        });

        test('once accepted, the contact is on it', () async {
            await db.doc('matches/r1_sothea').update({'response': 'ACCEPTED'});
            final match = (await repository.fetchMine() as Success<List<Match>>).value.single;
            expect(match.response, MatchResponseType.accepted);
            expect(match.request.requesterContact?.phone, '+85512345678');
        });

        test('someone else\'s matches are not mine', () async {
            await db.doc('matches/r1_other').set({'requestId': 'r1', 'donorUid': 'other', 'response': null});
            expect((await repository.fetchMine() as Success<List<Match>>).value.map((m) => m.matchId), ['r1_sothea']);
        });

        test('a silent match (never pushed) still lists, after the notified ones', () async {
            await db.doc('requests/r2').set((await db.doc('requests/r1').get()).data()!);
            await db.doc('matches/r2_sothea').set({'requestId': 'r2', 'donorUid': 'sothea', 'notifiedAt': null, 'response': null});
            final ids = (await repository.fetchMine() as Success<List<Match>>).value.map((m) => m.matchId);
            expect(ids, ['r1_sothea', 'r2_sothea']);
        });

        test('no donor profile is no matches, not a failure', () async {
            await db.doc('donors/sothea').delete();
            expect((await repository.fetchMine() as Success<List<Match>>).value, isEmpty);
        });
    });

    group('respond', () {
        test('accepting writes the answer and returns the family\'s contact', () async {
            final result = (await repository.respond('r1_sothea', MatchResponseType.accepted) as Success<RespondResult>).value;
            expect(result.response, MatchResponseType.accepted);
            expect(result.requesterContact?.displayName, 'Chea Srey');
            expect((await db.doc('matches/r1_sothea').get()).get('response'), 'ACCEPTED');
        });

        test('declining returns no contact', () async {
            final result = (await repository.respond('r1_sothea', MatchResponseType.declined) as Success<RespondResult>).value;
            expect(result.requesterContact, isNull);
        });

        test('a replay of the answer already stored is success — the idempotency key\'s job', () async {
            await db.doc('matches/r1_sothea').update({'response': 'ACCEPTED'});
            whenCalling(Invocation.method(#update, null))
                .on(db.doc('matches/r1_sothea'))
                .thenThrow(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
            expect(await repository.respond('r1_sothea', MatchResponseType.accepted), isA<Success<RespondResult>>());
        });

        test('a different answer after one is stored is ALREADY_RESPONDED', () async {
            await db.doc('matches/r1_sothea').update({'response': 'DECLINED'});
            whenCalling(Invocation.method(#update, null))
                .on(db.doc('matches/r1_sothea'))
                .thenThrow(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
            final failure = (await repository.respond('r1_sothea', MatchResponseType.accepted) as Failed<RespondResult>).failure;
            expect(failure, isA<ConflictFailure>().having((f) => f.code, 'code', 'ALREADY_RESPONDED'));
        });

        test('refused while still unanswered means the request closed', () async {
            whenCalling(Invocation.method(#update, null))
                .on(db.doc('matches/r1_sothea'))
                .thenThrow(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
            final failure = (await repository.respond('r1_sothea', MatchResponseType.accepted) as Failed<RespondResult>).failure;
            expect(failure, isA<ConflictFailure>().having((f) => f.code, 'code', 'REQUEST_NOT_OPEN'));
        });

        test('offline is NetworkFailure, so the offline-first wrapper queues it', () async {
            whenCalling(Invocation.method(#update, null))
                .on(db.doc('matches/r1_sothea'))
                .thenThrow(FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'));
            final failure = (await repository.respond('r1_sothea', MatchResponseType.accepted) as Failed<RespondResult>).failure;
            expect(failure, isA<NetworkFailure>());
        });

        test('signed out is UnauthorizedFailure', () async {
            uid = null;
            final failure = (await repository.respond('r1_sothea', MatchResponseType.accepted) as Failed<RespondResult>).failure;
            expect(failure, isA<UnauthorizedFailure>());
        });
    });
}
