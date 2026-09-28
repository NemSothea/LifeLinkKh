// The callable protocol's error, without firebase-functions (ADR 0010). The handlers throw one
// of these; `invoke.ts` turns it into the `{error: {status, message, details}}` body and HTTP
// status that `callFunction` in client.ts and the app's `cloud_functions` plugin already parse.
// The codes are Firebase's own spelling, so nothing on either client changed with the move.

/**
 * gRPC canonical name and HTTP status for each callable error code.
 * @type {Readonly<Record<string, readonly [string, number]>>}
 */
const CODES = Object.freeze({
    ok: ['OK', 200],
    cancelled: ['CANCELLED', 499],
    unknown: ['UNKNOWN', 500],
    'invalid-argument': ['INVALID_ARGUMENT', 400],
    'deadline-exceeded': ['DEADLINE_EXCEEDED', 504],
    'not-found': ['NOT_FOUND', 404],
    'already-exists': ['ALREADY_EXISTS', 409],
    'permission-denied': ['PERMISSION_DENIED', 403],
    unauthenticated: ['UNAUTHENTICATED', 401],
    'resource-exhausted': ['RESOURCE_EXHAUSTED', 429],
    'failed-precondition': ['FAILED_PRECONDITION', 400],
    aborted: ['ABORTED', 409],
    'out-of-range': ['OUT_OF_RANGE', 400],
    unimplemented: ['UNIMPLEMENTED', 501],
    internal: ['INTERNAL', 500],
    unavailable: ['UNAVAILABLE', 503],
    'data-loss': ['DATA_LOSS', 500],
});

export class HttpsError extends Error {
    /**
     * @param {string} code one of the keys of CODES, e.g. 'failed-precondition'
     * @param {string} message
     * @param {unknown} [details] a JSON-safe value the client reads (`details.code` in the app)
     */
    constructor(code, message, details) {
        super(message);
        if (!CODES[code]) throw new Error(`Unknown callable error code: ${code}`);
        this.name = 'HttpsError';
        this.code = code;
        this.details = details;
    }

    /** The gRPC canonical status the wire body carries, e.g. FAILED_PRECONDITION. */
    get status() {
        return CODES[this.code][0];
    }

    get httpStatus() {
        return CODES[this.code][1];
    }

    /** The `{error}` half of the callable response body. */
    toBody() {
        return {
            error: {
                status: this.status,
                message: this.message,
                ...(this.details === undefined ? {} : { details: this.details }),
            },
        };
    }
}
