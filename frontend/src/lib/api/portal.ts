import { callFunction, firestoreGet, firestoreQuery, type ApiResult } from './client';
import type { DistrictName } from './district';
import { listDistricts } from './reference-data';
import { acceptedDonors, requestFields } from './request-docs';
import { requirePortalToken } from './session';

/**
 * The portal's requests, read from Firestore as the signed-in staff member (ADR 0009, phase 5).
 * FR-PORTAL-001, trimmed by DEC-004 to one page. Same shapes `GET /portal/requests` returned, so
 * the page did not change when the backend did.
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

/**
 * Every hospital's requests: v1's only portal role is ADMIN (ADR 0009, phase 5). The requests
 * themselves are public (DEC-009); what needs the admin's token is `donations`.
 */
async function listRequests(
    status: 'OPEN' | 'FULFILLED',
    withDonors: boolean,
): Promise<ApiResult<PortalRequest[]>> {
    const token = await requirePortalToken();
    const [requests, districts] = await Promise.all([
        firestoreQuery(
            {
                collection: 'requests',
                where: { status },
                orderBy: { field: 'createdAt', direction: 'DESCENDING' },
            },
            token,
        ),
        listDistricts(),
    ]);
    if (!requests.ok) return requests;
    const names = districts.ok ? districts.data : new Map<string, DistrictName>();

    const rows = await Promise.all(
        requests.data.map(async (doc): Promise<ApiResult<PortalRequest>> => {
            const request = requestFields(doc);
            if (!withDonors) return { ok: true, data: { ...request, acceptedDonors: [] } };

            const [donors, confirmed] = await Promise.all([
                acceptedDonors(doc.id, token),
                firestoreQuery(
                    {
                        collection: 'donations',
                        where: { requestId: doc.id },
                    },
                    token,
                ),
            ]);
            if (!donors.ok) return donors;
            if (!confirmed.ok) return confirmed;
            const done = new Set(confirmed.data.map((donation) => String(donation.data.donorUid)));
            const actionable = donors.data.filter((donor) => !done.has(donor.id));
            // The board row carries a shortened name ("Nem S.") because anyone can read it. The
            // admin confirming a donation at the hospital needs the full one, which only the
            // admin may read, from the donor's profile. A missing profile (the donor deleted
            // their account a moment ago) falls back to the board's name.
            const profiles = await Promise.all(
                actionable.map((donor) => firestoreGet(`donors/${donor.id}`, token)),
            );

            return {
                ok: true,
                data: {
                    ...request,
                    // `acceptedCount` is every acceptance; this list is narrower on purpose — it is
                    // the actionable list, so a donor whose donation is already confirmed drops
                    // off it rather than keeping a button that would only be refused.
                    acceptedDonors: actionable.map((donor, i) => {
                        const profile = profiles[i];
                        const fullName =
                            profile.ok && typeof profile.data?.data.fullName === 'string'
                                ? profile.data.data.fullName
                                : null;
                        return {
                            // The match id is `{requestId}_{donorUid}` by construction, and the
                            // board document's id is the donor's uid.
                            matchId: `${doc.id}_${donor.id}`,
                            displayName: fullName ?? String(donor.data.displayName ?? ''),
                            bloodType: String(donor.data.bloodType ?? ''),
                            districtName: names.get(String(donor.data.districtCode)) ?? null,
                            respondedAt: String(donor.data.respondedAt ?? ''),
                        };
                    }),
                },
            };
        }),
    );
    const failed = rows.find((row) => !row.ok);
    if (failed && !failed.ok) return failed;
    return { ok: true, data: rows.flatMap((row) => (row.ok ? [row.data] : [])) };
}

export function listOpenRequests(): Promise<ApiResult<PortalRequest[]>> {
    return listRequests('OPEN', true);
}

/** Work already done. The page renders no donors for these, so none are read. */
export function listFulfilledRequests(): Promise<ApiResult<PortalRequest[]>> {
    return listRequests('FULFILLED', false);
}

/** The `confirmDonation` callable — the only way a donation is recorded (the rules refuse it). */
export async function confirmDonation(
    requestId: string,
    matchId: string,
    donatedOn: string,
): Promise<ApiResult<ConfirmDonationResult>> {
    return callFunction<ConfirmDonationResult>(
        'confirmDonation',
        { requestId, matchId, donatedOn },
        await requirePortalToken(),
    );
}

/**
 * A request waiting for the admin (DEC-015). Carries the requester's contact, which the rules let
 * the admin read, because checking the need is real usually means calling the family or the
 * hospital — and it is the one screen where that is the job.
 */
export type PendingRequest = {
    id: string;
    patientBloodType: string;
    unitsNeeded: number;
    urgency: string;
    hospital: { id: string; name: string } | null;
    createdAt: string;
    contactName: string | null;
    contactPhone: string | null;
};

const URGENCY_ORDER: Record<string, number> = { CRITICAL: 0, URGENT: 1, ROUTINE: 2 };

/** Most urgent first, then oldest first: the order they should be reviewed in. */
export async function listPendingRequests(): Promise<ApiResult<PendingRequest[]>> {
    const token = await requirePortalToken();
    const requests = await firestoreQuery(
        {
            collection: 'requests',
            where: { status: 'PENDING' },
            orderBy: { field: 'createdAt', direction: 'DESCENDING' },
        },
        token,
    );
    if (!requests.ok) return requests;

    const rows = await Promise.all(
        requests.data.map(async (doc): Promise<ApiResult<PendingRequest>> => {
            const contact = await firestoreGet(`requests/${doc.id}/private/contact`, token);
            if (!contact.ok) return contact;
            const request = requestFields(doc);
            return {
                ok: true,
                data: {
                    id: request.id,
                    patientBloodType: request.patientBloodType,
                    unitsNeeded: request.unitsNeeded,
                    urgency: request.urgency,
                    hospital: request.hospital,
                    createdAt: request.createdAt,
                    contactName: (contact.data?.data.contactName as string | undefined) ?? null,
                    contactPhone: (contact.data?.data.contactPhone as string | undefined) ?? null,
                },
            };
        }),
    );
    const failed = rows.find((row) => !row.ok);
    if (failed && !failed.ok) return failed;
    return {
        ok: true,
        data: rows
            .flatMap((row) => (row.ok ? [row.data] : []))
            .sort(
                (a, b) =>
                    (URGENCY_ORDER[a.urgency] ?? 9) - (URGENCY_ORDER[b.urgency] ?? 9) ||
                    a.createdAt.localeCompare(b.createdAt),
            ),
    };
}

/** The `reviewRequest` callable (DEC-015). Approving is what alerts the donors. */
export async function reviewRequest(
    requestId: string,
    decision: 'APPROVE' | 'REJECT',
    reason?: string,
): Promise<ApiResult<{ requestId: string; status: string }>> {
    return callFunction<{ requestId: string; status: string }>(
        'reviewRequest',
        { requestId, decision, ...(reason === undefined ? {} : { reason }) },
        await requirePortalToken(),
    );
}
