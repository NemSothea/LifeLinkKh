import { apiGet, apiPost, type ApiResult } from './client';
import { portalAuthHeader } from './session';
import type { DistrictName } from './district';

/**
 * Typed against `GET`/`POST /api/portal/requests...` in
 * `docs/fullstack/api-contract/web/openapi.yaml`. FR-PORTAL-001, trimmed by DEC-004 to
 * one page.
 */
export type AcceptedDonor = {
    matchId: string;
    displayName: string;
    bloodType: string;
    districtName: DistrictName | null;
    respondedAt: string;
};

export type PortalRequest = {
    id: string;
    patientBloodType: string;
    unitsNeeded: number;
    urgency: string;
    status: string;
    hospital: { id: string; name: string } | null;
    alertedCount: number;
    acceptedCount: number;
    createdAt: string;
    acceptedDonors: AcceptedDonor[];
};

export type ConfirmDonationResult = {
    id: string;
    donorDisplayName: string;
    donatedOn: string;
    requestStatus: string;
    donorNextEligibleOn: string;
};

export async function listOpenRequests(): Promise<ApiResult<PortalRequest[]>> {
    return apiGet<PortalRequest[]>('/portal/requests?status=OPEN', await portalAuthHeader());
}

/**
 * The same endpoint with the other status the contract allows. `status` takes one value
 * (`openapi.yaml`: `enum: [OPEN, FULFILLED, CANCELLED]`), so "open plus what we finished"
 * is two calls, not one filter.
 */
export async function listFulfilledRequests(): Promise<ApiResult<PortalRequest[]>> {
    return apiGet<PortalRequest[]>('/portal/requests?status=FULFILLED', await portalAuthHeader());
}

export async function confirmDonation(
    requestId: string,
    matchId: string,
    donatedOn: string,
): Promise<ApiResult<ConfirmDonationResult>> {
    return apiPost<ConfirmDonationResult>(
        `/portal/requests/${requestId}/confirm-donation`,
        { matchId, donatedOn },
        await portalAuthHeader(),
    );
}
