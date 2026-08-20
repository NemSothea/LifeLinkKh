package kh.lifelink.api.donation;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import kh.lifelink.api.district.District;
import kh.lifelink.api.district.DistrictRepository;
import kh.lifelink.api.district.dto.DistrictName;
import kh.lifelink.api.donation.dto.DonationResponse;
import kh.lifelink.api.donor.DonorProfileRepository;
import kh.lifelink.api.hospital.Hospital;
import kh.lifelink.api.hospital.HospitalRepository;
import kh.lifelink.api.hospital.dto.HospitalResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** FR-DONATION-001: a donor's own donation history, most recent first. */
@Service
public class DonationService {

    private final DonationRepository donations;
    private final DonorProfileRepository profiles;
    private final HospitalRepository hospitals;
    private final DistrictRepository districts;

    DonationService(
            DonationRepository donations,
            DonorProfileRepository profiles,
            HospitalRepository hospitals,
            DistrictRepository districts) {
        this.donations = donations;
        this.profiles = profiles;
        this.hospitals = hospitals;
        this.districts = districts;
    }

    /**
     * No donor profile means no donations yet — a REQUESTER, or a DONOR mid-signup. That is an
     * empty list, not a 404: this is a collection endpoint, not a single-resource read.
     */
    @Transactional(readOnly = true)
    public List<DonationResponse> listForUser(UUID userId) {
        return profiles.findByUserId(userId)
                .map(
                        profile ->
                                toResponses(
                                        donations.findByDonorProfileIdOrderByDonatedOnDesc(
                                                profile.getId())))
                .orElseGet(List::of);
    }

    private List<DonationResponse> toResponses(List<Donation> rows) {
        if (rows.isEmpty()) {
            return List.of();
        }

        Map<UUID, Hospital> hospitalsById =
                hospitals
                        .findAllById(rows.stream().map(Donation::getHospitalId).distinct().toList())
                        .stream()
                        .collect(Collectors.toMap(Hospital::getId, Function.identity()));
        Map<String, District> districtsByCode =
                districts.findAll().stream()
                        .collect(Collectors.toMap(District::getCode, Function.identity()));

        return rows.stream().map(row -> toResponse(row, hospitalsById, districtsByCode)).toList();
    }

    private DonationResponse toResponse(
            Donation row, Map<UUID, Hospital> hospitalsById, Map<String, District> districtsByCode) {
        Hospital hospital = hospitalsById.get(row.getHospitalId());
        District district =
                hospital == null || hospital.getDistrictCode() == null
                        ? null
                        : districtsByCode.get(hospital.getDistrictCode());
        HospitalResponse hospitalResponse =
                hospital == null
                        ? null
                        : new HospitalResponse(
                                hospital.getId(),
                                hospital.getName(),
                                district == null
                                        ? null
                                        : new DistrictName(
                                                district.getNameKm(), district.getNameEn()));

        return new DonationResponse(
                row.getId(), row.getDonatedOn(), hospitalResponse, row.getBloodRequestId());
    }
}
