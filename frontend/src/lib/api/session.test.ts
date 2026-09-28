import { afterEach, describe, expect, it, vi } from 'vitest';

const cookieStore: Record<string, string> = {};
vi.mock('next/headers', () => ({
    cookies: async () => ({
        get: (name: string) =>
            cookieStore[name] === undefined ? undefined : { value: cookieStore[name] },
    }),
}));

const {
    hasPortalSession,
    portalDisplayName,
    portalRole,
    portalHasPassword,
    portalUsername,
    requirePortalToken,
    SESSION_COOKIE,
} = await import('./session');

function fakeJwt(claims: Record<string, unknown>): string {
    const body = Buffer.from(JSON.stringify(claims)).toString('base64url');
    return `header.${body}.signature`;
}

afterEach(() => {
    for (const key of Object.keys(cookieStore)) delete cookieStore[key];
});

describe('requirePortalToken', () => {
    it('is the session cookie', async () => {
        cookieStore[SESSION_COOKIE] = 'session-token';
        expect(await requirePortalToken()).toBe('session-token');
    });

    // The pages redirect to /sign-in first, so reaching here without a session is a bug in
    // the caller — and it must fail loudly rather than quietly make the call signed out.
    it('throws rather than calling Firebase as a visitor', async () => {
        await expect(requirePortalToken()).rejects.toThrow('No portal session');
    });
});

describe('portalUsername', () => {
    it('is the username behind the portal email', async () => {
        cookieStore[SESSION_COOKIE] = fakeJwt({
            sub: 'u1',
            role: 'ADMIN',
            email: 'soborey@portal.lifelink.invalid',
        });
        expect(await portalUsername()).toBe('soborey');
    });

    it('is null for a Google admin, whose email is their own address', async () => {
        cookieStore[SESSION_COOKIE] = fakeJwt({
            sub: 'u2',
            role: 'ADMIN',
            email: 'someone@gmail.com',
        });
        expect(await portalUsername()).toBeNull();
    });
});

describe('portalHasPassword', () => {
    it('is true for a password session and false for a Google one', async () => {
        cookieStore[SESSION_COOKIE] = fakeJwt({
            sub: 'u1',
            firebase: { sign_in_provider: 'password' },
        });
        expect(await portalHasPassword()).toBe(true);
        cookieStore[SESSION_COOKIE] = fakeJwt({
            sub: 'u2',
            firebase: { sign_in_provider: 'google.com' },
        });
        expect(await portalHasPassword()).toBe(false);
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
