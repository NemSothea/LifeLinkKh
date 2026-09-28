'use client';

import { useEffect, useState } from 'react';

/**
 * Counts the first number in `text` up from zero once, then shows `text` exactly — so "83%",
 * "74 min" and "២៥ នាទី"-style strings keep their units. Skipped under reduced motion, and the
 * server render is the final text, so nothing is wrong before JavaScript runs.
 */
export default function CountUp({ text, durationMs = 900 }: { text: string; durationMs?: number }) {
    const match = /\d+(\.\d+)?/.exec(text);
    const target = match ? Number(match[0]) : null;
    const decimals = match?.[1] ? match[1].length - 1 : 0;
    const [shown, setShown] = useState(text);

    useEffect(() => {
        if (target == null || target === 0) return;
        if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
        let frame = 0;
        const start = performance.now();
        const tick = (now: number) => {
            const p = Math.min(1, (now - start) / durationMs);
            const eased = 1 - (1 - p) ** 3;
            const value = (target * eased).toFixed(decimals);
            setShown(text.replace(match![0], value));
            if (p < 1) frame = requestAnimationFrame(tick);
        };
        frame = requestAnimationFrame(tick);
        return () => cancelAnimationFrame(frame);
        // Re-run only when the figure itself changes (a new period).
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [text]);

    return <>{shown}</>;
}
