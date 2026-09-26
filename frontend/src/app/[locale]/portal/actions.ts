'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { confirmDonation, reviewRequest } from '@/lib/api/portal';

/**
 * The one write on the portal's one page (FR-PORTAL-001 / FR-DONATION-001). A plain
 * `<form action={...}>` Server Action, not a client component with `useActionState` —
 * DEC-004 trimmed this page to a table plus one action, and a client-side form state
 * hook is a dependency this page has no second use for.
 *
 * Redirects back to the same locale rather than returning a value, because a Server
 * Action bound directly to a `<form>` (no `useActionState`) has no client to hand a
 * return value to.
 */
export async function confirmDonationAction(formData: FormData) {
    const requestId = formData.get('requestId');
    const matchId = formData.get('matchId');
    const donatedOn = formData.get('donatedOn');
    const locale = formData.get('locale');
    const donorName = formData.get('donorName');

    if (
        typeof requestId !== 'string' ||
        typeof matchId !== 'string' ||
        typeof donatedOn !== 'string' ||
        typeof locale !== 'string' ||
        typeof donorName !== 'string'
    ) {
        throw new Error('confirm-donation form is missing a required field');
    }

    const result = await confirmDonation(requestId, matchId, donatedOn);

    // Without this, Next's client Router Cache can serve the pre-mutation RSC
    // payload for a redirect landing back on the same route — the row this action
    // just confirmed would still show its "confirm" button until the cache's
    // default staleTime passed on its own.
    revalidatePath(`/${locale}/portal`);
    redirect(
        result.ok
            ? `/${locale}/portal?confirmed=${encodeURIComponent(donorName)}`
            : `/${locale}/portal?confirmError=1`,
    );
}

/**
 * DEC-015: approve or reject a pending request. Approving alerts donors, so the button that
 * submits this form sits behind a confirmation step in `pending-review-list.tsx`.
 *
 * `failed-precondition` means the request is no longer PENDING — its creator cancelled it, or
 * another admin reviewed it first. That gets its own message: the admin did nothing wrong, and
 * "could not complete that" would send them to try again.
 */
export async function reviewRequestAction(formData: FormData) {
    const requestId = formData.get('requestId');
    const decision = formData.get('decision');
    const reason = formData.get('reason');
    const locale = formData.get('locale');

    if (
        typeof requestId !== 'string' ||
        (decision !== 'APPROVE' && decision !== 'REJECT') ||
        typeof locale !== 'string'
    ) {
        throw new Error('review-request form is missing a required field');
    }

    const result = await reviewRequest(
        requestId,
        decision,
        decision === 'REJECT' && typeof reason === 'string' ? reason : undefined,
    );

    revalidatePath(`/${locale}/portal`);
    redirect(
        result.ok
            ? `/${locale}/portal?reviewed=${decision === 'APPROVE' ? 'approved' : 'rejected'}`
            : `/${locale}/portal?reviewError=${result.error === 'failed-precondition' ? 'gone' : '1'}`,
    );
}
