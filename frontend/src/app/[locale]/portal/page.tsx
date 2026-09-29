import { getTranslations } from 'next-intl/server';
import Notice from '@/components/Notice';
import PillLink from '@/components/PillLink';
import AutoRefresh from '@/components/AutoRefresh';
import HealthStatus from '@/components/HealthStatus';
import { getHealth } from '@/lib/api/health';
import EmptyState from '@/components/EmptyState';
import { hasPortalSession, portalDisplayName, portalRole } from '@/lib/api/session';
import AccountMenu from '@/components/AccountMenu';
import { listPublicRequests } from '@/lib/api/board';
import {
    listFulfilledRequests,
    listOpenRequests,
    listPendingRequests,
    listReports,
    type RequestReport,
    type PendingRequest,
    type PortalRequest,
} from '@/lib/api/portal';
import { IconAlertTriangle, IconDroplet, IconInbox, IconLogIn } from '@/components/icons';
import PendingReviewList from './pending-review-list';
import RequestList, { type RequestViewModel } from './request-list';
import PageHeader from '@/components/PageHeader';
import PortalTabs from '@/components/PortalTabs';
import FulfilledList from './fulfilled-list';
import { adminNotifications } from '@/lib/notifications';

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
    searchParams: Promise<{
        confirmError?: string;
        confirmed?: string;
        reviewed?: string;
        reviewError?: string;
    }>;
}) {
    const { locale } = await params;
    const { confirmError, confirmed, reviewed, reviewError } = await searchParams;
    const t = await getTranslations('portal');
    const isAdmin = await hasPortalSession();
    const [role, displayName] = isAdmin
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
    // DEC-015: the review queue is the admin's first job, so it is read with the rest.
    const [result, fulfilledResult, pendingResult, reportsResult] = isAdmin
        ? await Promise.all([
              listOpenRequests(),
              listFulfilledRequests(),
              listPendingRequests(),
              listReports(),
          ])
        : [
              await listPublicRequests(),
              { ok: false } as const,
              { ok: false } as const,
              { ok: false } as const,
          ];
    // DEC-019: donors' reports, read with the review queue because acting on them is review work.
    const reports: RequestReport[] = reportsResult.ok ? reportsResult.data : [];
    const health = isAdmin ? await getHealth() : null;
    const fulfilled = fulfilledResult.ok ? fulfilledResult.data : [];
    const pending: PendingRequest[] = pendingResult.ok ? pendingResult.data : [];
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
            <PageHeader
                locale={locale}
                title={t('title')}
                notifications={
                    isAdmin && result.ok
                        ? adminNotifications(locale, pending, result.data as PortalRequest[])
                        : undefined
                }
                account={
                    isAdmin ? (
                        <AccountMenu locale={locale} displayName={displayName} role={role} />
                    ) : undefined
                }
            >
                <div className="flex flex-wrap items-center justify-between gap-3">
                    {isAdmin ? <PortalTabs locale={locale} active="requests" /> : null}
                    {result.ok ? (
                        <div
                            data-testid="portal-summary"
                            className="flex items-center gap-2 text-sm tabular-nums"
                        >
                            <span className="flex min-h-9 items-center gap-1.5 rounded-full bg-secondary px-3.5">
                                <strong className="text-base">{requests.length}</strong>
                                <span className="text-muted-foreground">{t('openLabel')}</span>
                            </span>
                            {criticalCount > 0 ? (
                                <span className="flex min-h-9 items-center gap-1.5 rounded-full bg-brand/10 px-3.5 font-medium text-brand">
                                    <span className="relative flex h-2 w-2">
                                        <span className="absolute inline-flex h-full w-full motion-safe:animate-ping rounded-full bg-brand opacity-75" />
                                        <span className="relative inline-flex h-2 w-2 rounded-full bg-brand" />
                                    </span>
                                    <strong className="text-base">{criticalCount}</strong>
                                    {t('criticalLabel')}
                                </span>
                            ) : null}
                        </div>
                    ) : null}
                    {isAdmin ? null : (
                        // The only thing a visitor is offered. Not a wall in front of the
                        // board — a door beside it, for the people who have a key.
                        <PillLink
                            href={`/${locale}/sign-in`}
                            icon={<IconLogIn />}
                            testId="staff-sign-in-link"
                        >
                            {t('staffSignInCta')}
                        </PillLink>
                    )}
                </div>
            </PageHeader>

            {/* DEC-019: a visitor reading the board is a family or a would-be donor. Both need
                to hear "never pay", and where to learn how getting blood actually works. */}
            {isAdmin ? null : (
                <div
                    data-testid="board-guidance"
                    className="mb-6 flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-emerald-300 bg-emerald-50 px-4 py-3 text-sm text-emerald-900 dark:border-emerald-900 dark:bg-emerald-950/50 dark:text-emerald-200"
                >
                    <p className="min-w-0 flex-1">{t('moneyNotice')}</p>
                    <PillLink href={`/${locale}/getting-blood`} icon={<IconDroplet />}>
                        {t('guideLink')}
                    </PillLink>
                </div>
            )}

            {result.ok ? (
                <div className="mb-6 flex flex-wrap items-center justify-end gap-x-6 gap-y-2">
                    {/* The API health line lives here, for the admin — a donor has no use for it. */}
                    {health ? (
                        <HealthStatus
                            reachable={health.ok}
                            status={health.ok ? health.data.status : undefined}
                        />
                    ) : null}
                    <AutoRefresh intervalMs={isAdmin ? 30_000 : 120_000} />
                </div>
            ) : null}

            {confirmed ? (
                <Notice tone="success" testId="confirm-donation-success" className="mb-6">
                    {t('confirmSuccess', { name: confirmed })}
                </Notice>
            ) : null}

            {confirmError ? (
                <Notice tone="error" testId="confirm-donation-error" className="mb-6">
                    {t('confirmFailed')}
                </Notice>
            ) : null}

            {reviewed ? (
                <Notice tone="success" testId="review-success" className="mb-6">
                    {reviewed === 'approved' ? t('reviewApproved') : t('reviewRejected')}
                </Notice>
            ) : null}

            {reviewError ? (
                <Notice tone="error" testId="review-error" className="mb-6">
                    {reviewError === 'gone' ? t('reviewGone') : t('reviewFailed')}
                </Notice>
            ) : null}

            {reports.length > 0 ? (
                <section
                    data-testid="portal-reports"
                    className="mb-8 rounded-2xl border border-amber-300 bg-amber-50 p-5 text-amber-950 dark:border-amber-900 dark:bg-amber-950/40 dark:text-amber-100"
                >
                    <h2 className="flex items-center gap-2 text-lg font-semibold">
                        <IconAlertTriangle className="h-5 w-5 shrink-0" />
                        {t('reportsHeading')}
                        <span className="rounded-full bg-amber-200/70 px-2 text-sm tabular-nums dark:bg-amber-900/60">
                            {reports.length}
                        </span>
                    </h2>
                    <p className="mt-1 mb-4 text-sm opacity-85">{t('reportsHint')}</p>
                    <ul className="flex flex-col gap-3">
                        {reports.map((report) => (
                            <li
                                key={report.id}
                                className="rounded-xl border border-amber-200 bg-white/70 p-3 text-sm dark:border-amber-900 dark:bg-black/20"
                            >
                                <div className="flex flex-wrap items-baseline justify-between gap-2">
                                    <strong>
                                        {t(`reportReason.${report.reason}` as 'reportReason.OTHER')}
                                    </strong>
                                    <time
                                        dateTime={report.createdAt}
                                        className="text-xs opacity-75 tabular-nums"
                                    >
                                        {report.createdAt
                                            ? new Date(report.createdAt).toLocaleString(
                                                  locale === 'km' ? 'km-KH' : 'en-GB',
                                                  { timeZone: 'Asia/Phnom_Penh' },
                                              )
                                            : ''}
                                    </time>
                                </div>
                                <p className="mt-1 opacity-85">
                                    {report.request
                                        ? `${report.request.patientBloodType} · ${report.request.hospitalName ?? report.requestId} · ${report.request.status}`
                                        : t('reportRequestGone')}
                                </p>
                                <p className="mt-1 italic opacity-85">
                                    {report.note ?? t('reportNoNote')}
                                </p>
                            </li>
                        ))}
                    </ul>
                </section>
            ) : null}

            {pending.length > 0 ? (
                <PendingReviewList
                    requests={pending}
                    locale={locale}
                    copy={{
                        heading: t('pendingHeading'),
                        hint: t('pendingHint'),
                        contactLabel: t('pendingContactLabel'),
                        approveCta: t('approveCta'),
                        rejectCta: t('rejectCta'),
                        approveDialogTitle: t('approveDialogTitle'),
                        approveDialogBody: t('approveDialogBody'),
                        approveDialogCta: t('approveDialogCta'),
                        rejectDialogTitle: t('rejectDialogTitle'),
                        rejectDialogBody: t('rejectDialogBody'),
                        rejectReasonLabel: t('rejectReasonLabel'),
                        rejectReasonPlaceholder: t('rejectReasonPlaceholder'),
                        rejectDialogCta: t('rejectDialogCta'),
                        cancelCta: t('cancelCta'),
                        urgency: {
                            CRITICAL: t('filterCritical'),
                            URGENT: t('filterUrgent'),
                            ROUTINE: t('filterRoutine'),
                        },
                        // Interpolated here: a Client Component cannot receive `t()` itself.
                        unitsLabel: Object.fromEntries(
                            pending.map((r) => [r.id, t('unitsNeeded', { count: r.unitsNeeded })]),
                        ),
                    }}
                />
            ) : null}

            {!result.ok ? (
                <EmptyState
                    icon={<IconAlertTriangle className="h-8 w-8" />}
                    testId="portal-unreachable"
                >
                    {t('unreachable')}
                </EmptyState>
            ) : requests.length === 0 ? (
                <EmptyState icon={<IconInbox className="h-8 w-8" />} testId="portal-empty">
                    {t('empty')}
                </EmptyState>
            ) : (
                <RequestList
                    requests={requestViewModels}
                    canConfirm={isAdmin}
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

            {isAdmin && result.ok ? (
                <FulfilledList
                    rows={fulfilled.map((request) => ({
                        id: request.id,
                        patientBloodType: request.patientBloodType,
                        hospitalName: request.hospital?.name ?? null,
                        createdAt: request.createdAt,
                        unitsLabel: t('unitsNeeded', { count: request.unitsNeeded }),
                    }))}
                    heading={t('fulfilledHeading')}
                    emptyLabel={t('fulfilledEmpty')}
                />
            ) : null}
        </main>
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
