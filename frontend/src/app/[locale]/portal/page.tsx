import { getTranslations } from 'next-intl/server';
import Link from 'next/link';
import AutoRefresh from '@/components/AutoRefresh';
import EmptyState from '@/components/EmptyState';
import LanguageSwitcher from '@/components/LanguageSwitcher';
import RelativeTime from '@/components/RelativeTime';
import { hasPortalSession, portalDisplayName, portalRole } from '@/lib/api/session';
import SignOutButton from '@/components/SignOutButton';
import { listPublicRequests } from '@/lib/api/board';
import { listFulfilledRequests, listOpenRequests, type PortalRequest } from '@/lib/api/portal';
import { IconAlertTriangle, IconCheck, IconChevron, IconDroplet, IconInbox } from '@/components/icons';
import RequestList, { type RequestViewModel } from './request-list';

/**
 * The live board, and the portal, on one page.
 *
 * **Signed out** it is a public read of `GET /public/requests` (DEC-009): who needs blood,
 * where, how urgently, when they asked, and who has accepted. No session, no redirect —
 * anyone with the link sees the need, which is the entire point of a board.
 *
 * **Signed in** the same page reads the authenticated endpoint instead, which adds the one
 * thing the public copy deliberately omits: the `matchId` each confirm-donation write needs.
 * So staff get the board plus its actions rather than a different screen.
 *
 * A Server Component either way: both fetches run on the Next server, which is also where
 * the session cookie stays, since it is httpOnly and page script cannot read it.
 */
