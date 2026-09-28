import { describe, expect, it } from 'vitest';
import type { Doc } from './client';
import { computeDashboard, resolveRange } from './dashboard';

const NOW = new Date('2026-09-28T09:00:00Z');
const doc = (id: string, data: Record<string, unknown>): Doc => ({ id, data });

describe('resolveRange', () => {
    it('defaults to the last 30 days, by day', () => {
        const r = resolveRange({}, NOW);
        expect(r.preset).toBe('30d');
        expect(r.bucket).toBe('day');
        expect(r.from.toISOString()).toBe('2026-08-30T00:00:00.000Z');
        expect(r.to.toISOString()).toBe('2026-09-29T00:00:00.000Z');
    });

    it('reads a year, by month', () => {
        const r = resolveRange({ year: '2026' }, NOW);
        expect(r).toMatchObject({ preset: 'year', bucket: 'month', year: 2026 });
        expect(r.to.toISOString()).toBe('2027-01-01T00:00:00.000Z');
    });

    it('takes a custom range with both ends inclusive', () => {
        const r = resolveRange({ from: '2026-09-01', to: '2026-09-10' }, NOW);
        expect(r.preset).toBe('custom');
        expect(r.to.toISOString()).toBe('2026-09-11T00:00:00.000Z');
    });

    it('ignores nonsense rather than failing', () => {
        expect(resolveRange({ from: '2026-09-10', to: '2026-09-01' }, NOW).preset).toBe('30d');
        expect(resolveRange({ year: '1999' }, NOW).preset).toBe('30d');
        expect(resolveRange({ range: 'forever' }, NOW).preset).toBe('30d');
    });
});

describe('computeDashboard', () => {
    const range = resolveRange({ range: '7d' }, NOW);
    const raw = {
        donors: [
            doc('d1', { bloodType: 'O-', districtCode: '1201', createdAt: '2026-09-27T01:00:00Z' }),
            doc('d2', { bloodType: 'O-', districtCode: '1201', createdAt: '2026-01-01T00:00:00Z', isAvailable: false }),
            doc('d3', { bloodType: 'AB+', districtCode: '1202', createdAt: '2026-09-26T00:00:00Z' }),
        ],
        requests: [
            // accepted after 20 minutes, fulfilled
            doc('r1', { status: 'FULFILLED', patientBloodType: 'AB+', hospital: { name: 'Calmette' }, createdAt: '2026-09-27T08:00:00Z', reviewedAt: '2026-09-27T08:10:00Z' }),
            // open, never accepted
            doc('r2', { status: 'OPEN', patientBloodType: 'O-', hospital: { name: 'Calmette' }, createdAt: '2026-09-28T02:00:00Z', reviewedAt: '2026-09-28T02:30:00Z' }),
            // rejected: excluded from the live metrics
            doc('r3', { status: 'REJECTED', patientBloodType: 'O-', hospital: { name: 'Khmer-Soviet' }, createdAt: '2026-09-28T03:00:00Z' }),
            // outside the range
            doc('r4', { status: 'OPEN', patientBloodType: 'O-', createdAt: '2026-08-01T00:00:00Z' }),
            doc('r5', { status: 'PENDING', patientBloodType: 'A+', hospital: { name: 'Calmette' }, createdAt: '2026-09-28T04:00:00Z' }),
        ],
        matches: [
            doc('r1_d3', { requestId: 'r1', response: 'ACCEPTED', respondedAt: '2026-09-27T08:20:00Z', notifiedAt: '2026-09-27T08:11:00Z' }),
            doc('r2_d1', { requestId: 'r2', response: null, notifiedAt: '2026-09-28T02:31:00Z' }),
            doc('r2_d2', { requestId: 'r2', response: null }),
            doc('r4_d1', { requestId: 'r4', response: 'ACCEPTED', respondedAt: '2026-08-01T00:05:00Z', notifiedAt: '2026-08-01T00:01:00Z' }),
        ],
        donations: [
            doc('x1', { confirmedBy: 'admin', donatedOn: '2026-09-27T00:00:00Z' }),
            doc('x2', { confirmedBy: 'admin', donatedOn: '2026-07-01T00:00:00Z' }),
        ],
        districts: [
            doc('1201', { nameEn: 'Chamkar Mon', nameKm: 'ចំការមន' }),
            doc('1202', { nameEn: 'Doun Penh', nameKm: 'ដូនពេញ' }),
            doc('1203', { nameEn: 'Prampir Meakkakra', nameKm: '៧មករា' }),
        ],
    };
    const d = computeDashboard(raw, range);

    it('computes the KPIs the way metrics.mjs does, for the period', () => {
        expect(d.kpis.donorsRegistered).toBe(2);
        expect(d.kpis.donorsTotal).toBe(3);
        // live = r1, r2, r5 (r3 rejected, r4 out of range); r1 accepted within the hour
        expect(d.kpis.liveRequests).toBe(3);
        expect(d.kpis.acceptedWithinHour).toBeCloseTo(1 / 3);
        expect(d.kpis.medianFirstAcceptMinutes).toBe(20);
        expect(d.kpis.donationsConfirmed).toBe(1);
        // alerts on in-range requests: r1_d3, r2_d1, r2_d2 — two were sent
        expect(d.kpis.alerts).toBe(3);
        expect(d.kpis.pushSuccess).toBeCloseTo(2 / 3);
        expect(d.kpis.medianReviewMinutes).toBe(20);
        expect(d.kpis.waitingForReview).toBe(1);
    });

    it('buckets requests by day with their outcome', () => {
        expect(d.overTime).toHaveLength(7);
        const sep28 = d.overTime.find((b) => b.key === '2026-09-28');
        expect(sep28?.counts).toEqual({ fulfilled: 0, open: 1, pending: 1, closed: 1 });
    });

    it('counts demand per blood type against available donors', () => {
        const oNeg = d.bloodTypes.find((b) => b.type === 'O-');
        expect(oNeg).toEqual({ type: 'O-', requests: 2, donors: 1 });
    });

    it('ranks hospitals by requests and lists every district', () => {
        expect(d.hospitals[0]).toEqual({ name: 'Calmette', requests: 3 });
        expect(d.districts.map((x) => x.donors)).toEqual([2, 1, 0]);
    });
});
