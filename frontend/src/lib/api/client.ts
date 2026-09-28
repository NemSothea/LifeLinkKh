/**
 * The only place this app talks HTTP. Components never call `fetch` directly
 * (docs/tech-lead/coding-standards.md).
 *
 * ADR 0009, phase 5: the portal talks to Firebase instead of the Spring Boot API — Firestore and
 * the callable Functions over REST, **from the Next server, as the signed-in staff member**. The
 * staff member's own ID token is the bearer on every call, so the Security Rules decide what each
 * read returns exactly as they do for the app; nothing here holds an admin credential, and there is
 * no service account on this server. The token stays in the httpOnly cookie (`session.ts`) and
 * never reaches page script, which the Firebase Web SDK in the browser could not have kept.
 *
 * Emulators: set `FIRESTORE_EMULATOR_HOST`, `FIREBASE_AUTH_EMULATOR_HOST` and
 * `FUNCTIONS_EMULATOR_HOST` (host:port each) and every call goes there instead.
 *
 * Never read a secret through `NEXT_PUBLIC_`: that prefix embeds the value in the
 * browser bundle where anyone can read it.
 */
// Trimmed, and an empty value counts as unset: a variable saved blank or with a stray newline
// in a hosting dashboard would otherwise put `projects//databases` in every URL.
const PROJECT_ID = process.env.FIREBASE_PROJECT_ID?.trim() || 'lifelinkkh';
/** Where the Functions are deployed — `setGlobalOptions` in firebase/functions/src/index.js. */
const FUNCTIONS_REGION = 'asia-southeast1';

export type ApiResult<T> = { ok: true; data: T } | { ok: false; error: string };

// ── Firestore ──────────────────────────────────────────────────────────────────────────────────

function firestoreBase(): string {
    const emulator = process.env.FIRESTORE_EMULATOR_HOST;
    const root = emulator ? `http://${emulator}/v1` : 'https://firestore.googleapis.com/v1';
    return `${root}/projects/${PROJECT_ID}/databases/(default)/documents`;
}

/** A Firestore REST value, as the API sends it. */
type FirestoreValue = {
    nullValue?: null;
    booleanValue?: boolean;
    integerValue?: string;
    doubleValue?: number;
    timestampValue?: string;
    stringValue?: string;
    mapValue?: { fields?: Record<string, FirestoreValue> };
    arrayValue?: { values?: FirestoreValue[] };
};

/** A decoded document: its id, and its fields as plain JSON. Timestamps are ISO strings. */
export type Doc = { id: string; data: Record<string, unknown> };

export function decodeValue(value: FirestoreValue): unknown {
    if ('stringValue' in value) return value.stringValue;
    if ('integerValue' in value) return Number(value.integerValue);
    if ('doubleValue' in value) return value.doubleValue;
    if ('booleanValue' in value) return value.booleanValue;
    if ('timestampValue' in value) return value.timestampValue;
    if ('mapValue' in value) return decodeFields(value.mapValue?.fields);
    if ('arrayValue' in value) return (value.arrayValue?.values ?? []).map(decodeValue);
    return null;
}

function decodeFields(fields: Record<string, FirestoreValue> | undefined): Record<string, unknown> {
    return Object.fromEntries(Object.entries(fields ?? {}).map(([k, v]) => [k, decodeValue(v)]));
}

function decodeDoc(raw: { name: string; fields?: Record<string, FirestoreValue> }): Doc {
    return { id: raw.name.slice(raw.name.lastIndexOf('/') + 1), data: decodeFields(raw.fields) };
}

function encodeValue(value: string | number | boolean | null): FirestoreValue {
    if (value === null) return { nullValue: null };
    if (typeof value === 'string') return { stringValue: value };
    if (typeof value === 'boolean') return { booleanValue: value };
    return Number.isInteger(value) ? { integerValue: String(value) } : { doubleValue: value };
}

function authHeaders(token: string | null): Record<string, string> {
    return token ? { Authorization: `Bearer ${token}` } : {};
}

export type Query = {
    /** A collection id, optionally under a parent document path: `acceptedDonors` in `requests/r1`. */
    collection: string;
    parent?: string;
    /** Equality filters only — every query the portal makes is one. */
    where?: Record<string, string | number | boolean | null>;
    orderBy?: { field: string; direction: 'ASCENDING' | 'DESCENDING' };
    limit?: number;
};

/**
 * `runQuery`. `token` is the staff member's ID token, or `null` for a public read — which is then
 * evaluated by the rules as signed out, the same as a visitor to the board.
 */
