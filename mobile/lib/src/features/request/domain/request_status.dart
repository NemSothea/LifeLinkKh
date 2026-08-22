/// `blood_requests.status`. `expired` is unreachable in this build — `FR-REQUEST-005`
/// is deferred (DEC-004) — but the wire value exists on the server, so it is parsed
/// rather than treated as invalid if it is ever seen.
enum RequestStatus {
    open('OPEN'),
    fulfilled('FULFILLED'),
    cancelled('CANCELLED'),
    expired('EXPIRED');

    const RequestStatus(this.wireValue);

    final String wireValue;

    static RequestStatus? fromWire(String? value) {
        for (final status in RequestStatus.values) {
            if (status.wireValue == value) return status;
        }
        return null;
    }
}
