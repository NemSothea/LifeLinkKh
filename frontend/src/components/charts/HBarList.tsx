import type { CSSProperties } from 'react';
/**
 * Ranked horizontal bars as plain HTML: the label, a thin bar, and the value always visible —
 * so nothing depends on hover or on colour. For "per hospital" and "per district".
 */
export default function HBarList({
    rows,
    color,
    emptyLabel,
}: {
    rows: { key: string; label: string; value: number }[];
    color: string;
    emptyLabel: string;
}) {
    const max = Math.max(1, ...rows.map((r) => r.value));
    if (rows.every((r) => r.value === 0)) {
        return <p className="py-6 text-center text-sm text-muted-foreground">{emptyLabel}</p>;
    }
    return (
        <ul className="flex flex-col gap-2.5">
            {rows.map((r, i) => (
                <li
                    key={r.key}
                    className="grid grid-cols-[minmax(7rem,48%)_1fr_auto] items-center gap-3 text-sm"
                >
                    <span className="truncate" title={r.label}>
                        {r.label}
                    </span>
                    <span className="h-2.5 overflow-hidden rounded-full bg-muted">
                        <span
                            className="animate-grow-x block h-full rounded-full"
                            style={
                                {
                                    width: `${(r.value / max) * 100}%`,
                                    background: color,
                                    '--i': i,
                                } as CSSProperties
                            }
                        />
                    </span>
                    <span className="w-8 text-right font-medium tabular-nums">{r.value}</span>
                </li>
            ))}
        </ul>
    );
}
