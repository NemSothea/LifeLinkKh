import '../../request/domain/requester_contact.dart';
import 'match_response_type.dart';

/// What `POST /matches/{id}/respond` answers with.
final class RespondResult {
    const RespondResult({
        required this.matchId,
        required this.response,
        required this.respondedAt,
        this.requesterContact,
    });

    final String matchId;
    final MatchResponseType response;
    final DateTime respondedAt;

    /// Present only for [MatchResponseType.accepted]. Null for a decline — null,
    /// not an empty object, so a client bug reads as a crash rather than a contact
    /// card with blank fields.
    final RequesterContact? requesterContact;
}
