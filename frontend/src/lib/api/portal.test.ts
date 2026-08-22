import { afterEach, describe, expect, it, vi } from 'vitest';
import { confirmDonation, listOpenRequests } from './portal';

afterEach(() => {
    vi.unstubAllGlobals();
    vi.unstubAllEnvs();
});

describe('listOpenRequests', () => {
    it('sends the dev JWT as a bearer credential', async () => {
        vi.stubEnv('PORTAL_DEV_JWT', 'dev-token');
        const fetchMock = vi
            .fn()
            .mockResolvedValue({ ok: true, status: 200, json: async () => [] });
        vi.stubGlobal('fetch', fetchMock);

        await listOpenRequests();

        const [url, init] = fetchMock.mock.calls[0];
        expect(url).toContain('/portal/requests?status=OPEN');
        expect(init.headers.Authorization).toBe('Bearer dev-token');
    });

    it('throws a clear error rather than calling the API with no token', () => {
        // authHeader() runs synchronously as an argument to apiGet — the throw happens
        // before any promise exists, so this is a sync throw, not a rejection.
        expect(() => listOpenRequests()).toThrow('PORTAL_DEV_JWT');
    });
});

describe('confirmDonation', () => {
    it('posts matchId and donatedOn to the request-scoped path', async () => {
        vi.stubEnv('PORTAL_DEV_JWT', 'dev-token');
        const fetchMock = vi
            .fn()
            .mockResolvedValue({ ok: true, status: 201, json: async () => ({}) });
        vi.stubGlobal('fetch', fetchMock);

        await confirmDonation('req-1', 'match-1', '2026-08-22');

        const [url, init] = fetchMock.mock.calls[0];
        expect(url).toContain('/portal/requests/req-1/confirm-donation');
        expect(init.method).toBe('POST');
        expect(JSON.parse(init.body)).toEqual({ matchId: 'match-1', donatedOn: '2026-08-22' });
        expect(init.headers.Authorization).toBe('Bearer dev-token');
    });

    it('a 409 (already confirmed) is a handled failure, not a thrown exception', async () => {
        vi.stubEnv('PORTAL_DEV_JWT', 'dev-token');
        vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 409 }));

        const result = await confirmDonation('req-1', 'match-1', '2026-08-22');

        expect(result).toEqual({ ok: false, error: 'HTTP 409' });
    });
});
