/// `request_matches.response`. `WITHDRAWN` is a column value with no rule behind it
/// — `FR-REQUEST-004` is deferred — and `MatchService.RESPONSES` on the server never
/// accepts it, so it has no member here either.
enum MatchResponseType {
    accepted('ACCEPTED'),
    declined('DECLINED');

    const MatchResponseType(this.wireValue);

    final String wireValue;

    static MatchResponseType? fromWire(String? value) {
        for (final type in MatchResponseType.values) {
            if (type.wireValue == value) return type;
        }
        return null;
    }
}
