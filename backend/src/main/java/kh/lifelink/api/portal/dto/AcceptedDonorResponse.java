package kh.lifelink.api.portal.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * One donor who has accepted, as hospital staff need to coordinate an arrival.
 *
 * <p>This is the reveal a mobile requester never gets
 * ({@code docs/po/prototypes/mobile/REQUEST-responders-list}) — staff have an operational reason
 * a requester does not: they are the ones meeting the donor at the door. Still no
 * {@code latitude}/{@code longitude} and no unrounded distance (ADR 0003); {@code districtName} is
 * a plain string here, matching {@code contract.md}'s documented shape, unlike the km/en pair used
 * everywhere donor-district-facing text reaches a client with a language switch.
 *
 * @param bloodType the donor's own type, not the patient's — staff already know the patient's type
 *     from the request row this sits under
 */
public record AcceptedDonorResponse(
        UUID matchId,
        String displayName,
        String bloodType,
        String districtName,
        OffsetDateTime respondedAt) {}
