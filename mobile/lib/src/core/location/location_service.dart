/// A GPS fix, precise enough for `NUMERIC(8,5)` ranking (ADR 0003) — never rendered, never
/// sent anywhere but `PUT /donors/me`.
typedef LocationFix = ({double latitude, double longitude});

/// The "use my current location" button behind `FR-DONOR-001`.
///
/// An interface — not just `DeviceLocationService` directly — so a widget test can fake a
/// GPS fix (or a decline) without touching a platform channel.
abstract interface class LocationService {
    /// `null` covers: location services off, permission denied (once or forever), and any
    /// platform error acquiring a fix. The caller cannot act differently on any of these —
    /// the outcome for the draft is the same "leave coordinates alone" — so they collapse here
    /// rather than becoming a richer error type nothing downstream would switch on.
    Future<LocationFix?> currentFix();
}
