/// `matches/{id}.response` — the two answers a donor can give.
///
/// `WITHDRAWN` is deliberately not a member. Since DEC-016 it is a real stored value: a
/// deleted donor's acceptance on a request that was still open. But no donor can *give*
/// it, and nobody left can see it as theirs — the match's `donorUid` is cleared with the
/// account — so it is recognised by [withdrawnWireValue] and skipped, not modelled.
/// [fromWire] maps it to `null` like any other unknown value, never a throw.
enum MatchResponseType {
    accepted('ACCEPTED'),
    declined('DECLINED');

    const MatchResponseType(this.wireValue);

    final String wireValue;

    /// DEC-016: an acceptance withdrawn because the donor deleted their account.
    static const String withdrawnWireValue = 'WITHDRAWN';

    static MatchResponseType? fromWire(String? value) {
        for (final type in MatchResponseType.values) {
            if (type.wireValue == value) return type;
        }
        return null;
    }
}
