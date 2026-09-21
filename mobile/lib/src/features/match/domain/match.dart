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
        this.isPending = false,
        this.rejectedReason,
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

    /// True while the donor's answer is written on the device but has not reached
    /// the server. The inbox and the detail screen both badge it.
    final bool isPending;

    /// Set when a queued answer was refused on arrival — the request had already
    /// closed. Server-wins, stated rather than swallowed.
    final String? rejectedReason;

    /// Null when the push was never sent — no FCM token, or a send that failed. The
    /// match is still real; that is the reason this inbox exists rather than relying
    /// on the notification alone.
    final DateTime? notifiedAt;

    Match copyWith({
        MatchResponseType? response,
        BloodRequest? request,
        bool? isPending,
        String? rejectedReason,
    }) => Match(
        matchId: matchId,
        request: request ?? this.request,
        myBloodType: myBloodType,
        notifiedAt: notifiedAt,
        response: response ?? this.response,
        isPending: isPending ?? this.isPending,
        rejectedReason: rejectedReason ?? this.rejectedReason,
    );
}
