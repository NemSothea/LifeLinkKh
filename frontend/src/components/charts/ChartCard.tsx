import type { ReactNode } from 'react';
import type { Series } from './BarChart';
import ExportImageButton from './ExportImageButton';

/**
 * A chart's frame: title, optional note, legend (always, for two or more series — so identity is
 * never colour alone), the chart, and a collapsible table of the same numbers.
 */
export default function ChartCard({
    title,
    note,
    series,
    table,
    tableLabel,
    children,
    testId,
    exportImage,
}: {
    title: string;
    note?: string;
    series?: Series[];
    table?: { head: string[]; rows: (string | number)[][] };
    tableLabel: string;
    children: ReactNode;
    testId?: string;
    /** Adds a "download image" button; the legend is drawn into the PNG. */
    exportImage?: {
        fileName: string;
        label: string;
        legend?: { label: string; color: string; value?: string }[];
    };
}) {
    return (
        <section
            data-chart-card
            data-testid={testId}
            className="animate-rise flex min-w-0 flex-col gap-4 rounded-2xl border border-border bg-card p-4 text-card-foreground shadow-sm sm:p-5"
        >
            <div className="flex flex-wrap items-start justify-between gap-x-4 gap-y-2">
                <div>
                    <h2 className="text-base font-semibold">{title}</h2>
                    {note ? <p className="mt-0.5 text-xs text-muted-foreground">{note}</p> : null}
                </div>
                <div className="flex items-start gap-3">
                    {series && series.length > 1 ? (
                        <ul className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
                            {series.map((s) => (
                                <li key={s.key} className="flex items-center gap-1.5">
                                    <span
                                        className="size-2.5 rounded-sm"
                                        style={{ background: s.color }}
                                        aria-hidden="true"
                                    />
                                    {s.label}
                                </li>
                            ))}
                        </ul>
                    ) : null}
                    {exportImage ? (
                        <ExportImageButton
                            title={title}
                            fileName={exportImage.fileName}
                            label={exportImage.label}
                            legend={
                                exportImage.legend ??
                                (series && series.length > 1
                                    ? series.map((s) => ({ label: s.label, color: s.color }))
                                    : [])
                            }
                        />
                    ) : null}
                </div>
            </div>
            {children}
            {table ? (
                <details className="group text-sm">
                    <summary className="flex min-h-11 cursor-pointer list-none items-center text-sm font-medium text-muted-foreground hover:text-foreground">
                        {tableLabel}
                    </summary>
                    <div className="overflow-x-auto">
                        <table className="w-full text-left tabular-nums">
                            <thead>
                                <tr className="border-b border-border text-muted-foreground">
                                    {table.head.map((h) => (
                                        <th key={h} className="py-2 pr-4 font-medium">
                                            {h}
                                        </th>
                                    ))}
                                </tr>
                            </thead>
                            <tbody>
                                {table.rows.map((row, i) => (
                                    <tr key={i} className="border-b border-border/60 last:border-0">
                                        {row.map((cell, j) => (
                                            <td key={j} className="py-1.5 pr-4">
                                                {cell}
                                            </td>
                                        ))}
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </details>
            ) : null}
        </section>
    );
}
