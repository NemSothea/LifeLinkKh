'use client';

import { useState } from 'react';
import EmptyState from '@/components/EmptyState';
import RelativeTime from '@/components/RelativeTime';
import type { PortalRequest } from '@/lib/api/portal';
import type { PublicRequest } from '@/lib/api/board';
import ConfirmDonationForm from './confirm-donation-form';
import {
    IconAlertTriangle,
    IconBell,
    IconBuilding,
    IconCheck,
    IconChevron,
    IconDroplet,
    IconInbox,
    IconSearch,
} from '@/components/icons';

/**
 * A request row as this list renders it, from **either** source, plus its
 * already-interpolated "N unit(s) needed" string — computed server-side in `page.tsx`,
 * since a Client Component can't receive the `t()` function itself as a prop (functions
 * can't cross the server/client boundary).
 *
 * The union is the point. A public row's donors carry no `matchId` (DEC-009: the public
 * DTO omits the confirm-donation handle on purpose), so `matchId` is optional here and
 * every use of it has to say what happens when it is absent. Typing this as `PortalRequest`
 * and casting the public data to it — which is what the first version did — compiled fine
 * and shipped `key={undefined}` on every donor row of the public board.
 */
export type RequestViewModel = (PortalRequest | PublicRequest) & { unitsLabel: string };

type DonorViewModel = RequestViewModel['acceptedDonors'][number];

/**
 * Stable within one request's donor list. `matchId` when the caller is staff; otherwise the
 * moment they answered, which is unique per donor on a request because one donor can accept
 * a given request only once (`request_matches_unique_pair`).
 */
function donorKey(donor: DonorViewModel): string {
    return 'matchId' in donor ? donor.matchId : `${donor.respondedAt}-${donor.displayName}`;
}

type Copy = {
    noAcceptedDonors: string;
    donatedOnLabel: string;
    confirmDonationCta: string;
    dialogTitle: string;
    dialogBody: string;
    cancelCta: string;
    dialogConfirmCta: string;
    searchPlaceholder: string;
    noMatches: string;
    filterAll: string;
    filterCritical: string;
    filterUrgent: string;
    filterRoutine: string;
    pageLabel: string;
    unitsProgress: string;
    acceptedAtLabel: string;
};

/** Rows per page. Not a network page — the whole list is already in memory
 * (`page.tsx`'s single fetch); this only caps how much DOM a long list produces at
 * once. Page resets to 1 whenever the filter changes, so switching tabs never leaves
 * you stranded on a page number that no longer exists. */
const PAGE_SIZE = 15;

const URGENCY_STYLE: Record<string, string> = {
    CRITICAL:
        'bg-red-100 text-red-800 ring-1 ring-inset ring-red-300 dark:bg-red-950/60 dark:text-red-300 dark:ring-red-800',
    URGENT:
        'bg-amber-100 text-amber-800 ring-1 ring-inset ring-amber-300 dark:bg-amber-950/60 dark:text-amber-300 dark:ring-amber-800',
    ROUTINE:
        'bg-slate-100 text-slate-700 ring-1 ring-inset ring-slate-300 dark:bg-slate-800/60 dark:text-slate-300 dark:ring-slate-700',
};

/** The urgency enum is the API's word, not the reader's. The filter chips above the list have
 * been translated since the portal shipped; the badge on every card rendered the raw
 * `CRITICAL`/`URGENT`/`ROUTINE` instead, so the Khmer board — the default locale — printed one
 * English word on every row. Same copy keys as the chips, so the two can never disagree. */
export function urgencyLabel(urgency: string, copy: Copy): string {
    switch (urgency) {
        case 'CRITICAL':
            return copy.filterCritical;
        case 'URGENT':
            return copy.filterUrgent;
        case 'ROUTINE':
            return copy.filterRoutine;
        default:
            return urgency;
    }
}

export function UrgencyBadge({ urgency, label }: { urgency: string; label?: string }) {
    return (
        <span
            className={`rounded-full px-2.5 py-0.5 text-xs font-semibold tracking-wide uppercase ${
                URGENCY_STYLE[urgency] ?? URGENCY_STYLE.ROUTINE
            }`}
        >
            {label ?? urgency}
        </span>
    );
}

type UrgencyFilter = 'ALL' | 'CRITICAL' | 'URGENT' | 'ROUTINE';

/**
 * Search + urgency filter over the full open-requests list `page.tsx` already fetched —
 * a plain in-memory `.filter()`, not a re-fetch. The list is small (open requests, not
 * every request ever), so there's nothing here a network round-trip or a debounce would
 * improve; every keystroke just re-filters an array already in memory.
 */
