package kh.lifelink.api.donor;

import java.time.Clock;
import java.time.LocalDate;
import java.util.Set;
import java.util.UUID;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.district.District;
import kh.lifelink.api.district.DistrictRepository;
import kh.lifelink.api.donor.dto.DonorProfileResponse;
import kh.lifelink.api.donor.dto.DonorProfileWriteRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DonorService {

    /**
     * Also a CHECK constraint in {@code V1__init.sql}, which is the real authority. Duplicated here
     * so the refusal is a 422 with a useful code instead of a constraint violation surfacing as a
     * generic one.
     *
     * <p>There is deliberately no unknown value: {@code blood_compatibility} has no row for one
     * (ADR 0004), so such a donor would be stored and then silently never match.
     */
    private static final Set<String> BLOOD_TYPES =
            Set.of("O-", "O+", "A-", "A+", "B-", "B+", "AB-", "AB+");

    private final DonorProfileRepository profiles;
    private final DistrictRepository districts;
    private final Clock clock;

    DonorService(DonorProfileRepository profiles, DistrictRepository districts, Clock clock) {
        this.profiles = profiles;
        this.districts = districts;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public DonorProfileResponse read(UUID userId) {
        DonorProfile profile =
                profiles.findByUserId(userId)
                        // Normal for a REQUESTER, and for a DONOR mid-signup. Not a fault to log.
                        .orElseThrow(
                                () ->
                                        ApiException.notFound(
                                                "DONOR_PROFILE_NOT_FOUND",
                                                "No donor profile yet."));
        return toResponse(profile);
    }

    @Transactional
    public DonorProfileResponse save(UUID userId, DonorProfileWriteRequest body) {
        validate(body);

        DonorProfile profile = profiles.findByUserId(userId).orElseGet(DonorProfile::new);
        profile.setUserId(userId);
        profile.setFullName(body.fullName());
        profile.setBloodType(body.bloodType());
        profile.setDistrictCode(body.districtCode());
        profile.setLatitude(body.latitude());
        profile.setLongitude(body.longitude());
        profile.setLastDonationDate(body.lastDonationDate());
        if (body.isAvailable() != null) {
            profile.setAvailable(body.isAvailable());
        }

        return toResponse(profiles.save(profile));
    }

    private void validate(DonorProfileWriteRequest body) {
        if (!BLOOD_TYPES.contains(body.bloodType())) {
            throw ApiException.unprocessable("UNKNOWN_BLOOD_TYPE", "That blood type is not valid.");
        }

        // Both or neither. A latitude with no longitude is not a partial location, it is a bug, and
        // storing it produces a donor who is neither rankable nor obviously broken.
        boolean hasLat = body.latitude() != null;
        boolean hasLon = body.longitude() != null;
        if (hasLat != hasLon) {
            throw ApiException.badRequest(
                    "INCOMPLETE_COORDINATES", "Latitude and longitude must be provided together.");
        }

        LocalDate lastDonation = body.lastDonationDate();
        if (lastDonation != null && lastDonation.isAfter(today())) {
            // A donation cannot be in the future, and a future date would make the donor
            // permanently ineligible.
            throw ApiException.unprocessable(
                    "LAST_DONATION_IN_FUTURE", "The last donation date cannot be in the future.");
        }

        // The foreign key would catch this too. Checked here so the caller gets a code that names
        // the field rather than a generic constraint failure.
        if (districts.findByCode(body.districtCode()).isEmpty()) {
            throw ApiException.unprocessable("UNKNOWN_DISTRICT", "That district is not valid.");
        }
    }

    private DonorProfileResponse toResponse(DonorProfile profile) {
        // Field by field, deliberately. latitude and longitude have no counterpart here (ADR 0003).
        District district = districts.findByCode(profile.getDistrictCode()).orElse(null);
        return new DonorProfileResponse(
                profile.getId(),
                profile.getFullName(),
                profile.getBloodType(),
                profile.getDistrictCode(),
                district == null
                        ? null
                        : new DonorProfileResponse.DistrictName(
                                district.getNameKm(), district.getNameEn()),
                profile.getLastDonationDate(),
                profile.isAvailable(),
                EligibilityCalculator.forLastDonation(profile.getLastDonationDate(), today()));
    }

    /** Injected clock, so the 56-day boundary tests do not depend on the day they are run. */
    private LocalDate today() {
        return LocalDate.now(clock);
    }
}
