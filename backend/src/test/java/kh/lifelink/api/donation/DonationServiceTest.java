package kh.lifelink.api.donation;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyIterable;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kh.lifelink.api.district.District;
import kh.lifelink.api.district.DistrictRepository;
import kh.lifelink.api.donation.dto.DonationResponse;
import kh.lifelink.api.donor.DonorProfile;
import kh.lifelink.api.donor.DonorProfileRepository;
import kh.lifelink.api.hospital.Hospital;
import kh.lifelink.api.hospital.HospitalRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class DonationServiceTest {

    private static final String DISTRICT = "1201";

    private DonationRepository donations;
    private DonorProfileRepository profiles;
    private HospitalRepository hospitals;
    private DistrictRepository districts;
    private DonationService service;
    private UUID callerId;
    private UUID donorProfileId;

    @BeforeEach
    void setUp() {
        donations = mock(DonationRepository.class);
        profiles = mock(DonorProfileRepository.class);
        hospitals = mock(HospitalRepository.class);
        districts = mock(DistrictRepository.class);
        service = new DonationService(donations, profiles, hospitals, districts);

        callerId = UUID.randomUUID();
        donorProfileId = UUID.randomUUID();
    }

    @Test
    void aUserWithNoDonorProfileHasAnEmptyHistoryRatherThanA404() {
        when(profiles.findByUserId(callerId)).thenReturn(Optional.empty());

        assertThat(service.listForUser(callerId)).isEmpty();
    }

    @Test
    void aDonorWithNoDonationsYetHasAnEmptyHistory() {
        when(profiles.findByUserId(callerId)).thenReturn(Optional.of(profile()));
        when(donations.findByDonorProfileIdOrderByDonatedOnDesc(donorProfileId))
                .thenReturn(List.of());

        assertThat(service.listForUser(callerId)).isEmpty();
    }

    @Test
    void aDonationIsJoinedToItsHospitalAndDistrict() {
        UUID hospitalId = UUID.randomUUID();
        UUID requestId = UUID.randomUUID();
        Donation donation = donation(hospitalId, requestId, LocalDate.of(2026, 6, 14));

        when(profiles.findByUserId(callerId)).thenReturn(Optional.of(profile()));
        when(donations.findByDonorProfileIdOrderByDonatedOnDesc(donorProfileId))
                .thenReturn(List.of(donation));
        when(hospitals.findAllById(anyIterable()))
                .thenReturn(List.of(hospital(hospitalId, "Calmette Hospital", DISTRICT)));
        when(districts.findAll()).thenReturn(List.of(district(DISTRICT, "ចំការមន", "Chamkar Mon")));

        List<DonationResponse> result = service.listForUser(callerId);

        assertThat(result).hasSize(1);
        DonationResponse response = result.get(0);
        assertThat(response.donatedOn()).isEqualTo(LocalDate.of(2026, 6, 14));
        assertThat(response.bloodRequestId()).isEqualTo(requestId);
        assertThat(response.hospital().name()).isEqualTo("Calmette Hospital");
        assertThat(response.hospital().districtName().km()).isEqualTo("ចំការមន");
    }

    /** A walk-in donation has no originating request (FR-08) — null must round-trip, not 0/empty. */
    @Test
    void aWalkInDonationHasNoBloodRequestId() {
        UUID hospitalId = UUID.randomUUID();
        Donation donation = donation(hospitalId, null, LocalDate.of(2026, 6, 14));

        when(profiles.findByUserId(callerId)).thenReturn(Optional.of(profile()));
        when(donations.findByDonorProfileIdOrderByDonatedOnDesc(donorProfileId))
                .thenReturn(List.of(donation));
        when(hospitals.findAllById(anyIterable()))
                .thenReturn(List.of(hospital(hospitalId, "Calmette Hospital", null)));
        when(districts.findAll()).thenReturn(List.of());

        DonationResponse response = service.listForUser(callerId).get(0);

        assertThat(response.bloodRequestId()).isNull();
        assertThat(response.hospital().districtName()).isNull();
    }

    private DonorProfile profile() {
        DonorProfile profile = new DonorProfile();
        setField(profile, "id", donorProfileId);
        return profile;
    }

    private Donation donation(UUID hospitalId, UUID requestId, LocalDate donatedOn) {
        Donation donation = new Donation();
        setField(donation, "id", UUID.randomUUID());
        donation.setHospitalId(hospitalId);
        donation.setBloodRequestId(requestId);
        donation.setDonatedOn(donatedOn);
        return donation;
    }

    private static Hospital hospital(UUID id, String name, String districtCode) {
        Hospital hospital = new Hospital();
        setField(hospital, "id", id);
        hospital.setName(name);
        hospital.setDistrictCode(districtCode);
        return hospital;
    }

    private static District district(String code, String km, String en) {
        District district = new District();
        setField(district, "code", code);
        setField(district, "nameKm", km);
        setField(district, "nameEn", en);
        return district;
    }

    private static void setField(Object target, String name, Object value) {
        try {
            var field = target.getClass().getDeclaredField(name);
            field.setAccessible(true);
            field.set(target, value);
        } catch (ReflectiveOperationException ex) {
            throw new IllegalStateException(
                    target.getClass().getSimpleName() + "." + name + " no longer exists", ex);
        }
    }
}
