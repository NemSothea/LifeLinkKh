import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/features/donor/domain/blood_type.dart';
import 'package:lifelink_kh/src/features/match/domain/match.dart';
import 'package:lifelink_kh/src/features/match/domain/match_response_type.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request.dart';
import 'package:lifelink_kh/src/features/request/domain/request_status.dart';
import 'package:lifelink_kh/src/features/request/domain/urgency.dart';

/// An alert is a call to action only while its request is still OPEN. One fulfilled or
/// cancelled before the donor answered used to stay on Home as a CRITICAL row with Accept.
void main() {
    Match matchOn(RequestStatus status, {MatchResponseType? response}) => Match(
        matchId: 'req-1_donor-1',
        request: BloodRequest(
            id: 'req-1',
            status: status,
            patientBloodType: BloodType.oPositive,
            unitsNeeded: 1,
            urgency: Urgency.critical,
            hospitalName: 'Calmette Hospital',
            alertedCount: 8,
            acceptedCount: 1,
            createdAt: DateTime(2026, 9, 22, 9),
            distanceKm: 2.5,
        ),
        myBloodType: BloodType.oPositive,
        notifiedAt: DateTime(2026, 9, 22, 9, 1),
        response: response,
    );

    test('an unanswered alert on an open request awaits an answer', () {
        expect(matchOn(RequestStatus.open).awaitsAnswer, isTrue);
    });

    test('an unanswered alert on a closed request does not', () {
        for (final closed in [RequestStatus.fulfilled, RequestStatus.cancelled, RequestStatus.expired]) {
            expect(matchOn(closed).awaitsAnswer, isFalse, reason: closed.name);
        }
    });

    test('an answered alert never does', () {
        expect(matchOn(RequestStatus.open, response: MatchResponseType.accepted).awaitsAnswer, isFalse);
    });
}
