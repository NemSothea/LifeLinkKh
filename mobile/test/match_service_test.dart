import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/donor/domain/blood_type.dart';
import 'package:lifelink_kh/src/features/match/application/match_service.dart';
import 'package:lifelink_kh/src/features/match/domain/match.dart';
import 'package:lifelink_kh/src/features/match/domain/match_repository.dart';
import 'package:lifelink_kh/src/features/match/domain/match_response_type.dart';
import 'package:lifelink_kh/src/features/match/domain/respond_result.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request.dart';
import 'package:lifelink_kh/src/features/request/domain/request_status.dart';
import 'package:lifelink_kh/src/features/request/domain/urgency.dart';

void main() {
    late _FakeMatchRepository repository;

    MatchService serviceUnder() => MatchService(repository);

    setUp(() => repository = _FakeMatchRepository());

    test('loadMine passes the inbox through untouched', () async {
        final matches = (await serviceUnder().loadMine()).valueOrNull!;

        expect(matches.single.matchId, 'match-1');
    });

    test('respond reaches the repository with the chosen response', () async {
        await serviceUnder().respond('match-1', MatchResponseType.accepted);

        expect(repository.respondedWith, MatchResponseType.accepted);
    });
}

Match _match() => Match(
    matchId: 'match-1',
    request: BloodRequest(
        id: 'req-1',
        status: RequestStatus.open,
        patientBloodType: BloodType.aPositive,
        unitsNeeded: 1,
        urgency: Urgency.urgent,
        hospitalName: 'Calmette Hospital',
        alertedCount: 12,
        acceptedCount: 0,
        createdAt: DateTime(2026, 8, 7, 9, 14),
        distanceKm: 2.5,
    ),
    myBloodType: BloodType.oNegative,
    notifiedAt: DateTime(2026, 8, 7, 9, 14),
);

final class _FakeMatchRepository implements MatchRepository {
    MatchResponseType? respondedWith;

    @override
    Future<Result<List<Match>>> fetchMine() async => Success([_match()]);

    @override
    Future<Result<RespondResult>> respond(String matchId, MatchResponseType response) async {
        respondedWith = response;
        return Success(
            RespondResult(matchId: matchId, response: response, respondedAt: DateTime(2026, 8, 7)),
        );
    }
}
