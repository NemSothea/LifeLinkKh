/// A donor's sex, asked only because it sets the wait between donations (DEC-019): blood
/// centres in Cambodia ask men to wait 3 months and women 4 months, in line with WHO's 12 and
/// 16 weeks. Optional. "Prefer not to say" is null, and null gets the longer, safe interval.
///
/// Sensitive data: the donor document is readable by its owner and the admin only
/// (`firestore.rules`), and the privacy page says so.
enum DonorSex {
    male('M'),
    female('F');

    const DonorSex(this.wireValue);

    /// The value stored on `donors/{uid}.sex`.
    final String wireValue;

    static DonorSex? fromWire(Object? value) => switch (value) {
        'M' => DonorSex.male,
        'F' => DonorSex.female,
        _ => null,
    };
}
