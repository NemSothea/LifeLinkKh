package kh.lifelink.api.admin.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/**
 * {@code POST /admin/staff/{id}/demote}. The hospital the demoted admin will be scoped to —
 * required, because a HOSPITAL account with no hospital is exactly the state
 * {@code assignStaffRole} already refuses to create.
 */
public record DemoteStaffRequest(@NotNull UUID hospitalId) {}
