/// One row from `GET /hospitals` — the request form's dropdown.
///
/// No coordinates: `HospitalResponse` never sends them (no client draws a map,
/// DEC-004), so there is nothing here for this type to carry and nothing to leak.
final class Hospital {
    const Hospital({required this.id, required this.name, this.districtNameKm, this.districtNameEn});

    final String id;
    final String name;

    /// Null until a hospital's `district_code` is backfilled — the column is
    /// nullable on the server (`V4__hospitals_district.sql`), display only.
    final String? districtNameKm;
    final String? districtNameEn;

    String? districtLabel(String languageCode) =>
        languageCode == 'en' ? districtNameEn : districtNameKm;
}
