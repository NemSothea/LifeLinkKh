import { apiGet, apiPost, type ApiResult } from './client';
import { portalAuthHeader } from './dev-auth';

/**
 * `GET`/`POST /admin/*` — staff provisioning (TM-AUTH-001 E1). `SecurityConfig` restricts
 * every `/admin/*` call to `ADMIN`; a `HOSPITAL` session gets a 403 from the backend
 * regardless of what this page renders.
 */
export type AdminCandidate = { id: string; displayName: string; role: string };

export type StaffMember = {
    id: string;
    displayName: string | null;
    role: string;
    hospitalId: string | null;
    hospitalName: string | null;
};

export function listCandidates(): Promise<ApiResult<AdminCandidate[]>> {
    return apiGet<AdminCandidate[]>('/admin/users', portalAuthHeader());
}

export function listStaff(): Promise<ApiResult<StaffMember[]>> {
    return apiGet<StaffMember[]>('/admin/staff', portalAuthHeader());
}

export function assignStaffRole(
    userId: string,
    role: string,
    hospitalId: string | null,
): Promise<ApiResult<StaffMember>> {
    return apiPost<StaffMember>('/admin/staff', { userId, role, hospitalId }, portalAuthHeader());
}
