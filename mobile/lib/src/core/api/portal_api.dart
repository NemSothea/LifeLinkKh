/// The portal's functions (ADR 0010): what the Cloud Functions were, now served by the web
/// portal's own server at `POST /api/functions/{name}` — `createRequest`, `respondToMatch`,
/// `deleteAccount`. Same callable protocol, so the app still speaks it through
/// `cloud_functions`; only the address changed.
///
/// An interface, so a repository test hands in a fake and never reaches a platform
/// channel. The real one is [FunctionsPortalApi].
abstract interface class PortalApi {
    /// Calls the function and returns its `result`, as decoded JSON. Throws
    /// [PortalCallException] for a refusal, and for a network that did not answer.
    Future<Object?> call(String name, [Object? data]);
}

/// A refusal, in the callable protocol's own words: [code] is Firebase's spelling
/// (`failed-precondition`, `not-found`, `unavailable`…), and [details] is what the server
/// put beside it — the app switches on `details.code` ([reason]), never on the message,
/// which is English prose meant for a log.
final class PortalCallException implements Exception {
    const PortalCallException({required this.code, this.details, this.message});

    final String code;
    final Object? details;
    final String? message;

    /// The server's stable reason, e.g. `ALREADY_RESPONDED`, `RATE_LIMITED`. Null when the
    /// refusal carried none.
    String? get reason {
        final details = this.details;
        return details is Map ? details['code'] as String? : null;
    }

    @override
    String toString() => 'PortalCallException($code${reason == null ? '' : ', $reason'})';
}
