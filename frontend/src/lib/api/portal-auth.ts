import { identityToolkit, type ApiResult } from './client';

/**
 * Portal sign-in on Firebase Auth (ADR 0009, phase 5) — the one module in this app that takes
 * a password.
 *
 * Called only from Server Actions, never from the browser: the response carries the session's
 * ID token, and the whole point of the cookie in `session.ts` is that the token never exists in
 * page script.
 */
export type PortalSession = {
    token: string;
    user: { id: string; role: string; displayName: string | null };
};

/**
 * A username as Firebase Auth knows it. The same mapping as `portalEmail` in
 * `firebase/functions/src/portal-accounts.js`, which the admin seed uses — change both or neither.
 */
export function portalEmail(username: string): string {
    return `${username}@portal.lifelink.invalid`;
}

/** Unverified, as in `session.ts`: it decides whether to keep a token Google just issued. */
function tokenClaims(idToken: string): { role?: unknown; name?: unknown } {
    try {
        return JSON.parse(Buffer.from(idToken.split('.')[1], 'base64url').toString('utf-8'));
    } catch {
        return {};
    }
}

type SignInResponse = { idToken: string; localId: string; displayName?: string };

/**
 * The errors are the Identity Toolkit's own codes. The caller collapses "no such account",
 * "wrong password" and "disabled" into one answer; `TOO_MANY_ATTEMPTS_TRY_LATER` and
 * `unreachable` are kept apart because they say nothing about whether an account exists.
 */
export async function portalLogin(
    username: string,
    password: string,
): Promise<ApiResult<PortalSession>> {
    const result = await identityToolkit<SignInResponse>('signInWithPassword', {
        email: portalEmail(username.toLowerCase()),
        password,
        returnSecureToken: true,
    });
    if (!result.ok) return result;

    // A valid password on an account with no staff claim — a revoked account that was not
    // disabled, say — is not a portal session. Same answer as a wrong password.
    const claims = tokenClaims(result.data.idToken);
    const role = typeof claims.role === 'string' ? claims.role : null;
    if (role !== 'ADMIN') return { ok: false, error: 'NOT_ADMIN' };
    // The token's `name` claim: the sign-in response carries `displayName` in production but
    // not from the Auth emulator, and the token is the one place both agree on.
    const displayName =
        result.data.displayName ?? (typeof claims.name === 'string' ? claims.name : null);

    return {
        ok: true,
        data: {
            token: result.data.idToken,
            user: { id: result.data.localId, role, displayName },
        },
    };
}

/**
 * A staff member changing their own password. The current password is checked by signing in
 * with it — the caller's session alone must not be enough, or a borrowed unlocked browser could
 * lock the owner out. Returns the fresh ID token: changing the password revokes the old session.
 *
 * Errors: `INVALID_LOGIN_CREDENTIALS` (the current password is wrong), `WEAK_PASSWORD`.
 */
export async function changePassword(
    username: string,
    currentPassword: string,
    newPassword: string,
): Promise<ApiResult<{ token: string }>> {
    const verified = await portalLogin(username, currentPassword);
    if (!verified.ok) return verified;

    const updated = await identityToolkit<{ idToken: string }>('update', {
        idToken: verified.data.token,
        password: newPassword,
        returnSecureToken: true,
    });
    return updated.ok ? { ok: true, data: { token: updated.data.idToken } } : updated;
}
