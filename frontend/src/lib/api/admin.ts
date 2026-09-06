import { apiGet, apiPost, type ApiResult } from './client';
import { portalAuthHeader } from './session';

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

export async function listCandidates(): Promise<ApiResult<AdminCandidate[]>> {
    return apiGet<AdminCandidate[]>('/admin/users', await portalAuthHeader());
}

export async function listStaff(): Promise<ApiResult<StaffMember[]>> {
    return apiGet<StaffMember[]>('/admin/staff', await portalAuthHeader());
}

/**
 * Creates a portal account outright — the sibling of `assignStaffRole`, for staff who have no
 * mobile account to promote. Until this existed the only way to add one was a Flyway migration.
 */
export async function createStaffAccount(input: {
    username: string;
    password: string;
    displayName: string;
    role: string;
    hospitalId: string | null;
}): Promise<ApiResult<StaffMember>> {
    return apiPost<StaffMember>('/admin/staff/accounts', input, await portalAuthHeader());
}

/** ADMIN → hospital staff, scoped to one hospital. */
export async function demoteStaff(userId: string, hospitalId: string): Promise<ApiResult<StaffMember>> {
    return apiPost<StaffMember>(`/admin/staff/${userId}/demote`, { hospitalId }, await portalAuthHeader());
}

/** Removes portal access. A promoted account returns to DONOR; a portal-only one is deactivated. */
export async function revokeStaff(userId: string): Promise<ApiResult<void>> {
    return apiPost<void>(`/admin/staff/${userId}/revoke`, {}, await portalAuthHeader());
}

export async function assignStaffRole(
    userId: string,
    role: string,
    hospitalId: string | null,
): Promise<ApiResult<StaffMember>> {
    return apiPost<StaffMember>('/admin/staff', { userId, role, hospitalId }, await portalAuthHeader());
}
