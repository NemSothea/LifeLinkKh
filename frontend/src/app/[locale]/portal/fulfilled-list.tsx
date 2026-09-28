'use client';

import { useState, type CSSProperties } from 'react';
import { ChevronDown } from 'lucide-react';
import Pagination, { paginate } from '@/components/Pagination';
import RelativeTime from '@/components/RelativeTime';
import { IconCheck, IconDroplet } from '@/components/icons';

export type FulfilledRow = {
    id: string;
    patientBloodType: string;
    hospitalName: string | null;
    createdAt: string;
    unitsLabel: string;
};

const PAGE_SIZE = 10;

/**
 * Work already done, kept on screen instead of vanishing.
 *
 * Collapsed by default — the open list is the job; this is the receipt. Newest first, because the
 * question it answers is "did that confirmation go through", asked minutes after the confirmation.
 * Ten at a time: a busy month would otherwise be one very long scroll.
 */
export default function FulfilledList({
    rows,
    heading,
    emptyLabel,
}: {
    rows: FulfilledRow[];
    heading: string;
    emptyLabel: string;
}) {
    const newestFirst = [...rows].sort((a, b) => b.createdAt.localeCompare(a.createdAt));
    const [page, setPage] = useState(1);
    const { current, totalPages, visible } = paginate(newestFirst, page, PAGE_SIZE);

    return (
        <details data-testid="portal-fulfilled" className="group mt-10">
            <summary className="flex min-h-11 cursor-pointer list-none items-center gap-2 rounded-xl text-sm font-semibold text-foreground/80 select-none focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-none">
                <ChevronDown
                    className="size-5 transition-transform duration-200 group-open:rotate-180"
                    aria-hidden="true"
                />
                <IconCheck className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
                {heading}
                <span className="tabular-nums">({newestFirst.length})</span>
            </summary>

            {newestFirst.length === 0 ? (
                <p
                    data-testid="portal-fulfilled-empty"
                    className="mt-3 text-sm text-muted-foreground"
                >
                    {emptyLabel}
                </p>
            ) : (
                <>
                    <ul className="mt-3 flex flex-col gap-2">
                        {visible.map((row, index) => (
                            <li
                                key={row.id}
                                data-testid={`portal-fulfilled-${row.id}`}
                                style={{ '--i': index } as CSSProperties}
                                className="animate-rise flex flex-wrap items-center gap-3 rounded-xl border border-border bg-card px-4 py-3 text-sm"
                            >
                                <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-emerald-600/10 text-xs font-bold text-emerald-700 dark:text-emerald-400">
                                    <IconDroplet className="mr-0.5 -ml-0.5 h-3 w-3 opacity-70" />
                                    {row.patientBloodType}
                                </span>
                                <span className="text-foreground/75">{row.unitsLabel}</span>
                                {row.hospitalName ? (
                                    <span className="text-muted-foreground">
                                        {row.hospitalName}
                                    </span>
                                ) : null}
                                <RelativeTime
                                    iso={row.createdAt}
                                    className="ml-auto text-xs text-muted-foreground tabular-nums"
                                />
                            </li>
                        ))}
                    </ul>
                    <div className="mt-4">
                        <Pagination
                            page={current}
                            totalPages={totalPages}
                            total={newestFirst.length}
                            pageSize={PAGE_SIZE}
                            onChange={setPage}
                            testIdPrefix="fulfilled-page"
                        />
                    </div>
                </>
            )}
        </details>
    );
}
