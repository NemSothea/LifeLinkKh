package kh.lifelink.api.admin.dto;

import java.util.UUID;

/** A HOSPITAL or ADMIN account, as the portal's staff-management screen lists it. */
public record StaffResponse(
        UUID id, String displayName, String role, UUID hospitalId, String hospitalName) {}
