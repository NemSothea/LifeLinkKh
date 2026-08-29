import { getTranslations } from 'next-intl/server';
import Link from 'next/link';
import EmptyState from '@/components/EmptyState';
import LanguageSwitcher from '@/components/LanguageSwitcher';
import { portalRole } from '@/lib/api/dev-auth';
import { listOpenRequests, type PortalRequest } from '@/lib/api/portal';
import { IconAlertTriangle, IconCheck, IconInbox } from './icons';
import RequestList, { type RequestViewModel } from './request-list';

/**
 * FR-PORTAL-001, trimmed by DEC-004 to one page: a table of open requests, each
 * expandable to its accepted donors, each donor row carrying the one write this page
 * has — confirm a donation.
 *
 * A Server Component, like the M2 health page: `listOpenRequests()` runs on the Next
 * server, never in the browser, which is also where `PORTAL_DEV_JWT` has to stay.
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
    const result = await listOpenRequests();
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
                    {portalRole() === 'ADMIN' ? (
                        <Link
                            href={`/${locale}/portal/admin`}
                            data-testid="manage-staff-link"
                            className="text-sm font-medium text-black/60 underline-offset-4 hover:underline dark:text-white/60"
                        >
                            {t('manageStaffCta')}
                        </Link>
                    ) : null}
                    <LanguageSwitcher />
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
                    locale={locale}
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
                        pageLabel: t('pageLabel'),
                    }}
                />
            )}
        </main>
    );
}

const URGENCY_RANK: Record<string, number> = { CRITICAL: 0, URGENT: 1, ROUTINE: 2 };

/**
 * A CRITICAL request buried under two ROUTINE ones defeats the point of color-coding
 * it — staff scan top to bottom, not the whole list. Ties keep the server's own order
 * (newest first), which is the only ordering `GET /portal/requests` promises.
 */
function sortByUrgency(requests: PortalRequest[]): PortalRequest[] {
    return [...requests].sort(
        (a, b) => (URGENCY_RANK[a.urgency] ?? 9) - (URGENCY_RANK[b.urgency] ?? 9),
    );
}
