import { describe, expect, it } from 'vitest';
import { isToday, minutesOld, relativeAge } from './time';

const NOW = new Date('2026-09-06T12:00:00.000Z');

function isoMinutesAgo(minutes: number): string {
    return new Date(NOW.getTime() - minutes * 60_000).toISOString();
}

describe('relativeAge', () => {
    it('reads under a minute as "now"', () => {
        expect(relativeAge(isoMinutesAgo(0), NOW)).toEqual({ unit: 'now' });
        expect(relativeAge(new Date(NOW.getTime() - 59_000).toISOString(), NOW)).toEqual({
            unit: 'now',
        });
    });

    // A device clock a few seconds ahead of the server must not render "-1 minutes ago".
    it('treats a future timestamp as now rather than a negative age', () => {
        expect(relativeAge(new Date(NOW.getTime() + 30_000).toISOString(), NOW)).toEqual({
            unit: 'now',
        });
    });

    it('counts whole minutes below an hour', () => {
        expect(relativeAge(isoMinutesAgo(14), NOW)).toEqual({ unit: 'minutes', value: 14 });
        expect(relativeAge(isoMinutesAgo(59), NOW)).toEqual({ unit: 'minutes', value: 59 });
    });

    it('rolls over to hours, then days', () => {
        expect(relativeAge(isoMinutesAgo(60), NOW)).toEqual({ unit: 'hours', value: 1 });
        expect(relativeAge(isoMinutesAgo(60 * 25), NOW)).toEqual({ unit: 'days', value: 1 });
        expect(relativeAge(isoMinutesAgo(60 * 24 * 6), NOW)).toEqual({ unit: 'days', value: 6 });
    });

    // Past a week the relative reading stops helping — "nine days ago" is harder to
    // place than a date, and nothing in this app is urgent at that age.
    it('falls back to the raw timestamp after a week', () => {
        const iso = isoMinutesAgo(60 * 24 * 8);
        expect(relativeAge(iso, NOW)).toEqual({ unit: 'date', value: iso });
    });
});

describe('minutesOld', () => {
    it('floors to whole minutes and never goes negative', () => {
        expect(minutesOld(isoMinutesAgo(42), NOW)).toBe(42);
        expect(minutesOld(new Date(NOW.getTime() + 60_000).toISOString(), NOW)).toBe(0);
    });
});

describe('isToday', () => {
    it('compares against the viewer’s own calendar day', () => {
        expect(isToday(isoMinutesAgo(60), NOW)).toBe(true);
        expect(isToday(isoMinutesAgo(60 * 48), NOW)).toBe(false);
    });
});
