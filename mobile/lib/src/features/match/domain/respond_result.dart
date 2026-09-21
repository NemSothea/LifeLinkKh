import '../../request/domain/requester_contact.dart';
import 'match_response_type.dart';

/// What `POST /matches/{id}/respond` answers with.
final class RespondResult {
    const RespondResult({
        required this.matchId,
        required this.response,
        required this.respondedAt,
        this.requesterContact,
        this.isPending = false,
    });

    final String matchId;
    final MatchResponseType response;
    final DateTime respondedAt;

    /// True when the answer was written on the device and queued instead of sent:
    /// the network was unreachable. The answer is real and the donor sees it, but
    /// nobody at the hospital knows yet — which is why the UI badges it rather
    /// than presenting it as delivered.
    final bool isPending;

    /// Present only for [MatchResponseType.accepted]. Null for a decline — null,
    /// not an empty object, so a client bug reads as a crash rather than a contact
    /// card with blank fields. Also null for a queued acceptance: the contact is
    /// the server's to reveal, and offline there is no server to reveal it.
    final RequesterContact? requesterContact;
}
