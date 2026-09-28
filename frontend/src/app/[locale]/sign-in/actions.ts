'use server';

import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { portalGoogleLogin, portalLogin, type PortalSession } from '@/lib/api/portal-auth';
import type { ApiResult } from '@/lib/api/client';
import { routing, type Locale } from '@/i18n/routing';
import { SESSION_COOKIE, SESSION_MAX_AGE_SECONDS } from '@/lib/api/session';

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

    return startSession(await portalLogin(username.trim(), password), locale);
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
    return startSession(await portalGoogleLogin(credential), locale);
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
 * Sign out. Unlike the mobile app there is no FCM token to clear — a browser receives no
 * push — so this is the whole of it: drop the cookie, land on the sign-in page.
 *
 * The ID token itself stays valid until it expires, bounded by the same one hour. Access does
 * not: the rules check `admins/{uid}` on every read, so a revoked account is refused at once.
 */
export async function signOutAction(formData: FormData) {
    const locale = formData.get('locale');
    const store = await cookies();
    store.delete(SESSION_COOKIE);
    store.delete(`${SESSION_COOKIE}_name`);
    redirect(`/${knownLocale(locale)}/sign-in`);
}

function knownLocale(locale: unknown): Locale {
    return routing.locales.includes(locale as Locale) ? (locale as Locale) : routing.defaultLocale;
}
