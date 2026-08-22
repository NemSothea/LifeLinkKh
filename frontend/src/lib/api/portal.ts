import { apiGet, apiPost, type ApiResult } from './client';

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

/**
 * The bearer token for every `/portal/*` call.
 *
 * **Temporary.** No Firebase Web app is registered yet, so there is no Google Sign-In
 * button on the portal — see `docs/po/prototypes/web/PORTAL-open-requests/README.md`.
 * `PORTAL_DEV_JWT` is a session minted directly for the seeded HOSPITAL account
 * (`V8__portal_access.sql`) and pasted into `.env.local`; it expires in one hour like
 * any other session (ADR 0007) and has to be re-minted, not renewed. Server-side only —
 * never read this under a `NEXT_PUBLIC_` name, or the token ships in the browser bundle.
 */
function authHeader(): HeadersInit {
    const token = process.env.PORTAL_DEV_JWT;
    if (!token) {
        throw new Error(
            'PORTAL_DEV_JWT is not set. See docs/po/prototypes/web/PORTAL-open-requests/README.md.',
        );
    }
    return { Authorization: `Bearer ${token}` };
}

export function listOpenRequests(): Promise<ApiResult<PortalRequest[]>> {
    return apiGet<PortalRequest[]>('/portal/requests?status=OPEN', authHeader());
}

export function confirmDonation(
    requestId: string,
    matchId: string,
    donatedOn: string,
): Promise<ApiResult<ConfirmDonationResult>> {
    return apiPost<ConfirmDonationResult>(
        `/portal/requests/${requestId}/confirm-donation`,
        { matchId, donatedOn },
        authHeader(),
    );
}
