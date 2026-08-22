import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../../request/application/request_providers.dart';
import '../data/dio_match_repository.dart';
import '../domain/match.dart';
import '../domain/match_repository.dart';
import '../domain/match_response_type.dart';
import '../domain/respond_result.dart';
import 'match_service.dart';

part 'match_providers.g.dart';

@Riverpod(keepAlive: true)
MatchRepository matchRepository(MatchRepositoryRef ref) => DioMatchRepository(
    ref.watch(apiClientProvider),
    ref.watch(dioRequestRepositoryProvider),
);

@Riverpod(keepAlive: true)
MatchService matchService(MatchServiceRef ref) => MatchService(ref.watch(matchRepositoryProvider));

/// The donor's inbox. `keepAlive` so it survives navigating into and back out of
/// a match's detail screen.
@Riverpod(keepAlive: true)
class MyMatchesController extends _$MyMatchesController {
    @override
    Future<List<Match>> build() async {
        final result = await ref.watch(matchServiceProvider).loadMine();
        return switch (result) {
            Success(value: final matches) => matches,
            Failed(failure: final failure) => throw failure,
        };
    }

    /// Accepts or declines, then folds the result into the cached list in place —
    /// a full reload would flash a spinner over an inbox the donor is mid-read on.
    Future<Result<RespondResult>> respond(String matchId, MatchResponseType response) async {
        final result = await ref.read(matchServiceProvider).respond(matchId, response);
        if (result case Success(value: final respondResult)) {
            final current = state.valueOrNull;
            if (current != null) {
                state = AsyncData([
                    for (final match in current)
                        if (match.matchId == matchId)
                            match.copyWith(
                                response: respondResult.response,
                                request: respondResult.requesterContact == null
                                    ? match.request
                                    : match.request.withRequesterContact(
                                        respondResult.requesterContact!,
                                    ),
                            )
                        else
                            match,
                ]);
            }
        }
        return result;
    }
}
