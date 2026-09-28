import type { PendingRequest, PortalRequest } from '@/lib/api/portal';

/** One entry in the admin's bell: what happened, when, and where to go to deal with it. */
export type AdminNotification = {
    id: string;
    kind: 'pending' | 'accepted';
    bloodType: string;
    hospital: string | null;
    donor: string | null;
    /** ISO time it happened: the request's creation, or the donor's answer. */
    at: string;
    href: string;
};

/**
 * The bell's list, from data the portal page already has: requests waiting for review, and
 * donors who accepted and are waiting for their donation to be confirmed. Newest first.
 */
export function adminNotifications(
    locale: string,
    pending: PendingRequest[],
    open: PortalRequest[],
): AdminNotification[] {
    const items: AdminNotification[] = [
        ...pending.map((r) => ({
            id: `pending-${r.id}`,
            kind: 'pending' as const,
            bloodType: r.patientBloodType,
            hospital: r.hospital?.name ?? null,
            donor: null,
            at: r.createdAt,
            href: `/${locale}/portal#pending-${r.id}`,
        })),
        ...open.flatMap((r) =>
            r.acceptedDonors.map((d) => ({
                id: `accepted-${d.matchId}`,
                kind: 'accepted' as const,
                bloodType: r.patientBloodType,
                hospital: r.hospital?.name ?? null,
                donor: d.displayName,
                at: d.respondedAt,
                href: `/${locale}/portal#request-${r.id}`,
            })),
        ),
    ];
    return items.sort((a, b) => b.at.localeCompare(a.at));
}