export default async function PortalPage({
    params,
    searchParams,
}: {
    params: Promise<{ locale: string }>;
    searchParams: Promise<{ confirmError?: string; confirmed?: string }>;
}) {
    const { locale } = await params;
    const { confirmError, confirmed } = await searchParams;
    const t = await getTranslations('portal');
    const isStaff = await hasPortalSession();
    const [role, displayName] = isStaff
        ? await Promise.all([portalRole(), portalDisplayName()])
        : [null, null];

    // Staff read the authenticated endpoints — the open list carries the matchId a
    // confirmation writes against, and the fulfilled list is what the
    // `PORTAL-open-requests` prototype meant by *"a confirmed row shows requestStatus
    // inline rather than disappearing, so staff can see today's work at a glance"*.
    //
    // A signed-out visitor reads the public board instead. Same rows, same counts, minus
    // the write handle — and no "recently fulfilled" section, which is a record of staff
    // work rather than a call for help.
    const [result, fulfilledResult] = isStaff
        ? await Promise.all([listOpenRequests(), listFulfilledRequests()])
        : [await listPublicRequests(), { ok: false } as const];
    const fulfilled = fulfilledResult.ok ? fulfilledResult.data : [];
    // No cast: the two sources have genuinely different donor shapes, and `sortByUrgency`
    // only reads `urgency`. Casting the public rows to `PortalRequest` is what let a
    // missing `matchId` reach the DOM as `key={undefined}`.
    const requests = result.ok ? sortByUrgency(result.data) : [];
    const criticalCount = requests.filter((r) => r.urgency === 'CRITICAL').length;
    // Interpolated server-side because a Client Component (RequestList) cannot receive
    // the `t()` function itself as a prop — functions don't cross that boundary.
    const requestViewModels: RequestViewModel[] = requests.map((request) => ({
        ...request,
        unitsLabel: t('unitsNeeded', { count: request.unitsNeeded }),
    }));

    return (
        <main className="mx-auto max-w-4xl p-6 sm:p-10">
            <header className="mb-8 flex flex-wrap items-end justify-between gap-3">
                <div>
                    <p className="text-sm font-semibold tracking-wide text-brand uppercase">
                        LifeLink KH
                    </p>
                    <h1 className="text-3xl font-bold tracking-tight">{t('title')}</h1>
                </div>
                <div className="flex items-center gap-3">
                    {role === 'ADMIN' ? (
                        <Link
                            href={`/${locale}/portal/staff`}
                            data-testid="manage-staff-link"
                            className="text-sm font-medium text-black/60 underline-offset-4 hover:underline dark:text-white/60"
                        >
                            {t('manageStaffCta')}
                        </Link>
                    ) : null}
                    <LanguageSwitcher />
                    {isStaff ? (
                        <SignOutButton locale={locale} displayName={displayName} role={role} />
                    ) : (
                        // The only thing a visitor is offered. Not a wall in front of the
                        // board — a door beside it, for the people who have a key.
                        <Link
                            href={`/${locale}/sign-in`}
                            data-testid="staff-sign-in-link"
                            className="rounded-full border border-black/10 px-3 py-1.5 text-sm font-medium text-black/70 transition-colors hover:bg-black/[0.03] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:border-white/15 dark:text-white/70 dark:hover:bg-white/[0.05]"
                        >
                            {t('staffSignInCta')}
                        </Link>
                    )}
                    {result.ok ? (
                        <div
                            data-testid="portal-summary"
                            className="flex items-center gap-4 rounded-full border border-black/10 bg-black/[0.02] px-5 py-2 text-sm tabular-nums dark:border-white/15 dark:bg-white/[0.04]"
                        >
                            <span>
                                <strong className="text-lg">{requests.length}</strong>{' '}
                                <span className="text-black/60 dark:text-white/60">{t('openLabel')}</span>
                            </span>
                            {criticalCount > 0 ? (
                                <span className="flex items-center gap-1.5 font-medium text-brand">
                                    <span className="relative flex h-2 w-2">
                                        <span className="absolute inline-flex h-full w-full motion-safe:animate-ping rounded-full bg-brand opacity-75" />
                                        <span className="relative inline-flex h-2 w-2 rounded-full bg-brand" />
                                    </span>
                                    <span className="tabular-nums">{criticalCount}</span> {t('criticalLabel')}
                                </span>
                            ) : null}
                        </div>
                    ) : null}
                </div>
            </header>

            {result.ok ? (
                <div className="mb-6 flex justify-end">
                    <AutoRefresh />
                </div>
            ) : null}

            {confirmed ? (
                <p
                    data-testid="confirm-donation-success"
                    className="mb-6 flex items-center gap-2 rounded-xl border border-emerald-300 bg-emerald-50 p-4 text-emerald-800 dark:border-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300"
                >
                    <IconCheck className="h-5 w-5 shrink-0" />
                    {t('confirmSuccess', { name: confirmed })}
                </p>
            ) : null}

            {confirmError ? (
                <p
                    data-testid="confirm-donation-error"
                    className="mb-6 flex items-center gap-2 rounded-xl border border-red-300 bg-red-50 p-4 text-red-700 dark:border-red-800 dark:bg-red-950/60 dark:text-red-400"
                >
                    <IconAlertTriangle className="h-5 w-5 shrink-0" />
                    {t('confirmFailed')}
                </p>
            ) : null}

            {!result.ok ? (
                <EmptyState icon={<IconAlertTriangle className="h-8 w-8" />} testId="portal-unreachable">
                    {t('unreachable')}
                </EmptyState>
            ) : requests.length === 0 ? (
                <EmptyState icon={<IconInbox className="h-8 w-8" />} testId="portal-empty">
                    {t('empty')}
                </EmptyState>
            ) : (
                <RequestList
                    requests={requestViewModels}
                    canConfirm={isStaff}
                    locale={locale}
                    // `.raw()` on the two below, not `t()`: both carry `{placeholder}`
                    // tokens that `RequestList` fills in per row on the client, and
                    // next-intl's `t()` refuses a message whose placeholders it was
                    // given no values for — it renders the key path instead. That is
                    // what put a literal "portal.unitsProgress" on every row.
                    copy={{
                        noAcceptedDonors: t('noAcceptedDonors'),
                        donatedOnLabel: t('donatedOnLabel'),
                        confirmDonationCta: t('confirmDonationCta'),
                        dialogTitle: t('confirmDialogTitle'),
                        dialogBody: t('confirmDialogBody'),
                        cancelCta: t('cancelCta'),
                        dialogConfirmCta: t('confirmDialogCta'),
                        searchPlaceholder: t('searchPlaceholder'),
                        noMatches: t('noMatches'),
                        filterAll: t('filterAll'),
                        filterCritical: t('filterCritical'),
                        filterUrgent: t('filterUrgent'),
                        filterRoutine: t('filterRoutine'),
                        pageLabel: t.raw('pageLabel'),
                        unitsProgress: t.raw('unitsProgress'),
                        acceptedAtLabel: t('acceptedAtLabel'),
                    }}
                />
            )}

            {isStaff && result.ok ? (
                <FulfilledSection
                    requests={fulfilled}
                    heading={t('fulfilledHeading')}
                    emptyLabel={t('fulfilledEmpty')}
                    unitsLabelFor={(request) => t('unitsNeeded', { count: request.unitsNeeded })}
                />
            ) : null}
        </main>
    );
}

