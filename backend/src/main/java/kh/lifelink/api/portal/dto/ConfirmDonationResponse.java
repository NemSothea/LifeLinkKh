package kh.lifelink.api.portal.dto;

import java.time.LocalDate;
import java.util.UUID;

/**
 * @param id the new {@code donations} row — the only write path to that table in the product.
 * @param donorNextEligibleOn {@code donatedOn + 56 days}, returned so staff can tell the donor when
 *     to come back, which is the information the donor actually wants at that moment.
 */
public record ConfirmDonationResponse(
        UUID id,
        String donorDisplayName,
        LocalDate donatedOn,
        String requestStatus,
        LocalDate donorNextEligibleOn) {}
