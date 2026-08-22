package kh.lifelink.api.portal.dto;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import java.util.UUID;

/**
 * @param matchId must belong to this request and be ACCEPTED — confirming a donation from a donor
 *     who never accepted would silently start their 56-day cooldown for a donation they were never
 *     asked about.
 * @param donatedOn must not be in the future.
 */
public record ConfirmDonationRequest(@NotNull UUID matchId, @NotNull LocalDate donatedOn) {}
