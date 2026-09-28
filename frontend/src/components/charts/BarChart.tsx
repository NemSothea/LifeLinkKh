'use client';

import { useEffect, useRef, useState, type CSSProperties } from 'react';

export type Series = { key: string; label: string; color: string };
export type Row = { key: string; label: string; values: Record<string, number> };

const HEIGHT = 240;
const PAD = { top: 12, right: 8, bottom: 28, left: 36 };

/** A round axis: whole-number steps of 1, 2 or 5 × 10ⁿ, at most five of them. */
function niceScale(value: number): { max: number; ticks: number[] } {
    const target = Math.max(1, value);
    const pow = 10 ** Math.floor(Math.log10(target));
    const step = [0.1, 0.2, 0.5, 1, 2, 5, 10]
        .map((m) => Math.max(1, m * pow))
        .find((st) => Math.ceil(target / st) <= 5)!;
    const max = Math.ceil(target / step) * step;
    return { max, ticks: Array.from({ length: max / step + 1 }, (_, i) => i * step) };
}

/**
 * Vertical bars, stacked or grouped. Thin marks with 4px rounded tops anchored to the baseline,
 * a 2px surface gap between segments, a recessive grid, and a hover tooltip over the whole column
 * (the hit target is the column band, not the sliver of a small bar). One y-axis only.
 */
export default function BarChart({
    rows,
    series,
    mode,
    ariaLabel,
    labelEvery,
}: {
    rows: Row[];
    series: Series[];
    mode: 'stacked' | 'grouped';
    ariaLabel: string;
    /** Label every Nth column on the x-axis (a 30-day range cannot fit 30 labels on a phone). */
    labelEvery?: number;
}) {
    const ref = useRef<HTMLDivElement>(null);
    const [width, setWidth] = useState(640);
    const [hover, setHover] = useState<number | null>(null);

    useEffect(() => {
        const el = ref.current;
        if (!el) return;
        const observer = new ResizeObserver(([entry]) =>
            setWidth(Math.max(280, entry.contentRect.width)),
        );
        observer.observe(el);
        return () => observer.disconnect();
    }, []);

    const totals = rows.map((r) =>
        mode === 'stacked'
            ? series.reduce((sum, s) => sum + (r.values[s.key] ?? 0), 0)
            : Math.max(0, ...series.map((s) => r.values[s.key] ?? 0)),
    );
    const { max, ticks } = niceScale(Math.max(0, ...totals));
    const plotW = width - PAD.left - PAD.right;
    const plotH = HEIGHT - PAD.top - PAD.bottom;
    const band = plotW / Math.max(1, rows.length);
    const barW = Math.max(2, Math.min(40, band * (mode === 'grouped' ? 0.7 : 0.62)));
    const y = (v: number) => PAD.top + plotH - (v / max) * plotH;

    const hovered = hover == null ? null : rows[hover];
    const tipLeft = hover == null ? 0 : PAD.left + band * (hover + 0.5);

    return (
        <div ref={ref} className="relative w-full" onMouseLeave={() => setHover(null)}>
            <svg
                data-chart
                width={width}
                height={HEIGHT}
                role="img"
                aria-label={ariaLabel}
                className="block"
            >
                {ticks.map((t) => (
                    <g key={t}>
                        <line
                            x1={PAD.left}
                            x2={width - PAD.right}
                            y1={y(t)}
                            y2={y(t)}
                            stroke="var(--chart-grid)"
                            strokeWidth={1}
                        />
                        <text
                            x={PAD.left - 8}
                            y={y(t)}
                            dy="0.32em"
                            textAnchor="end"
                            className="fill-muted-foreground text-[11px] tabular-nums"
                        >
                            {t}
                        </text>
                    </g>
                ))}

                {rows.map((row, i) => {
                    const cx = PAD.left + band * (i + 0.5);
                    const every =
                        labelEvery ?? Math.max(1, Math.ceil(rows.length / Math.floor(plotW / 44)));
                    const label = i % every === 0 ? row.label : '';
                    let stackTop = 0;
                    return (
                        <g
                            key={row.key}
                            opacity={hover == null || hover === i ? 1 : 0.45}
                            className="transition-opacity duration-200"
                        >
                            {series.map((s, si) => {
                                const v = row.values[s.key] ?? 0;
                                if (v <= 0) return null;
                                if (mode === 'stacked') {
                                    const y0 = y(stackTop);
                                    stackTop += v;
                                    const y1 = y(stackTop);
                                    const isTop = series
                                        .slice(si + 1)
                                        .every((n) => (row.values[n.key] ?? 0) <= 0);
                                    const h = Math.max(1, y0 - y1 - (stackTop - v > 0 ? 2 : 0));
                                    return (
                                        <rect
                                            key={s.key}
                                            x={cx - barW / 2}
                                            y={y1}
                                            width={barW}
                                            height={h}
                                            rx={isTop ? Math.min(4, barW / 2) : 0}
                                            fill={s.color}
                                            className="animate-grow-y"
                                            style={{ '--i': i } as CSSProperties}
                                        />
                                    );
                                }
                                const gw = barW / series.length;
                                const x = cx - barW / 2 + gw * si;
                                return (
                                    <rect
                                        key={s.key}
                                        x={x + 1}
                                        y={y(v)}
                                        width={Math.max(1, gw - 2)}
                                        height={Math.max(1, y(0) - y(v))}
                                        rx={Math.min(4, (gw - 2) / 2)}
                                        fill={s.color}
                                        className="animate-grow-y"
                                        style={{ '--i': i } as CSSProperties}
                                    />
                                );
                            })}
                            {label ? (
                                <text
                                    x={cx}
                                    y={HEIGHT - 8}
                                    textAnchor="middle"
                                    className="fill-muted-foreground text-[11px] tabular-nums"
                                >
                                    {label}
                                </text>
                            ) : null}
                            {/* The hit target: the whole column band. */}
                            <rect
                                x={cx - band / 2}
                                y={PAD.top}
                                width={band}
                                height={plotH}
                                fill="transparent"
                                onMouseEnter={() => setHover(i)}
                                onClick={() => setHover(i)}
                            />
                        </g>
                    );
                })}
                <line
                    x1={PAD.left}
                    x2={width - PAD.right}
                    y1={y(0)}
                    y2={y(0)}
                    stroke="currentColor"
                    strokeOpacity={0.35}
                />
            </svg>

            {hovered ? (
                <div
                    key={hover}
                    role="status"
                    className="animate-pop pointer-events-none absolute top-2 z-10 min-w-36 -translate-x-1/2 rounded-xl border border-border bg-popover px-3 py-2 text-sm text-popover-foreground shadow-lg"
                    style={{ left: Math.min(Math.max(tipLeft, 80), width - 80) }}
                >
                    <p className="mb-1 font-semibold">{hovered.label}</p>
                    <ul className="flex flex-col gap-0.5">
                        {series.map((s) => (
                            <li key={s.key} className="flex items-center gap-2">
                                <span
                                    className="size-2.5 shrink-0 rounded-sm"
                                    style={{ background: s.color }}
                                    aria-hidden="true"
                                />
                                <span className="flex-1 text-muted-foreground">{s.label}</span>
                                <span className="font-medium tabular-nums">
                                    {hovered.values[s.key] ?? 0}
                                </span>
                            </li>
                        ))}
                    </ul>
                </div>
            ) : null}
        </div>
    );
}
