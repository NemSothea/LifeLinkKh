import { apiGet, type ApiResult } from './client';
import { portalAuthHeader } from './dev-auth';

/** `GET /hospitals` — reference data, sorted by name server-side. */
export type Hospital = { id: string; name: string };

export function listHospitals(): Promise<ApiResult<Hospital[]>> {
    return apiGet<Hospital[]>('/hospitals', portalAuthHeader());
}
