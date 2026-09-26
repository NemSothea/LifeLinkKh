// The clauses of DonorCandidateRepository.findCandidates, one test each — the same cases
// MatchingIntegrationTest ran against a real PostgreSQL, so the port is held to the original.
import { describe, expect, test } from 'vitest';
import {
  COMPATIBLE_DONORS,
  MAX_NOTIFIED,
  distanceKm,
  phnomPenhDate,
  selectCandidates,
} from '../../src/matching.js';

const CALMETTE = { lat: 11.581329, lng: 104.91569 };
// 2026-09-26 10:00 in Phnom Penh.
const NOW = new Date('2026-09-26T03:00:00Z');

const donor = (uid, overrides = {}) => ({
  uid,
  bloodType: 'O-',
  isAvailable: true,
  lastDonationDate: null,
  lat: 11.5806,
  lng: 104.9165,
  ...overrides,
});
const request = (overrides = {}) => ({ patientBloodType: 'AB+', createdBy: 'requester', ...overrides });
const run = (donors, overrides = {}) =>
  selectCandidates({ request: request(overrides.request), hospital: CALMETTE, donors, now: NOW, ...overrides.opts });
const uids = (rows) => rows.map((r) => r.uid);

describe('compatibility — ADR 0004', () => {
  test('the table is the blood_compatibility rows', () => {
    expect(COMPATIBLE_DONORS['O-']).toEqual(['O-']);
    expect(COMPATIBLE_DONORS['AB+']).toHaveLength(8);
    expect(COMPATIBLE_DONORS['A+'].sort()).toEqual(['A+', 'A-', 'O+', 'O-']);
  });

  test('direction: an O− patient is offered O− donors only, not every donor in the city', () => {
    const rows = run([donor('o-neg'), donor('ab-pos', { bloodType: 'AB+' }), donor('a-pos', { bloodType: 'A+' })],
      { request: { patientBloodType: 'O-' } });
    expect(uids(rows)).toEqual(['o-neg']);
  });

  test('an AB+ patient takes every type', () => {
    const all = Object.keys(COMPATIBLE_DONORS).map((t, i) => donor(`d${i}`, { bloodType: t }));
    expect(run(all)).toHaveLength(8);
  });
});

describe('filters', () => {
  test('an unavailable donor is not alerted', () => {
    expect(run([donor('away', { isAvailable: false })])).toEqual([]);
  });

  test('a donor never matches their own request', () => {
    expect(uids(run([donor('requester'), donor('other')]))).toEqual(['other']);
  });

  test('56-day cooldown, boundary inclusive, on the Phnom Penh calendar', () => {
    const rows = run([
      donor('exactly-56', { lastDonationDate: '2026-08-01' }),
      donor('55-days', { lastDonationDate: '2026-08-02' }),
      donor('never'),
    ]);
    expect(uids(rows).sort()).toEqual(['exactly-56', 'never']);
  });

  test('"today" is Phnom Penh\'s date, not UTC\'s', () => {
    // 20:00 UTC on the 25th is 03:00 on the 26th in Phnom Penh.
    expect(phnomPenhDate(new Date('2026-09-25T20:00:00Z'))).toBe('2026-09-26');
  });

  test('outside the radius is cut; no GPS still matches (ADR 0003)', () => {
    const rows = run([
      donor('mountain-view', { lat: 37.42, lng: -122.08 }),
      donor('no-gps', { lat: null, lng: null }),
      donor('near'),
    ]);
    expect(uids(rows)).toEqual(['near', 'no-gps']);
  });
});

describe('ordering and cap', () => {
  test('nearest first, no GPS last — never read as 0 km (the least(NULL) trap)', () => {
    const rows = run([
      donor('no-gps', { lat: null, lng: null }),
      donor('far', { lat: 11.62, lng: 104.95 }),
      donor('near'),
    ]);
    expect(uids(rows)).toEqual(['near', 'far', 'no-gps']);
    expect(rows[2].distanceKm).toBeNull();
  });

  test('distance is rounded to half a kilometre', () => {
    const [row] = run([donor('far', { lat: 11.62, lng: 104.95 })]);
    expect(row.distanceKm * 2).toBe(Math.round(row.distanceKm * 2));
  });

  test('equal distance breaks on id, so a re-run alerts the same donors (ADR 0008)', () => {
    const rows = run([donor('b'), donor('c'), donor('a')]);
    expect(uids(rows)).toEqual(['a', 'b', 'c']);
  });

  test('at most 25 are alerted — a ceiling, never a target', () => {
    const many = Array.from({ length: 40 }, (_, i) => donor(`d${String(i).padStart(2, '0')}`));
    expect(run(many)).toHaveLength(MAX_NOTIFIED);
  });
});

describe('distanceKm', () => {
  test('the same point is 0, not NaN — Math.min(1, …) guards acos', () => {
    expect(distanceKm(11.5806, 104.9165, 11.5806, 104.9165)).toBe(0);
  });

  test('any null coordinate is null, never 0', () => {
    expect(distanceKm(11.5, 104.9, null, 104.9)).toBeNull();
  });
});
