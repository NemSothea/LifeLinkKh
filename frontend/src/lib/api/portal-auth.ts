import { apiPost, type ApiResult } from './client';

/**
 * `POST /auth/portal/login` — the one endpoint in this app that takes a password.
 *
 * Called only from a Server Action, never from the browser: the response carries a session
 * JWT, and the whole point of the cookie in `session.ts` is that the token never exists in
 * page script.
 */
export type PortalSession = {
    token: string;
    user: { id: string; role: string; displayName: string | null; isNewAccount: boolean };
};

export function portalLogin(username: string, password: string): Promise<ApiResult<PortalSession>> {
    return apiPost<PortalSession>('/auth/portal/login', { username, password });
}

/** `POST /auth/portal/password` — a staff member changing their own password. */
export async function changePassword(
    currentPassword: string,
    newPassword: string,
): Promise<ApiResult<void>> {
    const { portalAuthHeader } = await import('./session');
    return apiPost<void>(
        '/auth/portal/password',
        { currentPassword, newPassword },
        await portalAuthHeader(),
    );
}
