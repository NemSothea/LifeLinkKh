import 'server-only';
import { serverAuth, serverDb, serverMessaging } from './firebase-admin';
import { FUNCTIONS } from './functions.js';
import { HttpsError } from './https-error.js';

/**
 * Run one portal function as the bearer of an ID token (ADR 0010) — what Cloud Functions'
 * `onCall` did before a handler ran: verify the token, or run the handler with no caller and
 * let it refuse. The route handler calls this for the app; the portal's Server Actions call it
 * in-process through `callFunction`, with the admin's session cookie as the token.
 *
 * The outcome is either the handler's result or an `HttpsError` — never anything else. A
 * handler bug becomes `internal`, logged with the function's name and nothing from the
 * request, because a request carries phone numbers.
 */
export type Invocation = { ok: true; result: unknown } | { ok: false; error: HttpsError };

export async function invoke(
    name: string,
    data: unknown,
    token: string | null,
): Promise<Invocation> {
    const handler = FUNCTIONS[name as keyof typeof FUNCTIONS];
    if (!handler)
        return { ok: false, error: new HttpsError('not-found', `No function named ${name}.`) };

    const caller = await verify(token);
    try {
        const result = await handler({
            db: serverDb(),
            auth: serverAuth(),
            messaging: serverMessaging(),
            caller,
            data,
            log: console,
        });
        return { ok: true, result };
    } catch (error) {
        if (error instanceof HttpsError) return { ok: false, error };
        console.error(`function ${name} failed:`, error instanceof Error ? error.message : error);
        return { ok: false, error: new HttpsError('internal', 'Something went wrong.') };
    }
}

/**
 * `{uid, token}` for a valid, unexpired Firebase ID token; null for none. A bad token is not
 * an error here — every handler refuses a null caller with its own code (`unauthenticated`
 * for the app's, `permission-denied` for the admin's), the same as a callable without auth.
 */
async function verify(
    token: string | null,
): Promise<{ uid: string; token: Record<string, unknown> } | null> {
    if (!token) return null;
    try {
        const decoded = await serverAuth().verifyIdToken(token);
        return { uid: decoded.uid, token: decoded as unknown as Record<string, unknown> };
    } catch {
        return null;
    }
}
