import { firestoreQuery, type ApiResult } from './client';
import type { DistrictName } from './district';

/**
 * `districts/{code}` — both labels per code, for turning a donor's `districtCode` into a name.
 * Public read, seeded once by `firebase/seed/`, and never written by any client.
 *
 * Cached in the server's memory for ten minutes. Every board and portal render needs all
 * fourteen, and reading them each time was most of the page's Firestore reads — the one budget
 * that could end LifeLink's free allowance (production-checklist Part A). Only a success is
 * cached, so a failed read is retried on the next render rather than remembered.
 */
const TTL_MS = 10 * 60_000;
let cache: { at: number; value: Map<string, DistrictName> } | null = null;

export async function listDistricts(
    now = Date.now(),
): Promise<ApiResult<Map<string, DistrictName>>> {
    if (cache && now - cache.at < TTL_MS) return { ok: true, data: cache.value };

    const result = await firestoreQuery({ collection: 'districts' }, null);
    if (!result.ok) return result;
    const value = new Map(
        result.data.map((doc) => [
            doc.id,
            { km: String(doc.data.nameKm ?? ''), en: String(doc.data.nameEn ?? '') },
        ]),
    );
    cache = { at: now, value };
    return { ok: true, data: value };
}

/** Tests only: forget the cache so one test's districts cannot leak into the next. */
export function clearReferenceDataCache(): void {
    cache = null;
}
