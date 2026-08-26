package kh.lifelink.api.donor;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import kh.lifelink.api.common.error.ApiException;
import kh.lifelink.api.district.District;
import kh.lifelink.api.district.DistrictRepository;
import kh.lifelink.api.donor.dto.DonorProfileResponse;
import kh.lifelink.api.donor.dto.DonorProfileWriteRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.http.HttpStatus;

class DonorServiceTest {

    private static final LocalDate TODAY = LocalDate.of(2026, 8, 17);
    private static final String DISTRICT = "1201";

    private DonorProfileRepository profiles;
    private DistrictRepository districts;
    private DonorService donors;
    private UUID callerId;

    @BeforeEach
    void setUp() {
        profiles = mock(DonorProfileRepository.class);
        districts = mock(DistrictRepository.class);
        Clock fixed = Clock.fixed(Instant.parse("2026-08-17T00:00:00Z"), ZoneOffset.UTC);
        donors = new DonorService(profiles, districts, fixed);
        callerId = UUID.randomUUID();

        // Built before the outer when(), not inside it — a mock stubbed while Mockito is
        // mid-stubbing
        // fails as UnfinishedStubbing.
        District chamkarMon = district();
        when(districts.findByCode(DISTRICT)).thenReturn(Optional.of(chamkarMon));
        when(profiles.findByUserId(callerId)).thenReturn(Optional.empty());
        when(profiles.save(any(DonorProfile.class))).thenAnswer(call -> call.getArgument(0));
    }

    @Test
    void aFirstTimeDonorSavesWithNoDateAndNoCoordinates() {
        DonorProfileResponse saved =
                donors.save(callerId, write("A+", DISTRICT, null, null, null, false));

        assertThat(saved.eligibility().isEligible()).isTrue();
        assertThat(saved.districtName().km()).isEqualTo("ចំការមន");
    }

