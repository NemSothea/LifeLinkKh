package kh.lifelink.api.donor.dto;

import java.time.LocalDate;
import java.util.UUID;

/**
 * The donor read model — an explicit allow-list, built field by field from the entity.
 *
 * <p><strong>{@code latitude} and {@code longitude} are absent, not null.</strong> There is no such
 * field to populate. That is ADR 0003, and it is why this is a hand-written record rather than
 * {@code @JsonIgnore} on the entity or a projection defined as "everything minus" — both of those
 * fail open the moment someone adds a column.
 *
 * <p>This endpoint returns the caller's own profile, so echoing their own coordinates back would
 * leak nothing today. The rule is absolute anyway: this is the DTO {@code GET /matches/me} will
 * reach for at M4, and at that point the coordinates belong to someone else.
 *
 * @param districtName the district in both languages — see {@link DistrictName}
 */
public record DonorProfileResponse(
        UUID id,
        String fullName,
        String bloodType,
        String districtCode,
        DistrictName districtName,
        LocalDate lastDonationDate,
        boolean isAvailable,
        EligibilityResponse eligibility) {

    /**
     * Both labels, rather than the server picking one.
     *
     * <p>The contract's {@code districtName} is a single string and does not say which language.
     * Returning both keeps a presentation decision out of the API; the alternative is the server
     * reading {@code users.language} and choosing for the client. Either way this needs a CR-MAPI,
     * since it changes a response schema — flagged in the spec, not settled here.
     */
    public record DistrictName(String km, String en) {}
}
