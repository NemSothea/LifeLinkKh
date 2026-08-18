/// The eight ABO/Rh values, and only those.
///
/// No `unknown` member. A donor with an unknown type has no row in `blood_compatibility`
/// (ADR 0004), so such a profile would be saved, look complete, and silently never match —
/// which is worse than being told to find out first (`FR-DONOR-001`).
enum BloodType {
    oNegative('O-'),
    oPositive('O+'),
    aNegative('A-'),
    aPositive('A+'),
    bNegative('B-'),
    bPositive('B+'),
    abNegative('AB-'),
    abPositive('AB+');

    const BloodType(this.wireValue);

    /// Exactly what the API accepts and returns. Also the label: `O-` is `O-` in Khmer and
    /// English alike, so this one string is both wire format and UI copy.
    final String wireValue;

    /// Returns `null` for anything unrecognised rather than throwing. A profile the app
    /// cannot read is a bug to surface, not a crash on the donor's screen.
    static BloodType? fromWire(String? value) {
        for (final type in BloodType.values) {
            if (type.wireValue == value) return type;
        }
        return null;
    }

    /// Grid order for the selector: O first, then A, B, AB — negative before positive within
    /// each group. `FR-DONOR-001` requires all eight visible at once, so this is the reading
    /// order of a 4×2 grid, not an arbitrary list.
    static const List<BloodType> gridOrder = [
        BloodType.oNegative,
        BloodType.oPositive,
        BloodType.aNegative,
        BloodType.aPositive,
        BloodType.bNegative,
        BloodType.bPositive,
        BloodType.abNegative,
        BloodType.abPositive,
    ];
}
