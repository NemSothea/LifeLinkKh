import { afterEach, describe, expect, it, vi } from 'vitest';
import { boardId } from '@/server/board-id.js';
import { fakeFirebase, fakeJwt } from '@/test/fake-firebase';
import { HttpsError } from '@/server/https-error.js';

// The functions run on this server (ADR 0010); here they are a mock, so no Admin SDK loads.
const invokeMock = vi.hoisted(() => vi.fn());
vi.mock('@/server/invoke', () => ({ invoke: invokeMock }));
import { clearReferenceDataCache } from './reference-data';

// The session lives in an httpOnly cookie. `next/headers` only exists inside a request, so it is
// stubbed here — these tests are about what the portal asks Firebase, and as whom.
const cookieStore = { value: null as string | null };
vi.mock('next/headers', () => ({
    cookies: async () => ({
        get: () => (cookieStore.value === null ? undefined : { value: cookieStore.value }),
    }),
}));
import {
    confirmDonation,
    listFulfilledRequests,
    listOpenRequests,
    listPendingRequests,
    listReports,
    reviewRequest,
} from './portal';

const admin = fakeJwt({ sub: 'admin-1', role: 'ADMIN' });

const request = (id: string, overrides: Record<string, unknown> = {}) => ({
    id,
    fields: {
        hospitalId: 'calmette',
        hospital: { name: 'Calmette Hospital', districtCode: '1202' },
        patientBloodType: 'AB+',
        unitsNeeded: 2,
        urgency: 'CRITICAL',
        status: 'OPEN',
        alertedCount: 3,
        acceptedCount: 2,
        createdAt: '2026-09-26T03:00:00Z',
        ...overrides,
    },
});

const tables = {
    requests: [request('r1'), request('r2', { hospitalId: 'khmer-soviet' })],
    'requests/r1/acceptedDonors': [
        {
            id: 'd2',
            fields: {
                displayName: 'Sok Dara',
                bloodType: 'O+',
                districtCode: '1201',
                respondedAt: '2026-09-26T03:20:00Z',
            },
        },
        {
            id: 'd1',
            fields: {
                // Shortened on the public board; the admin gets the profile's full name.
                displayName: 'Nem S.',
                bloodType: 'A+',
                districtCode: '1202',
                respondedAt: '2026-09-26T03:10:00Z',
            },
        },
    ],
    // Who answered, which only the admin reads: the board row's id is not the uid (F-11).
    matches: [
        { id: 'r1_d1', fields: { requestId: 'r1', donorUid: 'd1', response: 'ACCEPTED' } },
        { id: 'r1_d2', fields: { requestId: 'r1', donorUid: 'd2', response: 'ACCEPTED' } },
    ],
    donations: [
        { id: 'r1_d2', fields: { donorUid: 'd2', hospitalId: 'calmette', requestId: 'r1' } },
    ],
    donors: [{ id: 'd1', fields: { fullName: 'Nem Sothea', bloodType: 'A+' } }],
    districts: [
        { id: '1201', fields: { nameKm: 'ចំការមន', nameEn: 'Chamkar Mon' } },
        { id: '1202', fields: { nameKm: 'ដូនពេញ', nameEn: 'Doun Penh' } },
    ],
};

afterEach(() => {
    vi.unstubAllGlobals();
    clearReferenceDataCache();
    cookieStore.value = null;
    invokeMock.mockReset();
});

describe('listOpenRequests', () => {
    it('reads as the signed-in admin, across every hospital', async () => {
        cookieStore.value = admin;
        const calls = fakeFirebase(tables);

        const result = await listOpenRequests();

        expect(result.ok && result.data.map((r) => r.id)).toEqual(['r1', 'r2']);
        const requestsQuery = calls.find(
            (c) => c.body?.structuredQuery?.from[0].collectionId === 'requests',
        );
        expect(requestsQuery?.token).toBe(admin);
    });

    it('gives each donor the match id, in answer order, and drops donors already confirmed', async () => {
        cookieStore.value = admin;
        fakeFirebase(tables);

        const result = await listOpenRequests();

        expect(result.ok && result.data[0]).toMatchObject({
            patientBloodType: 'AB+',
            hospital: { id: 'calmette', name: 'Calmette Hospital' },
            acceptedCount: 2,
            acceptedDonors: [
                {
                    matchId: 'r1_d1',
                    displayName: 'Nem Sothea',
                    bloodType: 'A+',
                    districtName: { km: 'ដូនពេញ', en: 'Doun Penh' },
                    respondedAt: '2026-09-26T03:10:00Z',
                },
            ],
        });
    });

    it("asks for one request's donations, as the admin", async () => {
        cookieStore.value = admin;
        const calls = fakeFirebase(tables);

        await listOpenRequests();

        const donations = calls.find(
            (c) => c.body?.structuredQuery?.from[0].collectionId === 'donations',
        );
        expect(donations?.token).toBe(admin);
        expect(JSON.stringify(donations?.body.structuredQuery.where)).toContain('"requestId"');
    });

    it('resolves a board row keyed by its opaque id to the donor who answered (F-11)', async () => {
        cookieStore.value = admin;
        const d1Row = tables['requests/r1/acceptedDonors'][1];
        fakeFirebase({
            ...tables,
            'requests/r1/acceptedDonors': [{ ...d1Row, id: boardId('r1', 'd1') }],
        });

        const result = await listOpenRequests();

        expect(result.ok && result.data[0].acceptedDonors).toMatchObject([
            { matchId: 'r1_d1', displayName: 'Nem Sothea' },
        ]);
    });

    it("falls back to the board's shortened name when the profile is gone", async () => {
        cookieStore.value = admin;
        fakeFirebase({ ...tables, donors: [] });

        const result = await listOpenRequests();

        expect(result.ok && result.data[0].acceptedDonors[0].displayName).toBe('Nem S.');
    });

    it('refuses to read with no session rather than reading as a visitor', async () => {
        await expect(listOpenRequests()).rejects.toThrow('No portal session');
    });
});

