import { firestoreQuery, type ApiResult } from './client';
import type { DistrictName } from './district';
import { listDistricts } from './hospitals';
import { acceptedDonors, requestFields } from './request-docs';

/**
 * The live board, readable with no session at all (DEC-009): `requests` where `status == OPEN`,
 * and each one's `acceptedDonors`, read signed out — the rules make both public.
 *
 * Its own module and its own types: everything here is world-readable, so it must not share a
 * shape with the portal's authenticated one. If the two shared a type, a field added for staff
 * would appear on the public page the day someone added it.
 *
 * Note what is missing next to `AcceptedDonor`: no `matchId`. That handle exists to write a
 * donation confirmation, and a signed-out visitor has nothing to do with it.
 */
export type PublicDonor = {
    displayName: string;
    bloodType: string;
    districtName: DistrictName | null;
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

/** No token, deliberately — passing one would make a public page fail when a session expired. */
export async function listPublicRequests(): Promise<ApiResult<PublicRequest[]>> {
    const [requests, districts] = await Promise.all([
        firestoreQuery(
            {
                collection: 'requests',
                where: { status: 'OPEN' },
                orderBy: { field: 'createdAt', direction: 'DESCENDING' },
            },
            null,
        ),
        listDistricts(),
    ]);
    if (!requests.ok) return requests;
    const names = districts.ok ? districts.data : new Map<string, DistrictName>();

    const rows = await Promise.all(
        requests.data.map(async (doc): Promise<ApiResult<PublicRequest>> => {
            const donors = await acceptedDonors(doc.id, null);
            if (!donors.ok) return donors;
            return {
                ok: true,
                data: {
                    ...requestFields(doc),
                    acceptedDonors: donors.data.map((donor) => ({
                        displayName: String(donor.data.displayName ?? ''),
                        bloodType: String(donor.data.bloodType ?? ''),
                        districtName: names.get(String(donor.data.districtCode)) ?? null,
                        respondedAt: String(donor.data.respondedAt ?? ''),
                    })),
                },
            };
        }),
    );
    const failed = rows.find((row) => !row.ok);
    if (failed && !failed.ok) return failed;
    return { ok: true, data: rows.flatMap((row) => (row.ok ? [row.data] : [])) };
}
