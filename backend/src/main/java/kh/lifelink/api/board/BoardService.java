package kh.lifelink.api.board;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import kh.lifelink.api.board.dto.PublicDonorResponse;
import kh.lifelink.api.board.dto.PublicRequestResponse;
import kh.lifelink.api.district.District;
import kh.lifelink.api.district.DistrictRepository;
import kh.lifelink.api.donor.DonorProfileRepository;
import kh.lifelink.api.district.dto.DistrictName;
import kh.lifelink.api.hospital.Hospital;
import kh.lifelink.api.hospital.HospitalRepository;
import kh.lifelink.api.hospital.dto.HospitalResponse;
import kh.lifelink.api.match.RequestMatch;
import kh.lifelink.api.match.RequestMatchRepository;
import kh.lifelink.api.request.BloodRequest;
import kh.lifelink.api.request.BloodRequestRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * The public live board — every open blood request, readable without signing in.
 *
 * <p>Its own service rather than a flag on {@code PortalService}, and its own DTOs rather than the
 * portal's, for one reason: everything this class returns is world-readable, and a shared mapper
 * publishes any field a future edit adds to it. Two mappers is duplication that can only leak on
 * purpose; one mapper with a visibility flag is duplication that leaks by accident.
 *
 * <p><strong>OPEN only.</strong> A fulfilled or cancelled request is not a call for help, and
 * keeping the public surface to the smallest set that serves the purpose is the whole argument for
 * the endpoint being safe to expose at all.
 */
@Service
public class BoardService {

    private static final String OPEN = "OPEN";
    private static final String ACCEPTED = "ACCEPTED";

    private final BloodRequestRepository requests;
    private final RequestMatchRepository matches;
    private final DonorProfileRepository donorProfiles;
    private final HospitalRepository hospitals;
    private final DistrictRepository districts;

    BoardService(
            BloodRequestRepository requests,
            RequestMatchRepository matches,
            DonorProfileRepository donorProfiles,
            HospitalRepository hospitals,
            DistrictRepository districts) {
        this.requests = requests;
        this.matches = matches;
        this.donorProfiles = donorProfiles;
        this.hospitals = hospitals;
        this.districts = districts;
    }

    @Transactional(readOnly = true)
    public List<PublicRequestResponse> listOpenRequests() {
        List<BloodRequest> rows = requests.findByStatusOrderByCreatedAtDesc(OPEN);
        Map<UUID, Hospital> hospitalsById = hospitalsById(rows);
        Map<String, District> districtsByCode = districtsByCode();

        return rows.stream()
                .map(request -> toPublicResponse(request, hospitalsById, districtsByCode))
                .toList();
    }

    private PublicRequestResponse toPublicResponse(
            BloodRequest request,
            Map<UUID, Hospital> hospitalsById,
            Map<String, District> districtsByCode) {
        List<RequestMatch> accepted =
                matches.findByBloodRequestIdAndResponse(request.getId(), ACCEPTED);

        List<PublicDonorResponse> acceptedDonors =
                accepted.stream()
                        .map(match -> toPublicDonor(match, districtsByCode))
                        .filter(Objects::nonNull)
                        .sorted(Comparator.comparing(PublicDonorResponse::respondedAt))
                        .toList();

        return new PublicRequestResponse(
                request.getId(),
                request.getPatientBloodType(),
                request.getUnitsNeeded(),
                request.getUrgency(),
                request.getStatus(),
                hospitalResponse(hospitalsById.get(request.getHospitalId()), districtsByCode),
                matches.countByBloodRequestId(request.getId()),
                accepted.size(),
                request.getCreatedAt(),
                acceptedDonors);
    }

    /**
     * Unlike the portal's list, a confirmed donor is <strong>not</strong> filtered out here. The
     * portal's filter exists because its list is a to-do list with a confirm button; this one is a
     * record of who answered, and dropping someone the moment their donation was confirmed would
     * make the board understate the response to a request.
     */
    private PublicDonorResponse toPublicDonor(
            RequestMatch match, Map<String, District> districtsByCode) {
        return donorProfiles
                .findById(match.getDonorProfileId())
                .map(
                        profile -> {
                            District district = districtsByCode.get(profile.getDistrictCode());
                            return new PublicDonorResponse(
                                    profile.getFullName(),
                                    profile.getBloodType(),
                                    district == null ? null : district.getNameEn(),
                                    match.getRespondedAt());
                        })
                .orElse(null);
    }

    private HospitalResponse hospitalResponse(
            Hospital hospital, Map<String, District> districtsByCode) {
        if (hospital == null) {
            return null;
        }
        District district =
                hospital.getDistrictCode() == null
                        ? null
                        : districtsByCode.get(hospital.getDistrictCode());
        return new HospitalResponse(
                hospital.getId(),
                hospital.getName(),
                district == null
                        ? null
                        : new DistrictName(district.getNameKm(), district.getNameEn()));
    }

    private Map<UUID, Hospital> hospitalsById(List<BloodRequest> rows) {
        List<UUID> ids = rows.stream().map(BloodRequest::getHospitalId).distinct().toList();
        return hospitals.findAllById(ids).stream()
                .collect(Collectors.toMap(Hospital::getId, Function.identity()));
    }

    private Map<String, District> districtsByCode() {
        return districts.findAll().stream()
                .collect(Collectors.toMap(District::getCode, Function.identity()));
    }
}
