/// `blood_requests.status`. `expired` is unreachable in this build — `FR-REQUEST-005`
/// is deferred (DEC-004) — but the wire value exists on the server, so it is parsed
/// rather than treated as invalid if it is ever seen.
///
/// `pending` and `rejected` are DEC-015's admin review: every request is created
/// `PENDING` and no donor hears of it until an admin moves it to `OPEN`; a refused one
/// becomes `REJECTED` with the admin's reason. Only the creator (and the admin) can read
/// either, so a donor's screens never meet them.
enum RequestStatus {
    pending('PENDING'),
    open('OPEN'),
    rejected('REJECTED'),
    fulfilled('FULFILLED'),
    cancelled('CANCELLED'),
    expired('EXPIRED');

    const RequestStatus(this.wireValue);

    final String wireValue;

    /// The two states the rules let the creator cancel from. Checked here rather than
    /// as `== open` at each call site, so the button and the rule cannot drift apart.
    bool get isCancellable => this == pending || this == open;

    static RequestStatus? fromWire(String? value) {
        for (final status in RequestStatus.values) {
            if (status.wireValue == value) return status;
        }
        return null;
    }
}
