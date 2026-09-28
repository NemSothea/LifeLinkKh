import { afterEach, describe, expect, it, vi } from 'vitest';
import { fakeJwt } from '@/test/fake-firebase';
import { changePassword, portalEmail, portalGoogleLogin, portalLogin } from './portal-auth';

afterEach(() => vi.unstubAllGlobals());

const ok = (body: unknown) => ({ ok: true, status: 200, json: async () => body });
const failed = (message: string) => ({
    ok: false,
    status: 400,
    json: async () => ({ error: { message } }),
});

describe('portalLogin', () => {
    it("signs in with the username's portal email and keeps an admin token", async () => {
        const token = fakeJwt({ sub: 'u1', role: 'ADMIN' });
        const fetchMock = vi
            .fn()
            .mockResolvedValue(ok({ idToken: token, localId: 'u1', displayName: 'Soborey' }));
        vi.stubGlobal('fetch', fetchMock);

        const result = await portalLogin('Soborey', 'correct-horse-battery');

        expect(result).toEqual({
            ok: true,
            data: { token, user: { id: 'u1', role: 'ADMIN', displayName: 'Soborey' } },
        });
        const [url, init] = fetchMock.mock.calls[0];
        expect(url).toContain('accounts:signInWithPassword');
        expect(JSON.parse(init.body)).toMatchObject({
            email: 'soborey@portal.lifelink.invalid',
            returnSecureToken: true,
        });
    });

    it('a correct password without the ADMIN claim is not a session', async () => {
        vi.stubGlobal(
            'fetch',
            vi.fn().mockResolvedValue(ok({ idToken: fakeJwt({ sub: 'u1' }), localId: 'u1' })),
        );
        expect(await portalLogin('former', 'correct-horse-battery')).toEqual({
            ok: false,
            error: 'NOT_ADMIN',
        });
    });

    // v1 has no hospital staff: an old HOSPITAL claim does not open the portal.
    it('a HOSPITAL claim is not a session either', async () => {
        const token = fakeJwt({ sub: 'u1', role: 'HOSPITAL', hospitalId: 'calmette' });
        vi.stubGlobal('fetch', vi.fn().mockResolvedValue(ok({ idToken: token, localId: 'u1' })));
        expect(await portalLogin('calmette', 'correct-horse-battery')).toEqual({
            ok: false,
            error: 'NOT_ADMIN',
        });
    });

    it("passes Firebase Auth's code through for the action to classify", async () => {
        vi.stubGlobal('fetch', vi.fn().mockResolvedValue(failed('INVALID_LOGIN_CREDENTIALS')));
        expect(await portalLogin('soborey', 'wrong')).toEqual({
            ok: false,
            error: 'INVALID_LOGIN_CREDENTIALS',
        });
    });

    it("matches the Functions' mapping", () => {
        expect(portalEmail('soborey')).toBe('soborey@portal.lifelink.invalid');
    });
});

describe('changePassword', () => {
    it('proves the current password first, then updates with the fresh token', async () => {
        const fresh = fakeJwt({ sub: 'u1', role: 'ADMIN' });
        const fetchMock = vi
            .fn()
            .mockResolvedValueOnce(ok({ idToken: fresh, localId: 'u1' }))
            .mockResolvedValueOnce(ok({ idToken: 'after-change' }));
        vi.stubGlobal('fetch', fetchMock);

        expect(await changePassword('soborey', 'old-password', 'new-password')).toEqual({
            ok: true,
            data: { token: 'after-change' },
        });
        const [url, init] = fetchMock.mock.calls[1];
        expect(url).toContain('accounts:update');
        expect(JSON.parse(init.body)).toMatchObject({ idToken: fresh, password: 'new-password' });
    });

    it('a wrong current password changes nothing', async () => {
        const fetchMock = vi.fn().mockResolvedValue(failed('INVALID_LOGIN_CREDENTIALS'));
        vi.stubGlobal('fetch', fetchMock);

        expect(await changePassword('soborey', 'wrong', 'new-password')).toEqual({
            ok: false,
            error: 'INVALID_LOGIN_CREDENTIALS',
        });
        expect(fetchMock).toHaveBeenCalledTimes(1);
    });
});

describe('portalGoogleLogin', () => {
    it('trades the Google ID token with signInWithIdp and keeps an admin token', async () => {
        const token = fakeJwt({ sub: 'g1', role: 'ADMIN', name: 'Nem Sothea' });
        const fetchMock = vi.fn().mockResolvedValue(ok({ idToken: token, localId: 'g1' }));
        vi.stubGlobal('fetch', fetchMock);

        expect(await portalGoogleLogin('google-id-token')).toEqual({
            ok: true,
            data: { token, user: { id: 'g1', role: 'ADMIN', displayName: 'Nem Sothea' } },
        });
        const [url, init] = fetchMock.mock.calls[0];
        expect(url).toContain('accounts:signInWithIdp');
        expect(JSON.parse(init.body)).toMatchObject({
            postBody: 'id_token=google-id-token&providerId=google.com',
            returnSecureToken: true,
        });
    });

    // Any Google account can complete the exchange; a donor's is not a portal session.
    it('a Google account without the ADMIN claim is not a session', async () => {
        vi.stubGlobal(
            'fetch',
            vi.fn().mockResolvedValue(ok({ idToken: fakeJwt({ sub: 'g2' }), localId: 'g2' })),
        );
        expect(await portalGoogleLogin('google-id-token')).toEqual({
            ok: false,
            error: 'NOT_ADMIN',
        });
    });

    it('a reply with no Firebase token is not a session', async () => {
        vi.stubGlobal('fetch', vi.fn().mockResolvedValue(ok({ needConfirmation: true })));
        expect(await portalGoogleLogin('google-id-token')).toEqual({
            ok: false,
            error: 'NOT_ADMIN',
        });
    });
});