describe('listFulfilledRequests', () => {
    it('asks for FULFILLED, and reads no donors for rows that render none', async () => {
        cookieStore.value = admin;
        const calls = fakeFirebase({
            ...tables,
            requests: [request('r3', { status: 'FULFILLED' })],
        });

        const result = await listFulfilledRequests();

        expect(result.ok && result.data.map((r) => r.id)).toEqual(['r3']);
        expect(calls.some((c) => c.url.includes('acceptedDonors'))).toBe(false);
    });
});

describe('confirmDonation', () => {
    it('runs the confirmDonation function as the admin', async () => {
        cookieStore.value = admin;
        invokeMock.mockResolvedValue({ ok: true, result: { id: 'r1_d1' } });

        const result = await confirmDonation('r1', 'r1_d1', '2026-09-25');

        expect(result).toEqual({ ok: true, data: { id: 'r1_d1' } });
        expect(invokeMock).toHaveBeenCalledWith(
            'confirmDonation',
            { requestId: 'r1', matchId: 'r1_d1', donatedOn: '2026-09-25' },
            admin,
        );
    });

    it('an already-confirmed donation is a handled failure, not a thrown exception', async () => {
        cookieStore.value = admin;
        invokeMock.mockResolvedValue({
            ok: false,
            error: new HttpsError('already-exists', 'already confirmed'),
        });

        expect(await confirmDonation('r1', 'r1_d1', '2026-09-25')).toEqual({
            ok: false,
            error: 'already-exists',
        });
    });
});

describe('reviewRequest', () => {
    it('sends APPROVE with no reason', async () => {
        cookieStore.value = admin;
        invokeMock.mockResolvedValue({ ok: true, result: { status: 'OPEN' } });

        await reviewRequest('p1', 'APPROVE');

        expect(invokeMock).toHaveBeenCalledWith(
            'reviewRequest',
            { requestId: 'p1', decision: 'APPROVE' },
            admin,
        );
    });

    it('sends REJECT with its reason', async () => {
        cookieStore.value = admin;
        invokeMock.mockResolvedValue({ ok: true, result: { status: 'REJECTED' } });

        await reviewRequest('p1', 'REJECT', 'No such patient');

        expect(invokeMock.mock.calls[0][1]).toEqual({
            requestId: 'p1',
            decision: 'REJECT',
            reason: 'No such patient',
        });
    });
});

describe('listPendingRequests (DEC-015)', () => {
    const pendingTables = {
        requests: [
            request('p1', {
                status: 'PENDING',
                urgency: 'ROUTINE',
                createdAt: '2026-09-26T01:00:00Z',
            }),
            request('p2', {
                status: 'PENDING',
                urgency: 'CRITICAL',
                createdAt: '2026-09-26T03:00:00Z',
            }),
            request('p3', {
                status: 'PENDING',
                urgency: 'CRITICAL',
                createdAt: '2026-09-26T02:00:00Z',
            }),
            request('r1'),
        ],
        'requests/p2/private': [
            { id: 'contact', fields: { contactName: 'Chea Srey', contactPhone: '+85512345678' } },
        ],
    };

    it('lists only PENDING, most urgent then oldest first, as the admin', async () => {
        cookieStore.value = admin;
        const calls = fakeFirebase(pendingTables);

        const result = await listPendingRequests();

        expect(result.ok && result.data.map((r) => r.id)).toEqual(['p3', 'p2', 'p1']);
        expect(calls.every((c) => c.token === admin)).toBe(true);
    });

    it("carries the requester's contact, and null when there is none", async () => {
        cookieStore.value = admin;
        fakeFirebase(pendingTables);

        const result = await listPendingRequests();
        const byId = new Map(result.ok ? result.data.map((r) => [r.id, r]) : []);

        expect(byId.get('p2')).toMatchObject({
            contactName: 'Chea Srey',
            contactPhone: '+85512345678',
        });
        expect(byId.get('p1')).toMatchObject({ contactName: null, contactPhone: null });
    });
});

describe('listReports (DEC-019)', () => {
    const reportTables = {
        requests: [request('r1')],
        reports: [
            {
                id: 'r1_d1',
                fields: {
                    requestId: 'r1',
                    reporterUid: 'd1',
                    reason: 'MONEY',
                    note: 'Asked me for $50',
                    createdAt: '2026-09-26T04:00:00Z',
                },
            },
            {
                id: 'gone_d2',
                fields: {
                    requestId: 'gone',
                    reporterUid: 'd2',
                    reason: 'FAKE',
                    note: null,
                    createdAt: '2026-09-26T03:00:00Z',
                },
            },
        ],
    };

    it('reads reports as the admin, with the request they are about, and never the reporter', async () => {
        cookieStore.value = admin;
        const calls = fakeFirebase(reportTables);

        const result = await listReports();

        expect(result.ok).toBe(true);
        const byId = new Map(result.ok ? result.data.map((r) => [r.id, r]) : []);
        expect(byId.get('r1_d1')).toEqual({
            id: 'r1_d1',
            requestId: 'r1',
            reason: 'MONEY',
            note: 'Asked me for $50',
            createdAt: '2026-09-26T04:00:00Z',
            request: { patientBloodType: 'AB+', hospitalName: 'Calmette Hospital', status: 'OPEN' },
        });
        expect(byId.get('gone_d2')?.request).toBeNull();
        expect(JSON.stringify(result)).not.toContain('reporterUid');
        expect(calls.every((c) => c.token === admin)).toBe(true);
    });
});
