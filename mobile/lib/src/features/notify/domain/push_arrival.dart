/// A push message that reached this app while it was running — in the foreground, or
/// tapped from the tray while it sat in the background — or the tap that launched it.
///
/// Deliberately no `==`: two acceptances in a row carry the same [type], and a value
/// type would let Riverpod swallow the second as "unchanged".
final class PushArrival {
    PushArrival(this.type, {this.requestId, this.foreground = false});

    /// The payload's `type` — `REQUEST_ALERT` (FR-NOTIFY-001), `DONOR_ACCEPTED`
    /// (FR-NOTIFY-003), or `REQUEST_APPROVED` / `REQUEST_REJECTED` (DEC-015's admin
    /// review, to the requester). Empty for a message without one; any other value is
    /// ignored beyond the refetch every arrival triggers.
    final String type;

    /// The request the push is about, when the payload names one.
    final String? requestId;

    /// True when the push landed while the app was on screen (`onMessage`), false when
    /// it was tapped from the tray (`onMessageOpenedApp`, or `getInitialMessage` for a
    /// cold start). Only a foreground arrival has had no system notification — Android
    /// draws none for the app in front. A tap is a request to *open* something.
    final bool foreground;

    static const requestAlert = 'REQUEST_ALERT';
    static const donorAccepted = 'DONOR_ACCEPTED';
    static const requestApproved = 'REQUEST_APPROVED';
    static const requestRejected = 'REQUEST_REJECTED';
}
