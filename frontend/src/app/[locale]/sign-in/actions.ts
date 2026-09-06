'use server';

import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { portalLogin } from '@/lib/api/portal-auth';
import { SESSION_COOKIE, SESSION_MAX_AGE_SECONDS } from '@/lib/api/session';

/**
 * Sign in, and put the session where page script cannot reach it.
 *
 * The password is read from the form on the server and forwarded to the backend from the
 * server. It is never a prop, never in a URL, never in a redirect, and never logged — the
 * only two places it exists are the POST body the browser sends over TLS and the one the
 * Next server makes to the API.
 */
/**
 * What went wrong, at the only granularity that is safe to show.
 *
 * `invalid` deliberately covers both "no such username" and "wrong password" — the backend
 * answers those identically on purpose, and a page that separated them would enumerate the
 * staff list from the outside. `rateLimited` and `unreachable` are a different class: they
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

    const result = await portalLogin(username.trim(), password);

    if (!result.ok) {
        if (result.error === 'unreachable') return 'unreachable';
        // 429 is the per-IP limiter in AuthController, not a rejected credential.
        if (result.error === 'HTTP 429') return 'rateLimited';
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

    redirect(`/${locale}/portal`);
}

/**
 * Sign out. Unlike the mobile app there is no FCM token to clear — a browser receives no
 * push — so this is the whole of it: drop the cookie, land on the sign-in page.
 *
 * The JWT itself stays valid until it expires; ADR 0007 has no server-side revocation. That
 * is the same trade the mobile client makes, bounded by the same one hour.
 */
export async function signOutAction(formData: FormData) {
    const locale = formData.get('locale');
    const store = await cookies();
    store.delete(SESSION_COOKIE);
    store.delete(`${SESSION_COOKIE}_name`);
    redirect(`/${typeof locale === 'string' ? locale : 'km'}/sign-in`);
}
