package kh.lifelink.api.match;

import java.util.UUID;

/**
 * FR-NOTIFY-003 — a donor's response became {@code ACCEPTED}, published from inside {@link
 * MatchService#respond}. Only ids: the listener runs after commit and reads what it needs itself,
 * so nothing here can go stale between publishing and sending.
 */
public record DonorAccepted(UUID matchId, UUID requestId) {}
