/// The requester's callback details, revealed only after a donor accepts.
///
/// [phoneVerified] is always `false` in this build (ADR 0002 — phone numbers stopped
/// being verified when auth moved to Google Sign-In). It travels as a field rather
/// than being assumed by the screen so the caveat cannot silently be dropped if the
/// server ever starts sending `true`.
final class RequesterContact {
    const RequesterContact({
        required this.displayName,
        required this.phone,
        required this.phoneVerified,
    });

    final String displayName;
    final String phone;
    final bool phoneVerified;
}
