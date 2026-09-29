/// Why a donor flags a request (DEC-019). The wire values are the ones `firestore.rules`
/// accepts on `reports/{id}.reason`.
enum ReportReason {
    money('MONEY'),
    fake('FAKE'),
    harassment('HARASSMENT'),
    other('OTHER');

    const ReportReason(this.wireValue);

    final String wireValue;
}