export default function RequestList({
    requests,
    canConfirm,
    locale,
    copy,
}: {
    requests: RequestViewModel[];
    /**
     * False for a signed-out visitor reading the public board. The rows, the counts and the
     * donors are the same; only the write disappears. It is not the real control either —
     * `SecurityConfig` refuses the POST without a staff session regardless of what renders.
     */
    canConfirm: boolean;
    locale: string;
    copy: Copy;
}) {
    const [query, setQuery] = useState('');
    const [urgency, setUrgency] = useState<UrgencyFilter>('ALL');
    const [page, setPage] = useState(1);

    const filtered = requests.filter((request) => {
        if (urgency !== 'ALL' && request.urgency !== urgency) return false;
        if (query.trim() === '') return true;
        const q = query.toLowerCase();
        return (
            request.patientBloodType.toLowerCase().includes(q) ||
            (request.hospital?.name.toLowerCase().includes(q) ?? false)
        );
    });
    const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
    const currentPage = Math.min(page, totalPages);
    const visible = filtered.slice((currentPage - 1) * PAGE_SIZE, currentPage * PAGE_SIZE);

    function updateQuery(value: string) {
        setQuery(value);
        setPage(1);
    }

    function updateUrgency(value: UrgencyFilter) {
        setUrgency(value);
        setPage(1);
    }

    const filters: { value: UrgencyFilter; label: string }[] = [
        { value: 'ALL', label: copy.filterAll },
        { value: 'CRITICAL', label: copy.filterCritical },
        { value: 'URGENT', label: copy.filterUrgent },
        { value: 'ROUTINE', label: copy.filterRoutine },
    ];

    return (
        <div className="flex flex-col gap-4">
            <div className="flex flex-wrap items-center gap-3">
                <div className="relative min-w-[220px] flex-1">
                    <IconSearch className="pointer-events-none absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-black/40 dark:text-white/40" />
                    <input
                        type="text"
                        value={query}
                        onChange={(event) => updateQuery(event.target.value)}
                        placeholder={copy.searchPlaceholder}
                        data-testid="portal-search"
                        className="w-full rounded-full border border-black/10 bg-black/[0.02] py-2 pr-4 pl-9 text-sm focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:border-white/15 dark:bg-white/[0.04]"
                    />
                </div>
                <div className="flex items-center gap-1 rounded-full border border-black/10 p-1 dark:border-white/15">
                    {filters.map((f) => (
                        <button
                            key={f.value}
                            type="button"
                            data-testid={`portal-filter-${f.value.toLowerCase()}`}
                            onClick={() => updateUrgency(f.value)}
                            className={`rounded-full px-3 py-1 text-xs font-semibold tracking-wide uppercase transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand ${
                                urgency === f.value
                                    ? (URGENCY_STYLE[f.value] ?? 'bg-brand text-white')
                                    : 'text-black/50 hover:text-black dark:text-white/50 dark:hover:text-white'
                            }`}
                        >
                            {f.label}
                        </button>
                    ))}
                </div>
            </div>

            {filtered.length === 0 ? (
                <EmptyState icon={<IconInbox className="h-8 w-8" />} testId="portal-no-matches">
                    {copy.noMatches}
                </EmptyState>
            ) : (
                <>
                    <ul data-testid="portal-request-list" className="flex flex-col gap-4">
                        {visible.map((request) => (
                            <RequestRow
                                key={request.id}
                                request={request}
                                canConfirm={canConfirm}
                                locale={locale}
                                copy={copy}
                            />
                        ))}
                    </ul>
                    {totalPages > 1 ? (
                        <nav
                            aria-label={copy.pageLabel
                                .replace('{page}', String(currentPage))
                                .replace('{total}', String(totalPages))}
                            className="flex items-center justify-center gap-1"
                        >
                            <button
                                type="button"
                                data-testid="portal-page-prev"
                                disabled={currentPage === 1}
                                onClick={() => setPage(currentPage - 1)}
                                className="rounded-full px-3 py-1.5 text-sm font-medium text-black/70 transition-colors hover:bg-black/[0.03] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand disabled:pointer-events-none disabled:opacity-30 dark:text-white/70 dark:hover:bg-white/[0.05]"
                            >
                                <IconChevron className="h-4 w-4 rotate-90" />
                            </button>
                            {Array.from({ length: totalPages }, (_, i) => i + 1).map((n) => (
                                <button
                                    key={n}
                                    type="button"
                                    data-testid={`portal-page-${n}`}
                                    onClick={() => setPage(n)}
                                    aria-current={n === currentPage ? 'page' : undefined}
                                    className={`h-8 w-8 rounded-full text-sm font-medium tabular-nums transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand ${
                                        n === currentPage
                                            ? 'bg-brand text-white'
                                            : 'text-black/70 hover:bg-black/[0.03] dark:text-white/70 dark:hover:bg-white/[0.05]'
                                    }`}
                                >
                                    {n}
                                </button>
                            ))}
                            <button
                                type="button"
                                data-testid="portal-page-next"
                                disabled={currentPage === totalPages}
                                onClick={() => setPage(currentPage + 1)}
                                className="rounded-full px-3 py-1.5 text-sm font-medium text-black/70 transition-colors hover:bg-black/[0.03] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand disabled:pointer-events-none disabled:opacity-30 dark:text-white/70 dark:hover:bg-white/[0.05]"
                            >
                                <IconChevron className="h-4 w-4 -rotate-90" />
                            </button>
                        </nav>
                    ) : null}
                </>
            )}
        </div>
    );
}

