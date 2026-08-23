import { apiGet, apiPost, type ApiResult } from './client';
import { portalAuthHeader } from './dev-auth';

/**
 * Typed against `GET`/`POST /api/portal/requests...` in
 * `docs/fullstack/api-contract/web/openapi.yaml`. FR-PORTAL-001, trimmed by DEC-004 to
 * one page.
 */
export type AcceptedDonor = {
    matchId: string;
    displayName: string;
    bloodType: string;
    districtName: string | null;
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

export function listOpenRequests(): Promise<ApiResult<PortalRequest[]>> {
    return apiGet<PortalRequest[]>('/portal/requests?status=OPEN', portalAuthHeader());
}

export function confirmDonation(
    requestId: string,
    matchId: string,
    donatedOn: string,
): Promise<ApiResult<ConfirmDonationResult>> {
    return apiPost<ConfirmDonationResult>(
        `/portal/requests/${requestId}/confirm-donation`,
        { matchId, donatedOn },
        portalAuthHeader(),
    );
}
