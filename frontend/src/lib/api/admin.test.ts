import { afterEach, describe, expect, it, vi } from 'vitest';
import { assignStaffRole, listCandidates, listStaff } from './admin';

afterEach(() => {
    vi.unstubAllGlobals();
    vi.unstubAllEnvs();
});

describe('listCandidates', () => {
    it('sends the dev JWT as a bearer credential', async () => {
        vi.stubEnv('PORTAL_DEV_JWT', 'dev-token');
        const fetchMock = vi
            .fn()
            .mockResolvedValue({ ok: true, status: 200, json: async () => [] });
        vi.stubGlobal('fetch', fetchMock);

        await listCandidates();

        const [url, init] = fetchMock.mock.calls[0];
        expect(url).toContain('/admin/users');
        expect(init.headers.Authorization).toBe('Bearer dev-token');
    });
});

describe('listStaff', () => {
    it('reads /admin/staff', async () => {
        vi.stubEnv('PORTAL_DEV_JWT', 'dev-token');
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
        vi.stubEnv('PORTAL_DEV_JWT', 'dev-token');
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
        vi.stubEnv('PORTAL_DEV_JWT', 'dev-token');
        const fetchMock = vi
            .fn()
            .mockResolvedValue({ ok: true, status: 200, json: async () => ({}) });
        vi.stubGlobal('fetch', fetchMock);

        await assignStaffRole('user-1', 'ADMIN', null);

        const [, init] = fetchMock.mock.calls[0];
        expect(JSON.parse(init.body).hospitalId).toBeNull();
    });
});
