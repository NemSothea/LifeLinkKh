export type Slice = { key: string; label: string; value: number; color: string };

/** Keeps the largest `keep` and folds the rest into one "Other" slice, which always goes last. */
export function foldSlices(
    rows: { key: string; label: string; value: number }[],
    keep: number,
    otherLabel: string,
): Slice[] {
    const sorted = [...rows].filter((r) => r.value > 0).sort((a, b) => b.value - a.value);
    const head = sorted.slice(0, keep).map((r, i) => ({ ...r, color: `var(--series-${i + 1})` }));
    const rest = sorted.slice(keep).reduce((sum, r) => sum + r.value, 0);
    return rest > 0
        ? [
              ...head,
              { key: '__other', label: otherLabel, value: rest, color: 'var(--series-other)' },
          ]
        : head;
}
