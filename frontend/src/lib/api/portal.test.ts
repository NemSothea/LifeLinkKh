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
import { confirmDonation, listFulfilledRequests, listOpenRequests } from './portal';

afterEach(() => {
    vi.unstubAllGlobals();
    vi.unstubAllEnvs();
    cookieStore.value = 'session-token';
});

describe('listOpenRequests', () => {
    it('sends the dev JWT as a bearer credential', async () => {
        cookieStore.value = 'session-token';
        const fetchMock = vi
            .fn()
            .mockResolvedValue({ ok: true, status: 200, json: async () => [] });
        vi.stubGlobal('fetch', fetchMock);

        await listOpenRequests();

        const [url, init] = fetchMock.mock.calls[0];
        expect(url).toContain('/portal/requests?status=OPEN');
        expect(init.headers.Authorization).toBe('Bearer session-token');
    });

    it('refuses to call the API with no session rather than calling it unauthenticated', async () => {
        // Pages redirect to /sign-in before reaching here, so this state is a programming
        // error — but it must fail loudly rather than send an anonymous request that the
        // backend would answer with a 401 the page then renders as "could not load".
        cookieStore.value = null;
        await expect(listOpenRequests()).rejects.toThrow('No portal session');
    });
});

describe('listFulfilledRequests', () => {
    // The contract's `status` parameter takes one value, so the portal's "recently
    // fulfilled" section is a second call rather than a client-side filter — this is the
    // test that the second call actually asks for the other status.
    it('asks for FULFILLED, not OPEN', async () => {
        cookieStore.value = 'session-token';
        const fetchMock = vi
            .fn()
            .mockResolvedValue({ ok: true, status: 200, json: async () => [] });
        vi.stubGlobal('fetch', fetchMock);

        await listFulfilledRequests();

        const [url] = fetchMock.mock.calls[0];
        expect(url).toContain('/portal/requests?status=FULFILLED');
    });
});

describe('confirmDonation', () => {
    it('posts matchId and donatedOn to the request-scoped path', async () => {
        cookieStore.value = 'session-token';
        const fetchMock = vi
            .fn()
            .mockResolvedValue({ ok: true, status: 201, json: async () => ({}) });
        vi.stubGlobal('fetch', fetchMock);

        await confirmDonation('req-1', 'match-1', '2026-08-22');

        const [url, init] = fetchMock.mock.calls[0];
        expect(url).toContain('/portal/requests/req-1/confirm-donation');
        expect(init.method).toBe('POST');
        expect(JSON.parse(init.body)).toEqual({ matchId: 'match-1', donatedOn: '2026-08-22' });
        expect(init.headers.Authorization).toBe('Bearer session-token');
    });

    it('a 409 (already confirmed) is a handled failure, not a thrown exception', async () => {
        cookieStore.value = 'session-token';
        vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 409 }));

        const result = await confirmDonation('req-1', 'match-1', '2026-08-22');

        expect(result).toEqual({ ok: false, error: 'HTTP 409' });
    });
});
