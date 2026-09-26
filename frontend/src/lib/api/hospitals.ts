import { firestoreQuery, type ApiResult } from './client';
import type { DistrictName } from './district';

/** `hospitals/{id}` — reference data, public read (seeded by `firebase/seed/`). Sorted by name. */
export type Hospital = { id: string; name: string };

export async function listHospitals(): Promise<ApiResult<Hospital[]>> {
    const result = await firestoreQuery({ collection: 'hospitals' }, null);
    if (!result.ok) return result;
    return {
        ok: true,
        data: result.data
            .map((doc) => ({ id: doc.id, name: String(doc.data.name ?? '') }))
            .sort((a, b) => a.name.localeCompare(b.name)),
    };
}

/** `districts/{code}` — both labels per code, for turning a donor's `districtCode` into a name. */
export async function listDistricts(): Promise<ApiResult<Map<string, DistrictName>>> {
    const result = await firestoreQuery({ collection: 'districts' }, null);
    if (!result.ok) return result;
    return {
        ok: true,
        data: new Map(
            result.data.map((doc) => [
                doc.id,
                { km: String(doc.data.nameKm ?? ''), en: String(doc.data.nameEn ?? '') },
            ]),
        ),
    };
}
