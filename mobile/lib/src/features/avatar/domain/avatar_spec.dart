import '../../donor/domain/donor_sex.dart';

/// Which kind of face the avatar draws. Separate from `DonorSex` on purpose: that one is
/// medical data with a "prefer not to say" null (DEC-019), this one is a picture the user
/// chose — someone may well pick a face that says nothing about them.
enum AvatarGender {
    male('m'),
    female('f');

    const AvatarGender(this.wireValue);

    final String wireValue;

    static AvatarGender? fromWire(String value) => switch (value) {
        'm' => AvatarGender.male,
        'f' => AvatarGender.female,
        _ => null,
    };
}

/// A generated avatar: a gender and a seed. Everything else — skin tone, hair, colours —
/// is derived from the seed by `ProfileAvatar`, so the same spec draws the same face on
/// every launch and nothing but these two values ever needs storing.
///
/// Drawn on the phone, never fetched: an avatar service would get a request per user per
/// screen, and the seed would have to leave the device to get one.
final class AvatarSpec {
    const AvatarSpec({required this.gender, required this.seed});

    /// The face a user sees before they have picked one. Stable for a user id, so it does
    /// not change between launches, and follows the donor profile's sex when there is one.
    /// With no sex given, the id picks — either face is equally a guess.
    factory AvatarSpec.defaultFor(String userId, {DonorSex? sex}) {
        final hash = stableHash(userId);
        final gender = switch (sex) {
            DonorSex.male => AvatarGender.male,
            DonorSex.female => AvatarGender.female,
            null => hash.isEven ? AvatarGender.male : AvatarGender.female,
        };
        return AvatarSpec(gender: gender, seed: hash);
    }

    final AvatarGender gender;

    /// Non-negative, and under 2^31 so it survives a round trip through any store.
    final int seed;

    /// `m:12345` — what `AvatarStore` keeps.
    String encode() => '${gender.wireValue}:$seed';

    /// Null for anything [encode] did not produce, so a corrupt value falls back to the
    /// default face instead of throwing on the Me tab.
    static AvatarSpec? decode(String? value) {
        if (value == null) return null;
        final parts = value.split(':');
        if (parts.length != 2) return null;
        final gender = AvatarGender.fromWire(parts[0]);
        final seed = int.tryParse(parts[1]);
        if (gender == null || seed == null || seed < 0) return null;
        return AvatarSpec(gender: gender, seed: seed);
    }

    AvatarSpec copyWith({AvatarGender? gender, int? seed}) =>
        AvatarSpec(gender: gender ?? this.gender, seed: seed ?? this.seed);

    @override
    bool operator ==(Object other) =>
        other is AvatarSpec && other.gender == gender && other.seed == seed;

    @override
    int get hashCode => Object.hash(gender, seed);

    @override
    String toString() => 'AvatarSpec(${encode()})';
}

/// FNV-1a over the UTF-16 code units, masked to 31 bits. `String.hashCode` is not
/// promised to be the same across runs, and a default avatar that changed on every
/// launch would be worse than none.
int stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
        hash ^= unit;
        hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
}
