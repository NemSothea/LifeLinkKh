/// One Phnom Penh khan, from `GET /districts`.
///
/// Both labels travel together because the app switches language at runtime
/// (`FR-GLOBAL-001`); holding one would mean re-fetching the list to change locale.
final class District {
    const District({required this.code, required this.nameKm, required this.nameEn});

    /// National geocode — `1204`. A foreign key on the server, so this is the one field that
    /// must not be invented client-side.
    final String code;

    final String nameKm;
    final String nameEn;

    /// The label for a locale. Khmer is the default and the fallback: the pilot is Phnom Penh
    /// and a Latin-only dropdown is unusable for most donors.
    String label(String languageCode) => languageCode == 'en' ? nameEn : nameKm;

    @override
    bool operator ==(Object other) =>
        other is District &&
        other.code == code &&
        other.nameKm == nameKm &&
        other.nameEn == nameEn;

    @override
    int get hashCode => Object.hash(code, nameKm, nameEn);

    @override
    String toString() => 'District($code, $nameEn)';
}
