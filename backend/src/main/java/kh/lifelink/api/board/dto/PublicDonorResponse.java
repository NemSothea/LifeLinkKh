package kh.lifelink.api.board.dto;

import java.time.OffsetDateTime;

/**
 * One donor who has accepted, as the <strong>public</strong> board shows them.
 *
 * <p>Deliberately not {@code AcceptedDonorResponse}: that record carries {@code matchId}, the
 * handle {@code POST /portal/requests/{id}/confirm-donation} writes against. The write is
 * authenticated either way, but a public page has no reason to hand every visitor the identifier
 * for it, and reusing the portal's record would have published it by default the next time someone
 * added a field there.
 *
 * <p>Publishing a donor's name, blood type and district at all is a deliberate override of {@code
 * TM-AUTH-001} I1 and the {@code REQUEST-responders-list} prototype, recorded as {@code DEC-009} in
 * {@code docs/decisions.md}. Still absent, because that decision did not touch them: the
 * requester's name and phone number, and any coordinate (ADR 0003).
 */
public record PublicDonorResponse(
        String displayName, String bloodType, String districtName, OffsetDateTime respondedAt) {}
