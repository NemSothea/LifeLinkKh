import { apiGet, type ApiResult } from './client';

/**
 * `GET /public/requests` — the live board, readable with no session at all.
 *
 * Its own module and its own types, mirroring the backend's reason for a separate service:
 * everything here is world-readable, so it must not share a shape with the portal's
 * authenticated response. If the two shared a type, a field added for staff would appear on
 * the public page the day someone added it.
 *
 * Note what is missing next to `AcceptedDonor`: no `matchId`. That handle exists to write a
 * donation confirmation, and a signed-out visitor has nothing to do with it.
 */
export type PublicDonor = {
    displayName: string;
    bloodType: string;
    districtName: string | null;
    respondedAt: string;
};

export type PublicRequest = {
    id: string;
    patientBloodType: string;
    unitsNeeded: number;
    urgency: string;
    status: string;
    hospital: { id: string; name: string } | null;
    alertedCount: number;
    acceptedCount: number;
    createdAt: string;
    acceptedDonors: PublicDonor[];
};

/** No auth header, deliberately — passing one would make a public page fail when a session expired. */
export function listPublicRequests(): Promise<ApiResult<PublicRequest[]>> {
    return apiGet<PublicRequest[]>('/public/requests');
}
