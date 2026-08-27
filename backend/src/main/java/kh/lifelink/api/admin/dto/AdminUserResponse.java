package kh.lifelink.api.admin.dto;

import java.util.UUID;

/**
 * A self-service account an ADMIN could promote — the "candidate" list for {@code POST
 * /admin/staff}.
 */
public record AdminUserResponse(UUID id, String displayName, String role) {}
