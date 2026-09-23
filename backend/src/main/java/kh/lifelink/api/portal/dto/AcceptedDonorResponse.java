package kh.lifelink.api.portal.dto;

import java.time.OffsetDateTime;
import java.util.UUID;
import kh.lifelink.api.district.dto.DistrictName;

/**
 * One donor who has accepted, as hospital staff need to coordinate an arrival.
 *
 * <p>This is the reveal a mobile requester never gets ({@code
 * docs/po/prototypes/mobile/REQUEST-responders-list}) — staff have an operational reason a
 * requester does not: they are the ones meeting the donor at the door. Still no {@code
 * latitude}/{@code longitude} and no unrounded distance (ADR 0003).
 *
 * <p>{@code districtName} was a plain English string until {@code BUG-API-004}, which is what the
 * contract documented and what the portal then had no way to localize. It is now the same {@code
 * DistrictName} pair every other district on the page uses — the portal has a language switcher,
 * so the API cannot pick the language on its behalf.
 *
 * @param bloodType the donor's own type, not the patient's — staff already know the patient's type
 *     from the request row this sits under
 */
public record AcceptedDonorResponse(
        UUID matchId,
        String displayName,
        String bloodType,
        DistrictName districtName,
        OffsetDateTime respondedAt) {}
