import { afterEach, describe, expect, it, vi } from 'vitest';

// The API modules read the session from an httpOnly cookie now, not from PORTAL_DEV_JWT.
// `next/headers` only exists inside a request, so it is stubbed here — these tests are
// about what the API module sends, not about how Next stores a cookie.
const cookieStore = { value: 'session-token' as string | null };
vi.mock('next/headers', () => ({
    cookies: async () => ({
        get: () => (cookieStore.value === null ? undefined : { value: cookieStore.value }),
    }),
}));
import { assignStaffRole, listCandidates, listStaff } from './admin';

afterEach(() => {
    vi.unstubAllGlobals();
    vi.unstubAllEnvs();
    cookieStore.value = 'session-token';
});

describe('listCandidates', () => {
    it('sends the dev JWT as a bearer credential', async () => {
        cookieStore.value = 'session-token';
        const fetchMock = vi
            .fn()
            .mockResolvedValue({ ok: true, status: 200, json: async () => [] });
        vi.stubGlobal('fetch', fetchMock);

        await listCandidates();

        const [url, init] = fetchMock.mock.calls[0];
        expect(url).toContain('/admin/users');
        expect(init.headers.Authorization).toBe('Bearer session-token');
    });
});

describe('listStaff', () => {
    it('reads /admin/staff', async () => {
        cookieStore.value = 'session-token';
        const fetchMock = vi
            .fn()
            .mockResolvedValue({ ok: true, status: 200, json: async () => [] });
        vi.stubGlobal('fetch', fetchMock);

        await listStaff();

        expect(fetchMock.mock.calls[0][0]).toContain('/admin/staff');
    });
});

describe('assignStaffRole', () => {
    it('posts userId, role and hospitalId', async () => {
        cookieStore.value = 'session-token';
        const fetchMock = vi
            .fn()
            .mockResolvedValue({ ok: true, status: 200, json: async () => ({}) });
        vi.stubGlobal('fetch', fetchMock);

        await assignStaffRole('user-1', 'HOSPITAL', 'hospital-1');

        const [url, init] = fetchMock.mock.calls[0];
        expect(url).toContain('/admin/staff');
        expect(init.method).toBe('POST');
        expect(JSON.parse(init.body)).toEqual({
            userId: 'user-1',
            role: 'HOSPITAL',
            hospitalId: 'hospital-1',
        });
    });

    it('sends hospitalId as null for ADMIN', async () => {
        cookieStore.value = 'session-token';
        const fetchMock = vi
            .fn()
            .mockResolvedValue({ ok: true, status: 200, json: async () => ({}) });
        vi.stubGlobal('fetch', fetchMock);

        await assignStaffRole('user-1', 'ADMIN', null);

        const [, init] = fetchMock.mock.calls[0];
        expect(JSON.parse(init.body).hospitalId).toBeNull();
    });
});
