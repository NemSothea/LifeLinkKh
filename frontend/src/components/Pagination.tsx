'use client';

import { useTranslations } from 'next-intl';
import { ChevronLeft, ChevronRight } from 'lucide-react';

/** Page numbers to show: always the first and last, the current one and its neighbours, gaps as null. */
function pageItems(current: number, total: number): (number | null)[] {
    if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
    const items: (number | null)[] = [1];
    const start = Math.max(2, current - 1);
    const end = Math.min(total - 1, current + 1);
    if (start > 2) items.push(null);
    for (let n = start; n <= end; n++) items.push(n);
    if (end < total - 1) items.push(null);
    items.push(total);
    return items;
}

/** Slices `items` for `page` (1-based, clamped). */
export function paginate<T>(items: T[], page: number, pageSize: number) {
    const totalPages = Math.max(1, Math.ceil(items.length / pageSize));
    const current = Math.min(Math.max(1, page), totalPages);
    return {
        current,
        totalPages,
        visible: items.slice((current - 1) * pageSize, current * pageSize),
    };
}

/**
 * One pagination control for every list in the portal: "Showing 1–15 of 40" always (so the size
 * of the list is never a surprise), and 44px previous / page / next buttons once there is more than
 * one page. Long runs collapse to 1 … 4 5 6 … 12.
 */
export default function Pagination({
    page,
    totalPages,
    total,
    pageSize,
    onChange,
    testIdPrefix,
}: {
    page: number;
    totalPages: number;
    total: number;
    pageSize: number;
    onChange: (page: number) => void;
    /** `portal-page` gives `portal-page-prev`, `portal-page-2`, `portal-page-next`. */
    testIdPrefix: string;
}) {
    const t = useTranslations('portal');
    if (total === 0) return null;
    const from = (page - 1) * pageSize + 1;
    const to = Math.min(total, page * pageSize);
    const button =
        'flex size-11 items-center justify-center rounded-full text-sm font-medium tabular-nums transition-colors focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-none disabled:pointer-events-none disabled:opacity-30';

    return (
        <div className="flex flex-col items-center gap-2 sm:flex-row sm:justify-between">
            <p
                className="text-sm text-muted-foreground tabular-nums"
                data-testid={`${testIdPrefix}-summary`}
            >
                {t('showingLabel', { from, to, total })}
            </p>
            {totalPages > 1 ? (
                <nav
                    aria-label={t('pageLabel', { page, total: totalPages })}
                    className="flex items-center gap-1"
                >
                    <button
                        type="button"
                        data-testid={`${testIdPrefix}-prev`}
                        aria-label={t('previousPage')}
                        disabled={page === 1}
                        onClick={() => onChange(page - 1)}
                        className={`${button} text-foreground hover:bg-secondary`}
                    >
                        <ChevronLeft className="size-5" aria-hidden="true" />
                    </button>
                    {pageItems(page, totalPages).map((n, i) =>
                        n == null ? (
                            <span
                                key={`gap-${i}`}
                                className="w-6 text-center text-muted-foreground"
                                aria-hidden="true"
                            >
                                …
                            </span>
                        ) : (
                            <button
                                key={n}
                                type="button"
                                data-testid={`${testIdPrefix}-${n}`}
                                aria-label={t('goToPage', { page: n })}
                                aria-current={n === page ? 'page' : undefined}
                                onClick={() => onChange(n)}
                                className={`${button} ${
                                    n === page
                                        ? 'bg-primary text-primary-foreground'
                                        : 'text-foreground hover:bg-secondary'
                                }`}
                            >
                                {n}
                            </button>
                        ),
                    )}
                    <button
                        type="button"
                        data-testid={`${testIdPrefix}-next`}
                        aria-label={t('nextPage')}
                        disabled={page === totalPages}
                        onClick={() => onChange(page + 1)}
                        className={`${button} text-foreground hover:bg-secondary`}
                    >
                        <ChevronRight className="size-5" aria-hidden="true" />
                    </button>
                </nav>
            ) : null}
        </div>
    );
}
