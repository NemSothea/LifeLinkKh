package kh.lifelink.api.donation.dto;

import java.time.LocalDate;
import java.util.UUID;
import kh.lifelink.api.hospital.dto.HospitalResponse;

/**
 * @param bloodRequestId null for a walk-in donation with no originating request (FR-08).
 */
public record DonationResponse(
        UUID id, LocalDate donatedOn, HospitalResponse hospital, UUID bloodRequestId) {}
