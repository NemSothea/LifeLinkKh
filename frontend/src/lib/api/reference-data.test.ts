import { afterEach, describe, expect, it, vi } from 'vitest';
import { fakeFirebase } from '@/test/fake-firebase';
import { clearReferenceDataCache, listDistricts } from './reference-data';

const tables = { districts: [{ id: '1202', fields: { nameKm: 'ដូនពេញ', nameEn: 'Doun Penh' } }] };

afterEach(() => {
    vi.unstubAllGlobals();
    clearReferenceDataCache();
});

describe('listDistricts', () => {
    it('reads Firestore once and serves the next ten minutes from memory', async () => {
        const calls = fakeFirebase(tables);
        const t0 = 1_000_000;

        await listDistricts(t0);
        const second = await listDistricts(t0 + 9 * 60_000);

        expect(calls).toHaveLength(1);
        expect(second.ok && second.data.get('1202')).toEqual({ km: 'ដូនពេញ', en: 'Doun Penh' });
    });

    it('reads again once the ten minutes are up', async () => {
        const calls = fakeFirebase(tables);

        await listDistricts(1_000_000);
        await listDistricts(1_000_000 + 11 * 60_000);

        expect(calls).toHaveLength(2);
    });

    it('does not remember a failure', async () => {
        vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')));
        expect(await listDistricts(1_000_000)).toEqual({ ok: false, error: 'unreachable' });

        const calls = fakeFirebase(tables);
        expect((await listDistricts(1_000_001)).ok).toBe(true);
        expect(calls).toHaveLength(1);
    });
});
