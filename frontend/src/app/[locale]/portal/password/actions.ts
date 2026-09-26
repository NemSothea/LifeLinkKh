'use server';

import { cookies } from 'next/headers';
import { changePassword } from '@/lib/api/portal-auth';
import { portalUsername, SESSION_COOKIE, SESSION_MAX_AGE_SECONDS } from '@/lib/api/session';

/**
 * Every way this can fail, at a granularity the person can act on.
 *
 * Unlike sign-in, there is no enumeration risk here — the caller is already authenticated and the
 * account in question is their own — so "that is not your current password" is safe to say, and far
 * more useful than one generic message.
 */
export type ChangePasswordResult =
    'changed' | 'wrongCurrent' | 'tooShort' | 'mismatch' | 'unchanged' | 'failed';

export async function changePasswordAction(
    _previous: ChangePasswordResult | null | undefined,
    formData: FormData,
): Promise<ChangePasswordResult> {
    const current = formData.get('currentPassword');
    const next = formData.get('newPassword');
    const confirm = formData.get('confirmPassword');

    if (typeof current !== 'string' || typeof next !== 'string' || typeof confirm !== 'string') {
        return 'failed';
    }
    // Checked here rather than only server-side: a mistyped confirmation is the most common way
    // this goes wrong, and it needs no round trip to catch.
    if (next !== confirm) return 'mismatch';
    if (next.length < 8) return 'tooShort';

    if (next === current) return 'unchanged';

    const username = await portalUsername();
    if (!username) return 'failed';
    const result = await changePassword(username, current, next);
    if (!result.ok) {
        if (result.error === 'INVALID_LOGIN_CREDENTIALS' || result.error === 'INVALID_PASSWORD') {
            return 'wrongCurrent';
        }
        if (result.error === 'WEAK_PASSWORD') return 'tooShort';
        return 'failed';
    }

    // Changing the password ends the old session, so the fresh token replaces it — otherwise the
    // next page would be refused and send them to sign in straight after succeeding.
    (await cookies()).set(SESSION_COOKIE, result.data.token, {
        httpOnly: true,
        sameSite: 'lax',
        secure: process.env.NODE_ENV === 'production',
        path: '/',
        maxAge: SESSION_MAX_AGE_SECONDS,
    });
    return 'changed';
}
