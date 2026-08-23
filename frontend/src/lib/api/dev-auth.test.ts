import { afterEach, describe, expect, it, vi } from 'vitest';
import { portalAuthHeader, portalRole } from './dev-auth';

function fakeJwt(payload: object): string {
    const header = Buffer.from(JSON.stringify({ alg: 'HS256' })).toString('base64url');
    const body = Buffer.from(JSON.stringify(payload)).toString('base64url');
    return `${header}.${body}.signature`;
}

afterEach(() => {
    vi.unstubAllEnvs();
});

describe('portalAuthHeader', () => {
    it('throws a clear error with no token set', () => {
        expect(() => portalAuthHeader()).toThrow('PORTAL_DEV_JWT');
    });

    it('returns a bearer header', () => {
        vi.stubEnv('PORTAL_DEV_JWT', 'dev-token');
        expect(portalAuthHeader()).toEqual({ Authorization: 'Bearer dev-token' });
    });
});

describe('portalRole', () => {
    it('returns null with no token set', () => {
        expect(portalRole()).toBeNull();
    });

    it('reads the role claim out of the token', () => {
        vi.stubEnv('PORTAL_DEV_JWT', fakeJwt({ sub: 'u1', role: 'ADMIN' }));
        expect(portalRole()).toBe('ADMIN');
    });

    it('returns null for a malformed token rather than throwing', () => {
        vi.stubEnv('PORTAL_DEV_JWT', 'not-a-jwt');
        expect(portalRole()).toBeNull();
    });
});