    @Test
    void anUnknownBloodTypeIsUnprocessable() {
        assertThatThrownBy(
                        () -> donors.save(callerId, write("C+", DISTRICT, null, null, null, false)))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getCode())
                .isEqualTo("UNKNOWN_BLOOD_TYPE");
    }

    @Test
    void anUnknownDistrictIsUnprocessable() {
        when(districts.findByCode("9999")).thenReturn(Optional.empty());

        assertThatThrownBy(
                        () -> donors.save(callerId, write("A+", "9999", null, null, null, false)))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getCode())
                .isEqualTo("UNKNOWN_DISTRICT");
    }

    /** A future donation date would make the donor permanently ineligible. */
    @Test
    void aFutureLastDonationDateIsRejectedAndNothingIsWritten() {
        assertThatThrownBy(
                        () ->
                                donors.save(
                                        callerId,
                                        write(
                                                "A+",
                                                DISTRICT,
                                                null,
                                                null,
                                                TODAY.plusDays(1),
                                                false)))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);

        verify(profiles, never()).save(any(DonorProfile.class));
    }

    /** Today is not in the future. The boundary, since "after today" is the rule. */
    @Test
    void todayIsAnAcceptableLastDonationDate() {
        DonorProfileResponse saved =
                donors.save(callerId, write("A+", DISTRICT, null, null, TODAY, false));

        assertThat(saved.eligibility().isEligible()).isFalse();
        assertThat(saved.eligibility().daysRemaining()).isEqualTo(56);
    }

    /** A latitude with no longitude is not a partial location, it is a bug. */
    @Test
    void aLatitudeWithoutALongitudeIsRejected() {
        assertThatThrownBy(
                        () ->
                                donors.save(
                                        callerId,
                                        write(
                                                "A+",
                                                DISTRICT,
                                                new BigDecimal("11.55"),
                                                null,
                                                null,
                                                true)))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getCode())
                .isEqualTo("INCOMPLETE_COORDINATES");
    }

    /** {@code updateCoordinates=false} means the pair rule does not even apply. */
    @Test
    void anIncompletePairIsIgnoredWhenNotUpdatingCoordinates() {
        DonorProfileResponse saved =
                donors.save(
                        callerId,
                        write("A+", DISTRICT, new BigDecimal("11.55"), null, null, false));

        assertThat(saved).isNotNull();
    }

    /**
     * ADR 0003 the other way round: coordinates must actually be stored, because they are
     * unreadable through the API by design. A dropped write and a correct one produce identical
     * responses.
     */
    @Test
    void coordinatesAreStoredEvenThoughNoResponseReturnsThem() {
        donors.save(
                callerId,
                write(
                        "A+",
                        DISTRICT,
                        new BigDecimal("11.55000"),
                        new BigDecimal("104.92000"),
                        null,
                        true));

        ArgumentCaptor<DonorProfile> saved = ArgumentCaptor.forClass(DonorProfile.class);
        verify(profiles).save(saved.capture());
        assertThat(saved.getValue().getLatitude()).isEqualByComparingTo("11.55000");
        assertThat(saved.getValue().getLongitude()).isEqualByComparingTo("104.92000");
    }

    /**
     * CR-MAPI-004. Editing a name or a date must not silently wipe a donor's GPS precision —
     * coordinates never come back in a response, so "not sent" cannot mean "clear."
     */
    @Test
    void editingWithoutUpdateCoordinatesLeavesStoredCoordinatesUntouched() {
        DonorProfile existing = new DonorProfile();
        existing.setUserId(callerId);
        existing.setBloodType("O-");
        existing.setLatitude(new BigDecimal("11.55000"));
        existing.setLongitude(new BigDecimal("104.92000"));
        when(profiles.findByUserId(callerId)).thenReturn(Optional.of(existing));

        donors.save(callerId, write("O-", DISTRICT, null, null, null, false));

        assertThat(existing.getLatitude()).isEqualByComparingTo("11.55000");
        assertThat(existing.getLongitude()).isEqualByComparingTo("104.92000");
    }

    /** {@code updateCoordinates=true} with both fields null is an explicit clear, not a no-op. */
    @Test
    void updateCoordinatesTrueWithBothNullClearsThem() {
        DonorProfile existing = new DonorProfile();
        existing.setUserId(callerId);
        existing.setBloodType("O-");
        existing.setLatitude(new BigDecimal("11.55000"));
        existing.setLongitude(new BigDecimal("104.92000"));
        when(profiles.findByUserId(callerId)).thenReturn(Optional.of(existing));

        donors.save(callerId, write("O-", DISTRICT, null, null, null, true));

        assertThat(existing.getLatitude()).isNull();
        assertThat(existing.getLongitude()).isNull();
    }

    /** A second PUT updates the existing row rather than creating a second profile. */
    @Test
    void savingTwiceUpdatesTheSameRow() {
        DonorProfile existing = new DonorProfile();
        existing.setUserId(callerId);
        existing.setBloodType("O-");
        when(profiles.findByUserId(callerId)).thenReturn(Optional.of(existing));

        donors.save(callerId, write("AB+", DISTRICT, null, null, null, false));

        ArgumentCaptor<DonorProfile> saved = ArgumentCaptor.forClass(DonorProfile.class);
        verify(profiles).save(saved.capture());
        assertThat(saved.getValue()).isSameAs(existing);
        assertThat(saved.getValue().getBloodType()).isEqualTo("AB+");
    }

    @Test
    void readingWithNoProfileIsNotFound() {
        assertThatThrownBy(() -> donors.read(callerId))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).getStatus())
                .isEqualTo(HttpStatus.NOT_FOUND);
    }

    /**
     * docs/qa/test-strategy.md non-negotiable security test 1, asserted on the serialised JSON
     * rather than on the record — serialising an entity is exactly the mistake being guarded
     * against, and a DTO-level assertion would not catch it.
     */
    @Test
    void serialisedProfileJsonContainsNoCoordinates() throws Exception {
        DonorProfileResponse response =
                donors.save(
                        callerId,
                        write(
                                "A+",
                                DISTRICT,
                                new BigDecimal("11.55000"),
                                new BigDecimal("104.92000"),
                                null,
                                true));

        String json =
                new ObjectMapper()
                        .registerModule(new JavaTimeModule())
                        .writeValueAsString(response);

        assertThat(json)
                .doesNotContain("latitude")
                .doesNotContain("longitude")
                .doesNotContain("11.55")
                .doesNotContain("104.92");
    }

    private static District district() {
        District district = mock(District.class);
        when(district.getNameKm()).thenReturn("ចំការមន");
        when(district.getNameEn()).thenReturn("Chamkar Mon");
        return district;
    }

    private static DonorProfileWriteRequest write(
            String bloodType,
            String districtCode,
            BigDecimal latitude,
            BigDecimal longitude,
            LocalDate lastDonationDate,
            boolean updateCoordinates) {
        return new DonorProfileWriteRequest(
                "Nem Sothea",
                bloodType,
                districtCode,
                latitude,
                longitude,
                lastDonationDate,
                null,
                updateCoordinates);
    }
}
