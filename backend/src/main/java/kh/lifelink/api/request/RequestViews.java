package kh.lifelink.api.request;

import java.math.BigDecimal;
import java.util.UUID;
import kh.lifelink.api.district.DistrictRepository;
import kh.lifelink.api.district.dto.DistrictName;
import kh.lifelink.api.hospital.Hospital;
import kh.lifelink.api.hospital.HospitalRepository;
import kh.lifelink.api.hospital.dto.HospitalResponse;
import kh.lifelink.api.match.RequestMatchRepository;
import kh.lifelink.api.request.dto.BloodRequestDetailResponse;
import kh.lifelink.api.request.dto.BloodRequestResponse;
import kh.lifelink.api.request.dto.RequesterContact;
import org.springframework.stereotype.Component;

/**
 * Turns a {@link BloodRequest} into the two response shapes, in one place.
 *
 * <p>One place because of {@code requesterContact}. It is the single field in the product that
 * reveals a person's phone number, it is reachable from three endpoints, and the rule guarding it
 * is a condition rather than a type — exactly the shape of thing that gets reimplemented slightly
 * differently in the third caller and leaks. {@link #detail} takes the responded state as an
 * argument so no caller can forget to pass it.
 */
@Component
public class RequestViews {

    static final String ACCEPTED = "ACCEPTED";

    private final HospitalRepository hospitals;
    private final DistrictRepository districts;
    private final RequestMatchRepository matches;

    RequestViews(
            HospitalRepository hospitals,
            DistrictRepository districts,
            RequestMatchRepository matches) {
        this.hospitals = hospitals;
        this.districts = districts;
        this.matches = matches;
    }

    public BloodRequestResponse summary(BloodRequest request) {
        return new BloodRequestResponse(
                request.getId(),
                request.getStatus(),
                request.getPatientBloodType(),
                request.getUnitsNeeded(),
                request.getUrgency(),
                hospital(request.getHospitalId()),
                matches.countByBloodRequestId(request.getId()),
                matches.countByBloodRequestIdAndResponse(request.getId(), ACCEPTED),
                request.getCreatedAt());
    }

    /**
     * @param viewerResponse the calling donor's own match response, or null when the caller is the
     *     creator or has not answered. Anything other than {@code ACCEPTED} means no contact
     *     details, and that is the only rule — there is no "creator also sees it" branch, because
     *     the creator already knows their own number.
     * @param distanceKm the calling donor's stored match distance, or null
     */
    public BloodRequestDetailResponse detail(
            BloodRequest request, String viewerResponse, BigDecimal distanceKm) {

        RequesterContact contact =
                ACCEPTED.equals(viewerResponse)
                        ? RequesterContact.of(request.getContactName(), request.getContactPhone())
                        : null;

        return new BloodRequestDetailResponse(
                request.getId(),
                request.getStatus(),
                request.getPatientBloodType(),
                request.getUnitsNeeded(),
                request.getUrgency(),
                hospital(request.getHospitalId()),
                matches.countByBloodRequestId(request.getId()),
                matches.countByBloodRequestIdAndResponse(request.getId(), ACCEPTED),
                request.getCreatedAt(),
                distanceKm,
                contact);
    }

    private HospitalResponse hospital(UUID hospitalId) {
        Hospital hospital = hospitals.findById(hospitalId).orElse(null);
        if (hospital == null) {
            return null;
        }
        DistrictName districtName =
                hospital.getDistrictCode() == null
                        ? null
                        : districts
                                .findByCode(hospital.getDistrictCode())
                                .map(d -> new DistrictName(d.getNameKm(), d.getNameEn()))
                                .orElse(null);
        return new HospitalResponse(hospital.getId(), hospital.getName(), districtName);
    }
}
