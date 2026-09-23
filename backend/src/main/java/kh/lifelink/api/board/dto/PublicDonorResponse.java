package kh.lifelink.api.board.dto;

import java.time.OffsetDateTime;
import kh.lifelink.api.district.dto.DistrictName;

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
 *
 * <p>{@code districtName} carries both labels, like every other district on this page. It was a
 * bare English string until {@code BUG-API-004}: on the Khmer board — the default locale — a
 * hospital's district rendered {@code មានជ័យ} and the donor's, one line below it on the same card,
 * rendered {@code Doun Penh}. Which language a label is written in is not a decision the API gets
 * to make for a client that switches locale at runtime (the reasoning in {@code CR-MAPI-001}).
 */
public record PublicDonorResponse(
        String displayName,
        String bloodType,
        DistrictName districtName,
        OffsetDateTime respondedAt) {}
