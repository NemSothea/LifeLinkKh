'use server';

import { changePassword } from '@/lib/api/portal-auth';

/**
 * Every way this can fail, at a granularity the person can act on.
 *
 * Unlike sign-in, there is no enumeration risk here — the caller is already authenticated and the
 * account in question is their own — so "that is not your current password" is safe to say, and far
 * more useful than one generic message.
 */
export type ChangePasswordResult =
    | 'changed'
    | 'wrongCurrent'
    | 'tooShort'
    | 'mismatch'
    | 'unchanged'
    | 'failed';

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

    const result = await changePassword(current, next);
    if (result.ok) return 'changed';
    if (result.error === 'HTTP 401') return 'wrongCurrent';
    if (result.error === 'HTTP 422') return 'unchanged';
    return 'failed';
}
