import { describe, expect, it } from 'vitest';
import { districtLabel, type DistrictName } from './district';

/**
 * BUG-API-004. The donor's district used to arrive as a bare English string while the hospital's
 * on the same card arrived as a pair, so the Khmer board printed one Latin place name per row.
 * The API now sends both labels and the client picks — these are the picking rules.
 */
describe('districtLabel', () => {
    const dounPenh: DistrictName = { km: 'ដូនពេញ', en: 'Doun Penh' };

    it('gives the Khmer label on the Khmer board', () => {
        expect(districtLabel(dounPenh, 'km')).toBe('ដូនពេញ');
    });

    it('gives the English label on the English board', () => {
        expect(districtLabel(dounPenh, 'en')).toBe('Doun Penh');
    });

    /** A locale the portal does not have messages for still has to render something readable. */
    it('falls back to English for an unknown locale', () => {
        expect(districtLabel(dounPenh, 'fr')).toBe('Doun Penh');
    });

    /** A donor whose district code has no row: the label is absent, not the string "null". */
    it('returns null when there is no district', () => {
        expect(districtLabel(null, 'km')).toBeNull();
        expect(districtLabel(undefined, 'en')).toBeNull();
    });
});
