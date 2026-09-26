/// What the `deleteAccount` Function reports having done (DEC-016).
///
/// Nothing on screen shows these numbers today — the confirmation says what *will*
/// happen, and a deleted account has nowhere left to show what did. They are kept because
/// they are the only evidence on the device that the call did its work, and a test that
/// checks them tells a real answer from an empty one.
final class AccountDeletion {
    const AccountDeletion({
        required this.requestsClosed,
        required this.acceptancesWithdrawn,
        required this.recordsAnonymised,
    });

    /// The caller's own `PENDING` / `OPEN` requests, now `CANCELLED` with
    /// `cancelReason: 'ACCOUNT_DELETED'`.
    final int requestsClosed;

    /// Acceptances on requests that were still `OPEN`, now `WITHDRAWN`.
    final int acceptancesWithdrawn;

    /// Requests, matches and donations kept for the PRD metrics with the uid cleared.
    final int recordsAnonymised;

    @override
    bool operator ==(Object other) =>
        other is AccountDeletion &&
        other.requestsClosed == requestsClosed &&
        other.acceptancesWithdrawn == acceptancesWithdrawn &&
        other.recordsAnonymised == recordsAnonymised;

    @override
    int get hashCode => Object.hash(requestsClosed, acceptancesWithdrawn, recordsAnonymised);

    @override
    String toString() =>
        'AccountDeletion(closed: $requestsClosed, withdrawn: $acceptancesWithdrawn, '
        'anonymised: $recordsAnonymised)';
}
