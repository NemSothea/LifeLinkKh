import { cookies } from 'next/headers';

/**
 * The portal's session, as the server sees it.
 *
 * Replaces `dev-auth.ts` and `PORTAL_DEV_JWT` — a token pasted into `.env` by hand, shared
 * by whoever had the file, owned by nobody, and impossible to end from inside the product.
 * Staff sign in at `/[locale]/sign-in` with a username and password, and the Firebase ID
 * token Firebase Auth issues for that account (ADR 0009) is stored here.
 *
 * **httpOnly.** The token is a bearer credential: whoever holds it is that staff account
 * for an hour. Script on the page cannot read this cookie, so an injected script cannot
 * steal the session — which is exactly what `localStorage` would give away. Every call
 * that uses it runs on the Next server (Server Components and Server Actions); the value
 * never reaches the browser at all.
 */
export const SESSION_COOKIE = 'lifelink_portal_session';

/**
 * One hour, matching a Firebase ID token's own expiry. Deliberately not longer: the cookie
 * outliving the token would leave staff on a page where every read is refused instead of
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

/**
 * The session token, for a call that needs one. The pages redirect to /sign-in first, so a
 * missing session here is a programming error — and it must fail loudly rather than quietly
 * make the call signed out, where the rules would answer it as a visitor.
 */
export async function requirePortalToken(): Promise<string> {
    const token = await portalToken();
    if (!token) {
        throw new Error('No portal session. Redirect to /sign-in before calling the API.');
    }
    return token;
}

/**
 * The token's claims, read straight out of it, unverified — good enough to decide what to
 * render or which query to ask, never to authorize anything. Firestore's rules and the
 * Functions verify the signed token on every call regardless of what this returns.
 */
async function claims(): Promise<{
    sub?: string;
    role?: string;
    email?: string;
    firebase?: { sign_in_provider?: string };
} | null> {
    const token = await portalToken();
    if (!token) return null;
    try {
        const payload = token.split('.')[1];
        return JSON.parse(Buffer.from(payload, 'base64url').toString('utf-8'));
    } catch {
        return null;
    }
}

/** `ADMIN` — the custom claim `firebase/seed/admin.mjs` sets. v1 has no other portal role. */
export async function portalRole(): Promise<string | null> {
    return (await claims())?.role ?? null;
}

/**
 * The signed-in account's own uid, read from the token's `sub` claim. Used to hide the buttons on
 * an admin's own staff row — never to authorize anything.
 */
export async function portalUserId(): Promise<string | null> {
    return (await claims())?.sub ?? null;
}

/**
 * The portal username, recovered from the account's email (`portalEmail` in `portal-auth.ts`).
 * Used only to re-check the current password when someone changes it.
 */
export async function portalUsername(): Promise<string | null> {
    const email = (await claims())?.email;
    // A Google admin's email is their own address, not a portal username.
    if (!email?.endsWith(PORTAL_EMAIL_DOMAIN)) return null;
    return email.slice(0, -PORTAL_EMAIL_DOMAIN.length);
}

const PORTAL_EMAIL_DOMAIN = '@portal.lifelink.invalid';

/**
 * True when this session came from a portal password (`signInWithPassword`), false for Google
 * sign-in. A Google admin has no portal password to change.
 */
export async function portalHasPassword(): Promise<boolean> {
    return (await claims())?.firebase?.sign_in_provider === 'password';
}

/** The signed-in staff member's display name, for the header. Never used as an identity. */
export async function portalDisplayName(): Promise<string | null> {
    return (await cookies()).get(`${SESSION_COOKIE}_name`)?.value ?? null;
}
