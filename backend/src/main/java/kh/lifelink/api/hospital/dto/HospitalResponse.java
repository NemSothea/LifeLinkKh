package kh.lifelink.api.hospital.dto;

import java.util.UUID;
import kh.lifelink.api.district.dto.DistrictName;

/**
 * A hospital as the request form's dropdown needs it.
 *
 * <p>Deliberately without {@code latitude}/{@code longitude}. They are public facts and ADR 0003's
 * response ban does not apply to them — but nothing in either client draws a map (DEC-004), so
 * returning them would be shipping a field with no reader. {@code address} and {@code contactPhone}
 * are omitted for the same reason.
 *
 * @param districtName null when the hospital has no district yet — the column is nullable until the
 *     V5 seed lands, and the contract marks the field optional
 */
public record HospitalResponse(UUID id, String name, DistrictName districtName) {}
