package kh.lifelink.api.district.dto;

/**
 * One district in the donor-registration dropdown.
 *
 * <p>Both labels, not one: the app switches language at runtime (FR-GLOBAL-001), so a server that
 * picked a language would force a re-fetch on every locale change. Same shape as {@code
 * DonorProfileResponse.DistrictName} for the same reason.
 *
 * @param code what {@code PUT /donors/me} expects in {@code districtCode}
 */
public record DistrictResponse(String code, String nameKm, String nameEn) {}