/**
 * The row's one triage signal, and the reason the accepted count is a chip rather than a
 * bare number: "0" and "2" look identical at a glance down a list of fifty.
 *
 * Severity is `acceptedCount === 0` crossed with urgency, not elapsed minutes — the age
 * next to it already carries time, and a minutes threshold computed during render would
 * have the server and the browser disagreeing about which style to paint.
 */
function progressStyle(request: RequestViewModel): string {
    if (request.acceptedCount >= request.unitsNeeded) {
        return 'bg-emerald-600/10 text-emerald-700 dark:text-emerald-400';
    }
    if (request.acceptedCount > 0) {
        return 'bg-black/[0.04] text-black/70 dark:bg-white/10 dark:text-white/70';
    }
    switch (request.urgency) {
        case 'CRITICAL':
            return 'bg-red-100 text-red-800 dark:bg-red-950/60 dark:text-red-300';
        case 'URGENT':
            return 'bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300';
        default:
            return 'bg-black/[0.04] text-black/60 dark:bg-white/10 dark:text-white/60';
    }
}

function RequestRow({
    request,
    canConfirm,
    locale,
    copy,
}: {
    request: RequestViewModel;
    canConfirm: boolean;
    locale: string;
    copy: Copy;
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
                            <UrgencyBadge
                                urgency={request.urgency}
                                label={urgencyLabel(request.urgency, copy)}
                            />
                            <span className="text-sm text-black/60 dark:text-white/60">
                                {request.unitsLabel}
                            </span>
                            {/* How old the request is, live. Staff triage on elapsed
                                time before anything else — this was fetched on every row
                                and rendered on none. */}
                            <RelativeTime
                                iso={request.createdAt}
                                className="text-sm text-black/50 tabular-nums dark:text-white/50"
                            />
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
                        {/* Accepted against units needed, not a bare count: "2" reads as
                            done when the request wanted three. */}
                        <span
                            data-testid={`portal-request-${request.id}-progress`}
                            className={`flex items-center gap-1.5 rounded-full px-2.5 py-1 font-medium ${progressStyle(request)}`}
                        >
                            {request.acceptedCount === 0 ? (
                                <IconAlertTriangle className="h-4 w-4" />
                            ) : (
                                <IconCheck className="h-4 w-4" />
                            )}
                            {copy.unitsProgress
                                .replace('{accepted}', String(request.acceptedCount))
                                .replace('{needed}', String(request.unitsNeeded))}
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
                            {copy.noAcceptedDonors}
                        </p>
                    ) : (
                        <ul className="flex flex-col gap-3">
                            {request.acceptedDonors.map((donor) => (
                                <li
                                    key={donorKey(donor)}
                                    data-testid={`portal-donor-${donorKey(donor)}`}
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
                                            {/* `respondedAt` was fetched for every donor
                                                and rendered for none. Staff coordinating
                                                arrivals need to see who answered an hour
                                                ago and still has not turned up. */}
                                            <span className="block text-xs text-black/45 dark:text-white/45">
                                                {copy.acceptedAtLabel}{' '}
                                                <RelativeTime iso={donor.respondedAt} />
                                            </span>
                                        </span>
                                    </div>
                                    {canConfirm && 'matchId' in donor ? (
                                    <div className="flex flex-wrap items-end gap-2">
                                        <ConfirmDonationForm
                                            requestId={request.id}
                                            matchId={donor.matchId}
                                            donorName={donor.displayName}
                                            locale={locale}
                                            copy={{
                                                donatedOnLabel: copy.donatedOnLabel,
                                                confirmDonationCta: copy.confirmDonationCta,
                                                dialogTitle: copy.dialogTitle,
                                                dialogBody: copy.dialogBody,
                                                cancelCta: copy.cancelCta,
                                                dialogConfirmCta: copy.dialogConfirmCta,
                                            }}
                                        />
                                    </div>
                                    ) : null}
                                </li>
                            ))}
                        </ul>
                    )}
                </div>
            </details>
        </li>
    );
}
