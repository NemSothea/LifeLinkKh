import type { PendingRequest, PortalRequest } from '@/lib/api/portal';

/** One entry in the admin's bell: what happened, when, and where to go to deal with it. */
export type AdminNotification = {
    id: string;
    /** `unmatched`: approved, but matching found no eligible donor — the family is waiting on nobody. */
    kind: 'pending' | 'accepted' | 'unmatched';
    bloodType: string;
    hospital: string | null;
    donor: string | null;
    /** ISO time it happened: the request's creation, or the donor's answer. */
    at: string;
    href: string;
};

/**
 * The bell's list, from data the portal page already has: requests waiting for review,
 * donors who accepted and are waiting for their donation to be confirmed, and open requests
 * that alerted nobody — the one case where the app has done all it can and a person has to
 * step in. Newest first.
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
        ...open
            .filter((r) => r.alertedCount === 0)
            .map((r) => ({
                id: `unmatched-${r.id}`,
                kind: 'unmatched' as const,
                bloodType: r.patientBloodType,
                hospital: r.hospital?.name ?? null,
                donor: null,
                at: r.createdAt,
                href: `/${locale}/portal#request-${r.id}`,
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
