package kh.lifelink.api.match.dto;

import java.time.OffsetDateTime;
import java.util.UUID;
import kh.lifelink.api.request.dto.RequesterContact;

/**
 * @param requesterContact present only for ACCEPTED. Null for DECLINED — null rather than an empty
 *     object, so a client bug reads as a crash instead of as a contact card with blank fields.
 */
public record RespondResponse(
        UUID matchId,
        String response,
        OffsetDateTime respondedAt,
        RequesterContact requesterContact) {}
