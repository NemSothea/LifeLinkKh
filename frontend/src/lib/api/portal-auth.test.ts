import { afterEach, describe, expect, it, vi } from 'vitest';
import { fakeJwt } from '@/test/fake-firebase';
import { changePassword, portalEmail, portalLogin } from './portal-auth';

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
