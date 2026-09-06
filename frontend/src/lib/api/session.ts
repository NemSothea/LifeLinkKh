import { cookies } from 'next/headers';

/**
 * The portal's session, as the server sees it.
 *
 * Replaces `dev-auth.ts` and `PORTAL_DEV_JWT` — a token pasted into `.env` by hand, shared
 * by whoever had the file, owned by nobody, and impossible to end from inside the product.
 * Staff now sign in at `/[locale]/sign-in` with a username and password
 * (`POST /auth/portal/login`), and the session JWT the backend issues is stored here.
 *
 * **httpOnly.** The token is a bearer credential: whoever holds it is that staff account
 * for an hour. Script on the page cannot read this cookie, so an injected script cannot
 * steal the session — which is exactly what `localStorage` would give away. Every call
 * that uses it runs on the Next server (Server Components and Server Actions); the value
 * never reaches the browser at all.
 */
export const SESSION_COOKIE = 'lifelink_portal_session';

/**
 * One hour, matching `JwtService`'s own expiry. Deliberately not longer: the cookie
 * outliving the token would leave staff on a page that 401s on every action instead of
 * sending them to sign in.
 */
export const SESSION_MAX_AGE_SECONDS = 3600;

export async function portalToken(): Promise<string | null> {
    return (await cookies()).get(SESSION_COOKIE)?.value ?? null;
}

/** True when a session cookie is present. Says nothing about whether it is still valid. */
export async function hasPortalSession(): Promise<boolean> {
    return (await portalToken()) !== null;
}

export async function portalAuthHeader(): Promise<HeadersInit> {
    const token = await portalToken();
    if (!token) {
        // Reached only if a page called the API without checking for a session first. The
        // pages redirect to /sign-in instead, so this is a programming error, not a state a
        // signed-out visitor can produce.
        throw new Error('No portal session. Redirect to /sign-in before calling the API.');
    }
    return { Authorization: `Bearer ${token}` };
}

/**
 * Reads the `role` claim straight out of the token, unverified — good enough to decide
 * whether to render the "Manage staff" link, never to authorize a write. The backend
 * checks the real, signed claim on every `/admin/*` call regardless of what this returns.
 */
export async function portalRole(): Promise<string | null> {
    const token = await portalToken();
    if (!token) return null;
    try {
        const payload = token.split('.')[1];
        const json = Buffer.from(payload, 'base64url').toString('utf-8');
        return (JSON.parse(json) as { role?: string }).role ?? null;
    } catch {
        return null;
    }
}

/**
 * The signed-in account's own id, read from the token's `sub` claim. Used to hide the buttons on
 * an admin's own staff row — never to authorize anything, which the backend does from the signed
 * claim regardless.
 */
export async function portalUserId(): Promise<string | null> {
    const token = await portalToken();
    if (!token) return null;
    try {
        const payload = token.split('.')[1];
        return (JSON.parse(Buffer.from(payload, 'base64url').toString('utf-8')) as { sub?: string })
            .sub ?? null;
    } catch {
        return null;
    }
}

/** The signed-in staff member's display name, for the header. Never used as an identity. */
export async function portalDisplayName(): Promise<string | null> {
    return (await cookies()).get(`${SESSION_COOKIE}_name`)?.value ?? null;
}
