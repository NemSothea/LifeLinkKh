import { afterEach, describe, expect, it, vi } from 'vitest';
import { fakeFirebase, fakeJwt } from '@/test/fake-firebase';

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
                displayName: 'Nem Sothea',
                bloodType: 'A+',
                districtCode: '1202',
                respondedAt: '2026-09-26T03:10:00Z',
            },
        },
    ],
    donations: [
        { id: 'r1_d2', fields: { donorUid: 'd2', hospitalId: 'calmette', requestId: 'r1' } },
    ],
    districts: [
        { id: '1201', fields: { nameKm: 'ចំការមន', nameEn: 'Chamkar Mon' } },
        { id: '1202', fields: { nameKm: 'ដូនពេញ', nameEn: 'Doun Penh' } },
    ],
};

afterEach(() => {
    vi.unstubAllGlobals();
    cookieStore.value = null;
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
    it('calls the confirmDonation Function as the admin', async () => {
        cookieStore.value = admin;
        const calls = fakeFirebase({}, { confirmDonation: { body: { result: { id: 'r1_d1' } } } });

        await confirmDonation('r1', 'r1_d1', '2026-09-25');

        expect(calls[0].body).toEqual({
            data: { requestId: 'r1', matchId: 'r1_d1', donatedOn: '2026-09-25' },
        });
        expect(calls[0].token).toBe(admin);
    });

    it('an already-confirmed donation is a handled failure, not a thrown exception', async () => {
        cookieStore.value = admin;
        fakeFirebase(
            {},
            { confirmDonation: { status: 409, body: { error: { status: 'ALREADY_EXISTS' } } } },
        );

        expect(await confirmDonation('r1', 'r1_d1', '2026-09-25')).toEqual({
            ok: false,
            error: 'already-exists',
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

describe('reviewRequest', () => {
    it('sends APPROVE with no reason', async () => {
        cookieStore.value = admin;
        const calls = fakeFirebase({}, { reviewRequest: { body: { result: { status: 'OPEN' } } } });

        await reviewRequest('p1', 'APPROVE');

        expect(calls[0].body).toEqual({ data: { requestId: 'p1', decision: 'APPROVE' } });
    });

    it('sends REJECT with its reason', async () => {
        cookieStore.value = admin;
        const calls = fakeFirebase(
            {},
            { reviewRequest: { body: { result: { status: 'REJECTED' } } } },
        );

        await reviewRequest('p1', 'REJECT', 'No such patient');

        expect(calls[0].body.data).toEqual({
            requestId: 'p1',
            decision: 'REJECT',
            reason: 'No such patient',
        });
    });
});
