'use client';

import { useState, type CSSProperties } from 'react';

import type { Slice } from './slices';

const SIZE = 220;
const R = SIZE / 2;

function arc(start: number, end: number, outer: number, inner: number): string {
    // Rounded: server and browser trig differ in the last digits, which React reports as a
    // hydration mismatch. A hundredth of a pixel is invisible.
    const round = (n: number) => Math.round(n * 100) / 100;
    const pt = (a: number, r: number) => [round(R + r * Math.sin(a)), round(R - r * Math.cos(a))];
    const large = end - start > Math.PI ? 1 : 0;
    const [x1, y1] = pt(start, outer);
    const [x2, y2] = pt(end, outer);
    if (inner === 0) {
        return `M${R},${R} L${x1},${y1} A${outer},${outer} 0 ${large} 1 ${x2},${y2} Z`;
    }
    const [x3, y3] = pt(end, inner);
    const [x4, y4] = pt(start, inner);
    return `M${x1},${y1} A${outer},${outer} 0 ${large} 1 ${x2},${y2} L${x3},${y3} A${inner},${inner} 0 ${large} 0 ${x4},${y4} Z`;
}

/**
 * Pie or donut, with a legend beside it that carries every slice's count and share — so the reading
 * never depends on judging angles or on colour alone. A 2px surface gap separates slices; hovering
 * a slice or its legend row lifts that slice and dims the rest.
 */
export default function PieChart({
    slices,
    donut = false,
    centerLabel,
    ariaLabel,
    emptyLabel,
}: {
    slices: Slice[];
    donut?: boolean;
    /** Shown in a donut's hole under the total. */
    centerLabel?: string;
    ariaLabel: string;
    emptyLabel: string;
}) {
    const [hover, setHover] = useState<string | null>(null);
    const total = slices.reduce((sum, s) => sum + s.value, 0);
    if (total === 0) {
        return <p className="py-10 text-center text-sm text-muted-foreground">{emptyLabel}</p>;
    }
    const outer = R - 4;
    const inner = donut ? outer * 0.6 : 0;
    let angle = 0;

    return (
        // Side by side only when the card itself is wide (a container query, not the screen):
        // in a half-width card a legend beside the pie cut every name to "Nation…".
        <div className="@container w-full">
            <div className="flex flex-col items-center gap-5 @xl:flex-row @xl:items-center">
                <svg
                    data-chart
                    width={SIZE}
                    height={SIZE}
                    viewBox={`0 0 ${SIZE} ${SIZE}`}
                    role="img"
                    aria-label={ariaLabel}
                    className="shrink-0"
                >
                    <g className="animate-spin-in">
                        {slices.map((s) => {
                            const start = angle;
                            const sweep = (s.value / total) * Math.PI * 2;
                            angle += sweep;
                            // A lone slice is a full ring; an arc from 0 to 2π draws nothing.
                            const end = slices.length === 1 ? start + Math.PI * 2 - 0.0001 : angle;
                            const mid = start + sweep / 2;
                            const lift = hover === s.key ? 5 : 0;
                            return (
                                <path
                                    key={s.key}
                                    d={arc(start, end, outer, inner)}
                                    fill={s.color}
                                    stroke="var(--card)"
                                    strokeWidth={2}
                                    opacity={hover == null || hover === s.key ? 1 : 0.45}
                                    transform={`translate(${(Math.sin(mid) * lift).toFixed(2)} ${(-Math.cos(mid) * lift).toFixed(2)})`}
                                    className="cursor-pointer transition-[opacity,transform] duration-200"
                                    onMouseEnter={() => setHover(s.key)}
                                    onMouseLeave={() => setHover(null)}
                                    onClick={() => setHover(hover === s.key ? null : s.key)}
                                >
                                    <title>{`${s.label}: ${s.value} (${Math.round((s.value / total) * 100)}%)`}</title>
                                </path>
                            );
                        })}
                    </g>
                    {donut ? (
                        <g>
                            <text
                                x={R}
                                y={R - 4}
                                textAnchor="middle"
                                className="fill-foreground text-[28px] font-bold tabular-nums"
                            >
                                {total}
                            </text>
                            {centerLabel ? (
                                <text
                                    x={R}
                                    y={R + 18}
                                    textAnchor="middle"
                                    className="fill-muted-foreground text-[12px]"
                                >
                                    {centerLabel}
                                </text>
                            ) : null}
                        </g>
                    ) : null}
                </svg>

                <ul className="flex w-full min-w-0 flex-col gap-1">
                    {slices.map((s, i) => (
                        <li
                            key={s.key}
                            onMouseEnter={() => setHover(s.key)}
                            onMouseLeave={() => setHover(null)}
                            style={{ '--i': i } as CSSProperties}
                            className={`animate-rise flex min-h-9 items-center gap-2.5 rounded-lg px-2 text-sm transition-colors ${
                                hover === s.key ? 'bg-secondary' : ''
                            }`}
                        >
                            <span
                                className="size-3 shrink-0 rounded-sm"
                                style={{ background: s.color }}
                                aria-hidden="true"
                            />
                            <span className="min-w-0 flex-1 truncate" title={s.label}>
                                {s.label}
                            </span>
                            <span className="font-medium tabular-nums">{s.value}</span>
                            <span className="w-10 text-right text-muted-foreground tabular-nums">
                                {Math.round((s.value / total) * 100)}%
                            </span>
                        </li>
                    ))}
                </ul>
            </div>
        </div>
    );
}
