'use server';

import { cookies, headers } from 'next/headers';
import { redirect } from 'next/navigation';
import { portalGoogleLogin, portalLogin, type PortalSession } from '@/lib/api/portal-auth';
import type { ApiResult } from '@/lib/api/client';
import { routing, type Locale } from '@/i18n/routing';
import { passwordSignInEnabled } from '@/lib/api/sign-in-options';
import { SESSION_COOKIE, SESSION_MAX_AGE_SECONDS } from '@/lib/api/session';
import { serverAuth, serverDb } from '@/server/firebase-admin';
import { clearSignInFailures, recordSignInFailure, signInBlocked } from '@/server/sign-in-throttle';

/**
 * Sign in, and put the session where page script cannot reach it.
 *
 * The password is read from the form on the server and forwarded to Firebase Auth from the
 * server. It is never a prop, never in a URL, never in a redirect, and never logged — the
 * only two places it exists are the POST body the browser sends over TLS and the one the
 * Next server makes to Firebase Auth.
 */
/**
 * What went wrong, at the only granularity that is safe to show.
 *
 * `invalid` deliberately covers "no such username", "wrong password", "disabled" and "not
 * an admin" — Firebase Auth answers the first two identically on purpose, and a page that
 * separated them would enumerate the admin accounts from the outside. `rateLimited` and `unreachable` are a different class: they
 * say nothing about whether an account exists, and hiding them behind "wrong password" sends
 * someone to retype a password that was right all along.
 */
export type SignInError = 'invalid' | 'rateLimited' | 'unreachable';

export async function signInAction(
    _previous: SignInError | null | undefined,
    formData: FormData,
): Promise<SignInError | null> {
    const username = formData.get('username');
    const password = formData.get('password');
    const locale = formData.get('locale');

    if (
        typeof username !== 'string' ||
        typeof password !== 'string' ||
        typeof locale !== 'string'
    ) {
        return 'invalid';
    }

    // Turned off, the form is not rendered — and a hand-made POST is refused here as well.
    if (!passwordSignInEnabled()) return 'invalid';

    // SEC-REVIEW-003 F-08: per-IP, on top of Firebase's per-account lockout. The throttle
    // failing open is deliberate — a Firestore outage must not lock the admin out as well.
    const ip = await clientIp();
    const throttle = await guarded(() => signInBlocked(serverDb(), ip));
    if (throttle === true) return 'rateLimited';

    const result = await portalLogin(username.trim(), password);
    if (result.ok) await guarded(() => clearSignInFailures(serverDb(), ip));
    else if (result.error !== 'unreachable')
        await guarded(() => recordSignInFailure(serverDb(), ip));
    return startSession(result, locale);
}

/** Vercel puts the client first in `x-forwarded-for`; locally there is none. */
async function clientIp(): Promise<string> {
    const h = await headers();
    return h.get('x-forwarded-for')?.split(',')[0]?.trim() || h.get('x-real-ip')?.trim() || 'local';
}

async function guarded<T>(step: () => Promise<T>): Promise<T | null> {
    try {
        return await step();
    } catch (error) {
        console.warn(`sign-in throttle unavailable: ${(error as Error)?.message ?? error}`);
        return null;
    }
}

/**
 * Sign in with Google (admins only). The browser hands over the ID token Google Identity
 * Services just issued; the exchange for a Firebase session happens here, so the Firebase token
 * never exists in page script — the same as the password path.
 */
export async function googleSignInAction(
    credential: unknown,
    locale: unknown,
): Promise<SignInError | null> {
    if (typeof credential !== 'string' || credential === '' || typeof locale !== 'string') {
        return 'invalid';
    }
    const result = await portalGoogleLogin(credential);
    // The page collapses every refusal into one sentence; the server log keeps Firebase's code
    // (never the token or the account) so a misconfigured OAuth client can be told apart from a
    // Google account that simply is not an admin.
    if (!result.ok && result.error !== 'NOT_ADMIN') {
        console.warn(`Google sign-in refused by Firebase Auth: ${result.error}`);
    }
    return startSession(result, locale);
}

async function startSession(
    result: ApiResult<PortalSession>,
    locale: string,
): Promise<SignInError | null> {
    if (!result.ok) {
        if (result.error === 'unreachable') return 'unreachable';
        // Firebase Auth's lockout after repeated failures on one account — not a rejected
        // credential, so it gets its own sentence.
        if (result.error === 'TOO_MANY_ATTEMPTS_TRY_LATER') return 'rateLimited';
        return 'invalid';
    }

    const store = await cookies();
    store.set(SESSION_COOKIE, result.data.token, {
        httpOnly: true,
        sameSite: 'lax',
        // Off on localhost, on everywhere else — a Secure cookie is simply not sent over
        // the plain HTTP the local stack serves, which would make sign-in appear to succeed
        // and then bounce straight back to this page.
        secure: process.env.NODE_ENV === 'production',
        path: '/',
        maxAge: SESSION_MAX_AGE_SECONDS,
    });
    // Not httpOnly and deliberately not the session: a display name is not a credential, and
    // the header needs it on every render. Kept in its own cookie so the token stays the one
    // value no page can read.
    store.set(`${SESSION_COOKIE}_name`, result.data.user.displayName ?? '', {
        httpOnly: false,
        sameSite: 'lax',
        secure: process.env.NODE_ENV === 'production',
        path: '/',
        maxAge: SESSION_MAX_AGE_SECONDS,
    });

    // Only a known locale goes into the redirect: the value comes from the request, and
    // `/${'/evil.example'}/portal` would be a protocol-relative redirect off this site.
    redirect(`/${knownLocale(locale)}/portal`);
}

/**
 * Sign out: revoke the account's tokens, drop the cookie, land on the sign-in page. Unlike the
 * mobile app there is no FCM token to clear — a browser receives no push.
 *
 * SEC-REVIEW-003 F-05: deleting the cookie alone left a copied ID token working for the rest of
 * its hour. Revoking makes the portal functions refuse it at once (`checkRevoked`) and stops it
 * being refreshed. Firestore reads over REST do not check revocation, so those stay possible
 * until the token expires — bounded by the same hour, and by `admins/{uid}` on every read.
 * It signs this admin out of every browser, which is what "sign out" should mean for them.
 */
export async function signOutAction(formData: FormData) {
    const locale = formData.get('locale');
    const store = await cookies();
    const token = store.get(SESSION_COOKIE)?.value;
    if (token) {
        try {
            const { uid } = await serverAuth().verifyIdToken(token);
            await serverAuth().revokeRefreshTokens(uid);
        } catch (error) {
            // An expired or forged cookie has nothing to revoke; a failure to reach Auth must
            // not keep anyone signed in. Firebase's code only — never the token.
            const code = (error as { code?: unknown })?.code;
            if (code !== 'auth/id-token-expired' && code !== 'auth/argument-error')
                console.warn(`sign-out could not revoke tokens: ${String(code ?? error)}`);
        }
    }
    store.delete(SESSION_COOKIE);
    store.delete(`${SESSION_COOKIE}_name`);
    redirect(`/${knownLocale(locale)}/sign-in`);
}

function knownLocale(locale: unknown): Locale {
    return routing.locales.includes(locale as Locale) ? (locale as Locale) : routing.defaultLocale;
}
