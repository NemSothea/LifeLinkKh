import '../../donor/domain/blood_type.dart';
import '../../request/domain/blood_request.dart';
import 'match_response_type.dart';

/// One entry in a donor's alert inbox — `GET /matches/me`.
final class Match {
    const Match({
        required this.matchId,
        required this.request,
        required this.myBloodType,
        required this.notifiedAt,
        this.response,
    });

    final String matchId;

    /// Carries `distanceKm`, and — once this donor has accepted — `requesterContact`.
    /// There is no separate `GET /requests/{id}` call on this screen; the server
    /// already builds the same detail shape into this response.
    final BloodRequest request;

    /// Echoed so the screen can say "your O− blood is compatible" — without it a
    /// donor who knows their own type would assume the app is broken.
    final BloodType myBloodType;

    /// Null until the donor answers. Once set it never changes in this build.
    final MatchResponseType? response;

    /// Null when the push was never sent — no FCM token, or a send that failed. The
    /// match is still real; that is the reason this inbox exists rather than relying
    /// on the notification alone.
    final DateTime? notifiedAt;

    Match copyWith({MatchResponseType? response, BloodRequest? request}) => Match(
        matchId: matchId,
        request: request ?? this.request,
        myBloodType: myBloodType,
        notifiedAt: notifiedAt,
        response: response ?? this.response,
    );
}
