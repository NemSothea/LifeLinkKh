'use client';

import { useEffect, useState } from 'react';
import { useLocale, useTranslations } from 'next-intl';
import { relativeAge } from '@/lib/time';

/**
 * A live age label — "14 minutes ago" that becomes "15 minutes ago" without a reload.
 *
 * A Client Component because the server renders once and the page then sits open on a
 * ward desk for hours; a server-rendered age is wrong within a minute. It re-renders on
 * its own minute tick rather than depending on the page's refresh cycle.
 *
 * `suppressHydrationWarning`: the server and the browser compute this from two clocks
 * that are never exactly equal, so a one-minute disagreement on first paint is expected
 * and immediately corrected by the effect below.
 */
export default function RelativeTime({ iso, className }: { iso: string; className?: string }) {
    const t = useTranslations('time');
    const locale = useLocale();
    const [now, setNow] = useState<Date | null>(null);

    useEffect(() => {
        setNow(new Date());
        const timer = setInterval(() => setNow(new Date()), 30_000);
        return () => clearInterval(timer);
    }, []);

    const age = relativeAge(iso, now ?? new Date());
    const label =
        age.unit === 'now'
            ? t('justNow')
            : age.unit === 'date'
              ? new Date(age.value).toLocaleDateString(locale, {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric',
                })
              : t(age.unit, { count: age.value });

    return (
        <time dateTime={iso} className={className} suppressHydrationWarning>
            {label}
        </time>
    );
}
