import { firestoreQuery, type ApiResult, type Doc } from './client';

/**
 * Decoding shared by `board.ts` and `portal.ts`. Not a response shape — each of those keeps its
 * own type on purpose — only the reading of the same `requests/{id}` document both are built from.
 */
export type RequestFields = {
    id: string;
    patientBloodType: string;
    unitsNeeded: number;
    urgency: string;
    status: string;
    hospital: { id: string; name: string } | null;
    alertedCount: number;
    acceptedCount: number;
    createdAt: string;
};

export function requestFields(doc: Doc): RequestFields {
    const d = doc.data;
    // `hospital` is written by onRequestCreated. A request the Function has not reached yet has
    // only its id, and a card with no hospital name is what the old API sent for the same case.
    const hospital = d.hospital as { name?: string } | null | undefined;
    return {
        id: doc.id,
        patientBloodType: String(d.patientBloodType ?? ''),
        unitsNeeded: Number(d.unitsNeeded ?? 0),
        urgency: String(d.urgency ?? ''),
        status: String(d.status ?? ''),
        hospital: hospital?.name ? { id: String(d.hospitalId), name: hospital.name } : null,
        alertedCount: Number(d.alertedCount ?? 0),
        acceptedCount: Number(d.acceptedCount ?? 0),
        createdAt: String(d.createdAt ?? ''),
    };
}

/** `requests/{id}/acceptedDonors` — public read. The doc id is the donor's uid. */
export async function acceptedDonors(
    requestId: string,
    token: string | null,
): Promise<ApiResult<Doc[]>> {
    const result = await firestoreQuery(
        { parent: `requests/${requestId}`, collection: 'acceptedDonors' },
        token,
    );
    if (!result.ok) return result;
    // Earliest first: the order they answered in, which is the order staff expect them.
    return {
        ok: true,
        data: [...result.data].sort((a, b) =>
            String(a.data.respondedAt ?? '').localeCompare(String(b.data.respondedAt ?? '')),
        ),
    };
}
