import '../../../core/error/result.dart';
import '../domain/match.dart';
import '../domain/match_repository.dart';
import '../domain/match_response_type.dart';
import '../domain/respond_result.dart';

/// The MATCH feature's service. No Flutter import, no Riverpod import.
final class MatchService {
    const MatchService(this._repository);

    final MatchRepository _repository;

    Future<Result<List<Match>>> loadMine() => _repository.fetchMine();

    Future<Result<RespondResult>> respond(String matchId, MatchResponseType response) =>
        _repository.respond(matchId, response);
}
