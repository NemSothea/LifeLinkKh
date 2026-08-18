/// The four roles the backend knows. `HOSPITAL` and `ADMIN` exist here only so that a
/// JWT carrying one can be read back — they are **not** offerable at sign-up, and
/// asking for one is a 422 (`ROLE_NOT_SELF_SERVICE`, `TM-AUTH-001` E1).
enum UserRole {
    donor('DONOR'),
    requester('REQUESTER'),
    hospital('HOSPITAL'),
    admin('ADMIN');

    const UserRole(this.wireValue);

    /// The exact string the API uses. Never `name.toUpperCase()` — a rename of the
    /// Dart identifier would then silently change the wire contract.
    final String wireValue;

    /// The two roles the mobile app may request at sign-up.
    static const Set<UserRole> selfService = {UserRole.donor, UserRole.requester};

    /// Returns `null` for an unrecognised value instead of throwing, so a backend that
    /// adds a fifth role does not crash an installed app.
    static UserRole? fromWire(String? value) {
        for (final role in UserRole.values) {
            if (role.wireValue == value) return role;
        }
        return null;
    }
}
