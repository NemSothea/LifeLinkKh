import { getTranslations } from 'next-intl/server';
import Link from 'next/link';
import LanguageSwitcher from '@/components/LanguageSwitcher';
import { portalRole } from '@/lib/api/dev-auth';
import { listOpenRequests, type PortalRequest } from '@/lib/api/portal';
import ConfirmDonationForm from './confirm-donation-form';
import {
    IconAlertTriangle,
    IconBell,
    IconBuilding,
    IconCheck,
    IconChevron,
    IconDroplet,
    IconInbox,
} from './icons';

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
                <ul data-testid="portal-request-list" className="flex flex-col gap-4">
                    {requests.map((request) => (
                        <RequestRow key={request.id} request={request} locale={locale} t={t} />
                    ))}
                </ul>
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

function EmptyState({
    icon,
    children,
    testId,
}: {
    icon: React.ReactNode;
    children: React.ReactNode;
    testId: string;
}) {
    return (
        <div
            data-testid={testId}
            className="flex flex-col items-center gap-3 rounded-2xl border border-dashed border-black/15 py-16 text-center text-black/50 dark:border-white/15 dark:text-white/50"
        >
            {icon}
            <p>{children}</p>
        </div>
    );
}

const URGENCY_STYLE: Record<string, string> = {
    CRITICAL:
        'bg-red-100 text-red-800 ring-1 ring-inset ring-red-300 dark:bg-red-950/60 dark:text-red-300 dark:ring-red-800',
    URGENT:
        'bg-amber-100 text-amber-800 ring-1 ring-inset ring-amber-300 dark:bg-amber-950/60 dark:text-amber-300 dark:ring-amber-800',
    ROUTINE:
        'bg-slate-100 text-slate-700 ring-1 ring-inset ring-slate-300 dark:bg-slate-800/60 dark:text-slate-300 dark:ring-slate-700',
};

function UrgencyBadge({ urgency }: { urgency: string }) {
    return (
        <span
            className={`rounded-full px-2.5 py-0.5 text-xs font-semibold tracking-wide uppercase ${
                URGENCY_STYLE[urgency] ?? URGENCY_STYLE.ROUTINE
            }`}
        >
            {urgency}
        </span>
    );
}

async function RequestRow({
    request,
    locale,
    t,
}: {
    request: PortalRequest;
    locale: string;
    t: Awaited<ReturnType<typeof getTranslations>>;
}) {
    const isCritical = request.urgency === 'CRITICAL';

    return (
        <li
            data-testid={`portal-request-${request.id}`}
            className={`overflow-hidden rounded-2xl border bg-white shadow-sm transition-shadow hover:shadow-md dark:bg-white/[0.03] ${
                isCritical
                    ? 'border-red-300 border-l-4 border-l-brand dark:border-red-800'
                    : 'border-black/10 dark:border-white/15'
            }`}
        >
            <details className="group">
                <summary className="flex cursor-pointer list-none items-center gap-4 p-5 select-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand">
                    <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-brand text-sm font-bold text-white shadow-inner">
                        <IconDroplet className="mr-0.5 -ml-1 h-3.5 w-3.5 opacity-70" />
                        {request.patientBloodType}
                    </span>

                    <div className="min-w-0 flex-1">
                        <div className="flex flex-wrap items-center gap-2">
                            <UrgencyBadge urgency={request.urgency} />
                            <span className="text-sm text-black/60 dark:text-white/60">
                                {t('unitsNeeded', { count: request.unitsNeeded })}
                            </span>
                        </div>
                        {request.hospital ? (
                            <p className="mt-1 flex items-center gap-1.5 text-sm font-medium text-black/80 dark:text-white/80">
                                <IconBuilding className="h-4 w-4 text-black/40 dark:text-white/40" />
                                {request.hospital.name}
                            </p>
                        ) : null}
                    </div>

                    <div className="hidden shrink-0 items-center gap-4 text-sm tabular-nums sm:flex">
                        <span className="flex items-center gap-1.5 text-black/60 dark:text-white/60">
                            <IconBell className="h-4 w-4" />
                            {request.alertedCount}
                        </span>
                        <span className="flex items-center gap-1.5 font-medium text-emerald-700 dark:text-emerald-400">
                            <IconCheck className="h-4 w-4" />
                            {request.acceptedCount}
                        </span>
                    </div>

                    <IconChevron className="h-5 w-5 shrink-0 text-black/40 transition-transform duration-200 group-open:rotate-180 dark:text-white/40" />
                </summary>

                <div className="border-t border-black/10 bg-black/[0.015] p-5 dark:border-white/10 dark:bg-white/[0.02]">
                    {request.acceptedDonors.length === 0 ? (
                        <p
                            data-testid={`portal-request-${request.id}-no-donors`}
                            className="text-sm text-black/50 dark:text-white/50"
                        >
                            {t('noAcceptedDonors')}
                        </p>
                    ) : (
                        <ul className="flex flex-col gap-3">
                            {request.acceptedDonors.map((donor) => (
                                <li
                                    key={donor.matchId}
                                    data-testid={`portal-donor-${donor.matchId}`}
                                    className="flex flex-col gap-3 rounded-xl border border-black/10 bg-white p-3 sm:flex-row sm:items-center sm:justify-between dark:border-white/10 dark:bg-white/[0.04]"
                                >
                                    <div className="flex items-center gap-3">
                                        <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-black/10 text-xs font-semibold dark:bg-white/10">
                                            {donor.displayName.charAt(0).toUpperCase()}
                                        </span>
                                        <span className="text-sm">
                                            <span className="font-medium">{donor.displayName}</span>
                                            <span className="text-black/50 dark:text-white/50">
                                                {' · '}
                                                {donor.bloodType}
                                                {donor.districtName ? ` · ${donor.districtName}` : ''}
                                            </span>
                                        </span>
                                    </div>
                                    <div className="flex flex-wrap items-end gap-2">
                                        <ConfirmDonationForm
                                            requestId={request.id}
                                            matchId={donor.matchId}
                                            donorName={donor.displayName}
                                            locale={locale}
                                            copy={{
                                                donatedOnLabel: t('donatedOnLabel'),
                                                confirmDonationCta: t('confirmDonationCta'),
                                                dialogTitle: t('confirmDialogTitle'),
                                                dialogBody: t('confirmDialogBody'),
                                                cancelCta: t('cancelCta'),
                                                dialogConfirmCta: t('confirmDialogCta'),
                                            }}
                                        />
                                    </div>
                                </li>
                            ))}
                        </ul>
                    )}
                </div>
            </details>
        </li>
    );
}