/**
 * Work already done, kept on screen instead of vanishing.
 *
 * Collapsed by default — the open list is the job; this is the receipt. Newest first,
 * because the question it answers is "did that confirmation go through", asked minutes
 * after the confirmation.
 */
function FulfilledSection({
    requests,
    heading,
    emptyLabel,
    unitsLabelFor,
}: {
    requests: PortalRequest[];
    heading: string;
    emptyLabel: string;
    unitsLabelFor: (request: PortalRequest) => string;
}) {
    const newestFirst = [...requests].sort((a, b) => b.createdAt.localeCompare(a.createdAt));

    return (
        <details data-testid="portal-fulfilled" className="group mt-10">
            <summary className="flex cursor-pointer list-none items-center gap-2 text-sm font-semibold text-black/60 select-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:text-white/60">
                <IconChevron className="h-4 w-4 transition-transform duration-200 group-open:rotate-180" />
                <IconCheck className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
                {heading}
                <span className="tabular-nums">({newestFirst.length})</span>
            </summary>

            {newestFirst.length === 0 ? (
                <p
                    data-testid="portal-fulfilled-empty"
                    className="mt-3 text-sm text-black/50 dark:text-white/50"
                >
                    {emptyLabel}
                </p>
            ) : (
                <ul className="mt-3 flex flex-col gap-2">
                    {newestFirst.map((request) => (
                        <li
                            key={request.id}
                            data-testid={`portal-fulfilled-${request.id}`}
                            className="flex flex-wrap items-center gap-3 rounded-xl border border-black/10 bg-black/[0.015] px-4 py-3 text-sm dark:border-white/10 dark:bg-white/[0.02]"
                        >
                            <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-emerald-600/10 text-xs font-bold text-emerald-700 dark:text-emerald-400">
                                <IconDroplet className="mr-0.5 -ml-0.5 h-3 w-3 opacity-70" />
                                {request.patientBloodType}
                            </span>
                            <span className="text-black/70 dark:text-white/70">
                                {unitsLabelFor(request)}
                            </span>
                            {request.hospital ? (
                                <span className="text-black/50 dark:text-white/50">
                                    {request.hospital.name}
                                </span>
                            ) : null}
                            <RelativeTime
                                iso={request.createdAt}
                                className="ml-auto text-xs text-black/45 tabular-nums dark:text-white/45"
                            />
                        </li>
                    ))}
                </ul>
            )}
        </details>
    );
}

const URGENCY_RANK: Record<string, number> = { CRITICAL: 0, URGENT: 1, ROUTINE: 2 };

/**
 * A CRITICAL request buried under two ROUTINE ones defeats the point of color-coding
 * it — staff scan top to bottom, not the whole list. Ties keep the server's own order
 * (newest first), which is the only ordering `GET /portal/requests` promises.
 */
function sortByUrgency<T extends { urgency: string }>(requests: T[]): T[] {
    return [...requests].sort(
        (a, b) => (URGENCY_RANK[a.urgency] ?? 9) - (URGENCY_RANK[b.urgency] ?? 9),
    );
}
