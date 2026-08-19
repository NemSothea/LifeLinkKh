package kh.lifelink.api.district.dto;

/**
 * A district's label in both languages, wherever one is shown.
 *
 * <p>Both, not one (CR-MAPI-001): the app switches locale at runtime (FR-GLOBAL-001), so a server
 * that picked a language would force a re-fetch of the whole resource on every locale change, and
 * would put a presentation decision in the API.
 *
 * <p>One record shared by every response that carries a district — donor profile, hospital, request
 * detail. Two identical records in two packages drift, and the drift shows up as one screen
 * rendering Khmer while the next renders Latin.
 */
public record DistrictName(String km, String en) {}
