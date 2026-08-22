import '../../../core/error/result.dart';
import 'match.dart';
import 'match_response_type.dart';
import 'respond_result.dart';

/// `GET /matches/me` and `POST /matches/{id}/respond`, as the rest of the app sees them.
abstract interface class MatchRepository {
    /// The donor's inbox.
    Future<Result<List<Match>>> fetchMine();

    /// Accept or decline. A second call on the same match is a 409, mapped to a
    /// [Failure] — one response, never overwritten in this build.
    Future<Result<RespondResult>> respond(String matchId, MatchResponseType response);
}