export async function firestoreQuery(
    query: Query,
    token: string | null,
): Promise<ApiResult<Doc[]>> {
    const filters = Object.entries(query.where ?? {}).map(([field, value]) => ({
        fieldFilter: { field: { fieldPath: field }, op: 'EQUAL', value: encodeValue(value) },
    }));
    const structuredQuery = {
        from: [{ collectionId: query.collection }],
        ...(filters.length === 1 ? { where: filters[0] } : {}),
        ...(filters.length > 1 ? { where: { compositeFilter: { op: 'AND', filters } } } : {}),
        ...(query.orderBy
            ? {
                  orderBy: [
                      {
                          field: { fieldPath: query.orderBy.field },
                          direction: query.orderBy.direction,
                      },
                  ],
              }
            : {}),
        ...(query.limit ? { limit: query.limit } : {}),
    };
    const parent = query.parent ? `/${query.parent}` : '';
    const result = await send<
        { document?: { name: string; fields?: Record<string, FirestoreValue> } }[]
    >(`${firestoreBase()}${parent}:runQuery`, {
        method: 'POST',
        headers: authHeaders(token),
        body: { structuredQuery },
    });
    if (!result.ok) return result;
    return {
        ok: true,
        data: result.data.flatMap((row) => (row.document ? [decodeDoc(row.document)] : [])),
    };
}

/** One document, or `null` when it does not exist. */
export async function firestoreGet(
    path: string,
    token: string | null,
): Promise<ApiResult<Doc | null>> {
    const result = await send<{ name: string; fields?: Record<string, FirestoreValue> }>(
        `${firestoreBase()}/${path}`,
        { method: 'GET', headers: authHeaders(token) },
    );
    if (!result.ok) return result.error === 'HTTP 404' ? { ok: true, data: null } : result;
    return { ok: true, data: decodeDoc(result.data) };
}

// ── Callable Functions ─────────────────────────────────────────────────────────────────────────

function functionUrl(name: string): string {
    const emulator = process.env.FUNCTIONS_EMULATOR_HOST;
    return emulator
        ? `http://${emulator}/${PROJECT_ID}/${FUNCTIONS_REGION}/${name}`
        : `https://${FUNCTIONS_REGION}-${PROJECT_ID}.cloudfunctions.net/${name}`;
}

/**
 * The callable protocol over plain HTTP: `{data}` in, `{result}` out. A refusal comes back as
 * the HttpsError's code in the Functions' own spelling — `already-exists`, `failed-precondition`,
 * `permission-denied` — which is what the Server Actions branch on. The message is dropped: it
 * is written for a developer, and a page must not describe the server.
 */
export async function callFunction<T>(
    name: string,
    data: unknown,
    token: string,
): Promise<ApiResult<T>> {
    const result = await send<{ result: T }>(functionUrl(name), {
        method: 'POST',
        headers: authHeaders(token),
        body: { data },
        errorCode: (body) => {
            const status = (body as { error?: { status?: string } } | null)?.error?.status;
            return status ? status.toLowerCase().replace(/_/g, '-') : null;
        },
    });
    return result.ok ? { ok: true, data: result.data.result } : result;
}

// ── Firebase Auth (Identity Toolkit) ───────────────────────────────────────────────────────────

/**
 * `accounts:signInWithPassword`, `accounts:update`. Firebase Auth's own REST API, which is what
 * the Web SDK calls underneath. The key identifies the project, not the caller — it is not a
 * secret (it ships in every Firebase app) — and the emulator accepts any value.
 */
export async function identityToolkit<T>(method: string, body: unknown): Promise<ApiResult<T>> {
    const emulator = process.env.FIREBASE_AUTH_EMULATOR_HOST;
    const root = emulator
        ? `http://${emulator}/identitytoolkit.googleapis.com/v1`
        : 'https://identitytoolkit.googleapis.com/v1';
    const key = process.env.FIREBASE_API_KEY?.trim() || (emulator ? 'emulator' : '');
    return send<T>(`${root}/accounts:${method}?key=${encodeURIComponent(key)}`, {
        method: 'POST',
        body,
        // Identity Toolkit names the failure in `error.message`: `INVALID_LOGIN_CREDENTIALS`,
        // `TOO_MANY_ATTEMPTS_TRY_LATER : …`, `WEAK_PASSWORD : …`. The code before any colon.
        errorCode: (payload) => {
            const message = (payload as { error?: { message?: string } } | null)?.error?.message;
            return message ? message.split(' ')[0] : null;
        },
    });
}

// ── Transport ──────────────────────────────────────────────────────────────────────────────────

async function send<T>(
    url: string,
    init: {
        method: 'GET' | 'POST';
        headers?: Record<string, string>;
        body?: unknown;
        errorCode?: (body: unknown) => string | null;
    },
): Promise<ApiResult<T>> {
    try {
        // no-store: a cached portal response would show yesterday's acceptedCount as today's.
        const response = await fetch(url, {
            method: init.method,
            cache: 'no-store',
            headers: {
                ...(init.body === undefined ? {} : { 'Content-Type': 'application/json' }),
                ...init.headers,
            },
            body: init.body === undefined ? undefined : JSON.stringify(init.body),
        });

        if (!response.ok) {
            const payload = init.errorCode ? await response.json().catch(() => null) : null;
            return { ok: false, error: init.errorCode?.(payload) ?? `HTTP ${response.status}` };
        }
        return { ok: true, data: (await response.json()) as T };
    } catch {
        // The cause is deliberately not surfaced — an error string rendered in a page
        // must not describe the server's internals.
        return { ok: false, error: 'unreachable' };
    }
}
