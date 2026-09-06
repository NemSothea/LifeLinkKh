'use client';

import { useEffect, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import RelativeTime from './RelativeTime';

/**
 * Keeps the open-requests table current without anyone pressing F5.
 *
 * The page is a Server Component, so "refresh" means `router.refresh()` — Next refetches
 * on the server and streams new markup into the existing tree, which keeps every open
 * `<details>` row expanded and the search box's text where it was. A `location.reload()`
 * would throw all of that away every thirty seconds.
 *
 * Paused while the tab is hidden: a portal left open overnight should not poll the
 * backend until morning, and the first thing it does on becoming visible again is
 * refresh once, so nobody reads a stale table.
 */
const INTERVAL_MS = 30_000;

export default function AutoRefresh() {
    const t = useTranslations('portal');
    const router = useRouter();
    const [isPending, startTransition] = useTransition();
    const [lastUpdated, setLastUpdated] = useState<string | null>(null);

    useEffect(() => {
        setLastUpdated(new Date().toISOString());

        function refresh() {
            startTransition(() => {
                router.refresh();
                setLastUpdated(new Date().toISOString());
            });
        }

        let timer = window.setInterval(refresh, INTERVAL_MS);

        function onVisibilityChange() {
            window.clearInterval(timer);
            if (document.visibilityState === 'visible') {
                refresh();
                timer = window.setInterval(refresh, INTERVAL_MS);
            }
        }

        document.addEventListener('visibilitychange', onVisibilityChange);
        return () => {
            window.clearInterval(timer);
            document.removeEventListener('visibilitychange', onVisibilityChange);
        };
    }, [router]);

    return (
        <div
            data-testid="portal-auto-refresh"
            className="flex items-center gap-2 text-xs text-black/50 dark:text-white/50"
        >
            <span
                className={`h-1.5 w-1.5 shrink-0 rounded-full bg-emerald-500 ${
                    isPending ? 'motion-safe:animate-pulse' : ''
                }`}
                aria-hidden="true"
            />
            {lastUpdated ? (
                <span>
                    {t('updatedLabel')} <RelativeTime iso={lastUpdated} />
                </span>
            ) : (
                <span>{t('updatedLabel')}</span>
            )}
        </div>
    );
}
