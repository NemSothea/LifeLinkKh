import { afterEach, describe, expect, it, vi } from 'vitest';
import { HttpsError } from '@/server/https-error.js';
import { callFunction, decodeValue, firestoreGet, firestoreQuery, identityToolkit } from './client';

// The functions run on this server (ADR 0010); here they are a mock, so no Admin SDK loads.
const invokeMock = vi.hoisted(() => vi.fn());
vi.mock('@/server/invoke', () => ({ invoke: invokeMock }));

afterEach(() => {
    vi.unstubAllGlobals();
    vi.unstubAllEnvs();
    invokeMock.mockReset();
});

const ok = (body: unknown) => ({ ok: true, status: 200, json: async () => body });
const failed = (status: number, body: unknown) => ({ ok: false, status, json: async () => body });

describe('decodeValue', () => {
    it('turns Firestore REST values into plain JSON', () => {
        expect(
            decodeValue({
                mapValue: {
                    fields: {
                        name: { stringValue: 'Calmette Hospital' },
                        units: { integerValue: '2' },
                        km: { doubleValue: 2.5 },
                        open: { booleanValue: true },
                        at: { timestampValue: '2026-09-26T03:00:00Z' },
                        none: { nullValue: null },
                        list: { arrayValue: { values: [{ stringValue: 'a' }] } },
                    },
                },
            }),
        ).toEqual({
            name: 'Calmette Hospital',
            units: 2,
            km: 2.5,
            open: true,
            at: '2026-09-26T03:00:00Z',
            none: null,
            list: ['a'],
        });
    });
});

describe('firestoreQuery', () => {
    it('sends the admin token as the bearer, so the rules judge the admin', async () => {
        const fetchMock = vi.fn().mockResolvedValue(ok([]));
        vi.stubGlobal('fetch', fetchMock);

        await firestoreQuery({ collection: 'donations' }, 'id-token');

        const [url, init] = fetchMock.mock.calls[0];
        expect(url).toContain('/projects/lifelinkkh/databases/(default)/documents:runQuery');
        expect(init.headers.Authorization).toBe('Bearer id-token');
    });

    it('sends no credential at all for a public read', async () => {
        const fetchMock = vi.fn().mockResolvedValue(ok([]));
        vi.stubGlobal('fetch', fetchMock);

        await firestoreQuery({ collection: 'requests' }, null);

        expect(fetchMock.mock.calls[0][1].headers.Authorization).toBeUndefined();
    });

    it('builds equality filters, ordering and a subcollection parent', async () => {
        const fetchMock = vi.fn().mockResolvedValue(ok([]));
        vi.stubGlobal('fetch', fetchMock);

        await firestoreQuery(
            {
                parent: 'requests/r1',
                collection: 'acceptedDonors',
                where: { hospitalId: 'h1', status: 'OPEN' },
                orderBy: { field: 'createdAt', direction: 'DESCENDING' },
            },
            null,
        );

        const [url, init] = fetchMock.mock.calls[0];
        expect(url).toMatch(/documents\/requests\/r1:runQuery$/);
        expect(JSON.parse(init.body).structuredQuery).toEqual({
            from: [{ collectionId: 'acceptedDonors' }],
            where: {
                compositeFilter: {
                    op: 'AND',
                    filters: [
                        {
                            fieldFilter: {
                                field: { fieldPath: 'hospitalId' },
                                op: 'EQUAL',
                                value: { stringValue: 'h1' },
                            },
                        },
                        {
                            fieldFilter: {
                                field: { fieldPath: 'status' },
                                op: 'EQUAL',
                                value: { stringValue: 'OPEN' },
                            },
                        },
                    ],
                },
            },
            orderBy: [{ field: { fieldPath: 'createdAt' }, direction: 'DESCENDING' }],
        });
    });

    it('returns documents by id and skips the rows that carry none', async () => {
        vi.stubGlobal(
            'fetch',
            vi.fn().mockResolvedValue(
                ok([
                    {
                        document: {
                            name: 'projects/p/databases/(default)/documents/hospitals/h1',
                            fields: { name: { stringValue: 'A' } },
                        },
                    },
                    { readTime: '2026-09-26T00:00:00Z' },
                ]),
            ),
        );

        expect(await firestoreQuery({ collection: 'hospitals' }, null)).toEqual({
            ok: true,
            data: [{ id: 'h1', data: { name: 'A' } }],
        });
    });

    it('goes to the emulator when FIRESTORE_EMULATOR_HOST is set', async () => {
        vi.stubEnv('FIRESTORE_EMULATOR_HOST', '127.0.0.1:8081');
        const fetchMock = vi.fn().mockResolvedValue(ok([]));
        vi.stubGlobal('fetch', fetchMock);

        await firestoreQuery({ collection: 'districts' }, null);

        expect(fetchMock.mock.calls[0][0]).toMatch(/^http:\/\/127\.0\.0\.1:8081\/v1\/projects\//);
    });

    /**
     * A network failure must never surface the underlying cause: an error rendered in a page
     * must not describe the server (docs/security/asvs-baseline.md, error-handling control).
     */
    it('swallows the cause when the request throws', async () => {
        vi.stubGlobal(
            'fetch',
            vi.fn().mockRejectedValue(new Error('connect ECONNREFUSED 10.0.0.5:8081')),
        );

        const result = await firestoreQuery({ collection: 'districts' }, null);

        expect(result).toEqual({ ok: false, error: 'unreachable' });
        expect(JSON.stringify(result)).not.toContain('10.0.0.5');
    });

    it('a refusal by the rules is a failure, not an empty list', async () => {
        vi.stubGlobal(
            'fetch',
            vi.fn().mockResolvedValue(failed(403, { error: { status: 'PERMISSION_DENIED' } })),
        );
        expect(await firestoreQuery({ collection: 'donations' }, 'id-token')).toEqual({
            ok: false,
            error: 'HTTP 403',
        });
    });
});

describe('firestoreGet', () => {
    it('a missing document is null, not an error', async () => {
        vi.stubGlobal('fetch', vi.fn().mockResolvedValue(failed(404, {})));
        expect(await firestoreGet('requests/nobody', 'id-token')).toEqual({ ok: true, data: null });
    });
});

describe('callFunction', () => {
    it('runs the function in-process as the bearer and unwraps its result', async () => {
        invokeMock.mockResolvedValue({ ok: true, result: { id: 'd1' } });

        expect(await callFunction('confirmDonation', { requestId: 'r1' }, 'id-token')).toEqual({
            ok: true,
            data: { id: 'd1' },
        });
        expect(invokeMock).toHaveBeenCalledWith('confirmDonation', { requestId: 'r1' }, 'id-token');
    });

    it("reports the HttpsError code in the Functions' spelling, and drops the message", async () => {
        invokeMock.mockResolvedValue({
            ok: false,
            error: new HttpsError('already-exists', 'That username is already in use.'),
        });

        expect(await callFunction('confirmDonation', {}, 'id-token')).toEqual({
            ok: false,
            error: 'already-exists',
        });
    });
});

describe('identityToolkit', () => {
    it("reports Firebase Auth's own error code, without the text after it", async () => {
        vi.stubGlobal(
            'fetch',
            vi.fn().mockResolvedValue(
                failed(400, {
                    error: {
                        message: 'TOO_MANY_ATTEMPTS_TRY_LATER : Access disabled temporarily.',
                    },
                }),
            ),
        );

        expect(await identityToolkit('signInWithPassword', {})).toEqual({
            ok: false,
            error: 'TOO_MANY_ATTEMPTS_TRY_LATER',
        });
    });
});
