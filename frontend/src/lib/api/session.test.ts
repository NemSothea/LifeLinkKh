import { afterEach, describe, expect, it, vi } from 'vitest';

const cookieStore: Record<string, string> = {};
vi.mock('next/headers', () => ({
    cookies: async () => ({
        get: (name: string) =>
            cookieStore[name] === undefined ? undefined : { value: cookieStore[name] },
    }),
}));

const { hasPortalSession, portalAuthHeader, portalDisplayName, portalRole, SESSION_COOKIE } =
    await import('./session');

function fakeJwt(claims: Record<string, unknown>): string {
    const body = Buffer.from(JSON.stringify(claims)).toString('base64url');
    return `header.${body}.signature`;
}

afterEach(() => {
    for (const key of Object.keys(cookieStore)) delete cookieStore[key];
});

describe('portalAuthHeader', () => {
    it('sends the session cookie as a bearer credential', async () => {
        cookieStore[SESSION_COOKIE] = 'session-token';
        expect(await portalAuthHeader()).toEqual({ Authorization: 'Bearer session-token' });
    });

    // The pages redirect to /sign-in first, so reaching here without a session is a bug in
    // the caller — and it must fail loudly rather than quietly send an anonymous request.
    it('throws rather than calling the API unauthenticated', async () => {
        await expect(portalAuthHeader()).rejects.toThrow('No portal session');
    });
});

describe('portalRole', () => {
    it('is null when nobody is signed in', async () => {
        expect(await portalRole()).toBeNull();
        expect(await hasPortalSession()).toBe(false);
    });

    it('reads the role claim out of the session', async () => {
        cookieStore[SESSION_COOKIE] = fakeJwt({ sub: 'u1', role: 'ADMIN' });
        expect(await portalRole()).toBe('ADMIN');
        expect(await hasPortalSession()).toBe(true);
    });

    // Unverified on purpose — this only decides what renders. A cookie that is not a JWT is
    // a rendering question, never an authorization one, so it degrades instead of throwing.
    it('is null for a cookie that is not a JWT', async () => {
        cookieStore[SESSION_COOKIE] = 'not-a-jwt';
        expect(await portalRole()).toBeNull();
    });
});

describe('portalDisplayName', () => {
    it('comes from its own cookie, never from the session token', async () => {
        cookieStore[`${SESSION_COOKIE}_name`] = 'Soborey';
        expect(await portalDisplayName()).toBe('Soborey');
    });

    it('is null when absent', async () => {
        expect(await portalDisplayName()).toBeNull();
    });
});
