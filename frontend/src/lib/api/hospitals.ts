import { apiGet, type ApiResult } from './client';
import { portalAuthHeader } from './session';

/** `GET /hospitals` — reference data, sorted by name server-side. */
export type Hospital = { id: string; name: string };

export async function listHospitals(): Promise<ApiResult<Hospital[]>> {
    return apiGet<Hospital[]>('/hospitals', await portalAuthHeader());
}
