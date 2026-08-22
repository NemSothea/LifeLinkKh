/// The three urgency levels `POST /requests` accepts — `RequestCreation.URGENCIES`
/// on the server, not a client invention.
///
/// No "unknown" member, same reasoning as `BloodType`: an unrecognised urgency is a
/// bug to surface, not a value to guess at.
enum Urgency {
    critical('CRITICAL'),
    urgent('URGENT'),
    routine('ROUTINE');

    const Urgency(this.wireValue);

    final String wireValue;

    static Urgency? fromWire(String? value) {
        for (final urgency in Urgency.values) {
            if (urgency.wireValue == value) return urgency;
        }
        return null;
    }

    /// Segmented-control order, and the wireframe's default selection: most requests
    /// are urgent, not critical, so starting there is one fewer tap for the common case.
    static const List<Urgency> segmentOrder = [Urgency.critical, Urgency.urgent, Urgency.routine];

    static const Urgency defaultValue = Urgency.urgent;
}
