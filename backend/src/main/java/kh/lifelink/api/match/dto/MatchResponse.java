package kh.lifelink.api.match.dto;

import java.time.OffsetDateTime;
import java.util.UUID;
import kh.lifelink.api.request.dto.BloodRequestDetailResponse;

/**
 * One entry in a donor's alert inbox.
 *
 * @param response null until the donor answers. Once set it never changes — withdrawal is
 *     FR-REQUEST-004 and is deferred.
 * @param notifiedAt null when the push was never sent: no FCM token, or a send that failed. The
 *     match is still real and the donor still sees it here, which is the point of showing the inbox
 *     rather than relying on the notification alone.
 */
public record MatchResponse(
        UUID matchId,
        BloodRequestDetailResponse request,
        String myBloodType,
        String response,
        OffsetDateTime notifiedAt) {}
