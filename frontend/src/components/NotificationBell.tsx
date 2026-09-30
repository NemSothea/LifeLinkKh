'use client';

import Link from 'next/link';
import { useEffect, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Bell, ClipboardCheck, HeartHandshake, UserX } from 'lucide-react';
import RelativeTime from '@/components/RelativeTime';
import type { AdminNotification } from '@/lib/notifications';
import { FOCUS_EVENT } from '@/components/useFocusTarget';

/**
 * When the admin last opened the bell. Per browser, like the theme: a display convenience, not a
 * record — clearing site data only means everything shows as new once.
 */
const SEEN_KEY = 'lifelink.portal.notificationsSeenAt';

const ICONS = { pending: ClipboardCheck, accepted: HeartHandshake, unmatched: UserX } as const;
const TITLE_KEYS = {
    pending: 'pendingTitle',
    accepted: 'acceptedTitle',
    unmatched: 'unmatchedTitle',
} as const;

function readSeen(): string {
    try {
        return window.localStorage.getItem(SEEN_KEY) ?? '';
    } catch {
        return '';
    }
}

/**
 * The admin's bell, beside the theme and language buttons. The red count is what arrived since the
 * bell was last opened; opening it marks everything seen. Each item links to the card that deals
 * with it. Built the same way as the other header menus: a 44px button, Escape or a click outside
 * closes it.
 */
export default function NotificationBell({ items }: { items: AdminNotification[] }) {
    const t = useTranslations('notifications');
    const [open, setOpen] = useState(false);
    // Null until mounted: the server cannot know what this browser has seen.
    const [seenAt, setSeenAt] = useState<string | null>(null);
    const rootRef = useRef<HTMLDivElement>(null);
    const buttonRef = useRef<HTMLButtonElement>(null);

    useEffect(() => setSeenAt(readSeen()), []);

    useEffect(() => {
        if (!open) return;
        const onPointerDown = (e: PointerEvent) => {
            if (!rootRef.current?.contains(e.target as Node)) setOpen(false);
        };
        const onKeyDown = (e: KeyboardEvent) => {
            if (e.key === 'Escape') {
                setOpen(false);
                buttonRef.current?.focus();
            }
        };
        document.addEventListener('pointerdown', onPointerDown);
        document.addEventListener('keydown', onKeyDown);
        return () => {
            document.removeEventListener('pointerdown', onPointerDown);
            document.removeEventListener('keydown', onKeyDown);
        };
    }, [open]);

    const unseen = seenAt == null ? 0 : items.filter((i) => i.at > seenAt).length;

    function markSeen() {
        const now = new Date().toISOString();
        try {
            window.localStorage.setItem(SEEN_KEY, now);
        } catch {
            // Private windows can refuse storage; the badge simply comes back next load.
        }
        setSeenAt(now);
    }

    return (
        <div ref={rootRef} data-testid="notification-bell" className="relative text-sm">
            <button
                ref={buttonRef}
                type="button"
                onClick={() => setOpen((v) => !v)}
                aria-haspopup="true"
                aria-expanded={open}
                aria-label={t('open', { count: unseen })}
                data-testid="notification-bell-button"
                className="relative flex size-11 items-center justify-center rounded-full border border-border bg-secondary/60 text-foreground transition-colors hover:bg-secondary hover:text-foreground"
            >
                <Bell className="size-5" aria-hidden="true" />
                {unseen > 0 ? (
                    <span
                        data-testid="notification-bell-count"
                        className="animate-pop absolute -top-1 -right-1 flex h-5 min-w-5 items-center justify-center rounded-full bg-primary px-1 text-[11px] font-bold text-primary-foreground tabular-nums ring-2 ring-background"
                    >
                        {unseen > 9 ? '9+' : unseen}
                    </span>
                ) : null}
            </button>

            {open && (
                <div
                    role="dialog"
                    aria-label={t('title')}
                    className="animate-pop fixed inset-x-4 top-20 z-50 overflow-hidden rounded-2xl border border-border bg-popover text-popover-foreground shadow-xl sm:absolute sm:inset-x-auto sm:top-auto sm:right-0 sm:mt-2 sm:w-96"
                >
                    <div className="flex items-center justify-between gap-2 border-b border-border px-4 py-2">
                        <h2 className="text-sm font-semibold">{t('title')}</h2>
                        {unseen > 0 ? (
                            <button
                                type="button"
                                onClick={markSeen}
                                data-testid="notification-mark-read"
                                className="min-h-11 rounded-lg px-2 text-sm font-medium text-brand hover:underline"
                            >
                                {t('markAllRead')}
                            </button>
                        ) : (
                            <span className="min-h-11" />
                        )}
                    </div>

                    {items.length === 0 ? (
                        <p className="px-4 py-8 text-center text-sm text-muted-foreground">
                            {t('empty')}
                        </p>
                    ) : (
                        <ul className="max-h-[min(24rem,60vh)] overflow-y-auto p-1">
                            {items.map((item) => {
                                const isNew = seenAt != null && item.at > seenAt;
                                const Icon = ICONS[item.kind];
                                return (
                                    <li key={item.id}>
                                        <Link
                                            href={item.href}
                                            onClick={() => {
                                                setOpen(false);
                                                markSeen();
                                                // Already on the portal: the page will not remount,
                                                // so tell the list to bring the card into view.
                                                window.setTimeout(
                                                    () =>
                                                        window.dispatchEvent(
                                                            new CustomEvent(FOCUS_EVENT, {
                                                                detail: item.href.slice(
                                                                    item.href.indexOf('#'),
                                                                ),
                                                            }),
                                                        ),
                                                    50,
                                                );
                                            }}
                                            data-testid={`notification-${item.id}`}
                                            className="flex min-h-11 gap-3 rounded-xl px-3 py-2.5 transition-colors hover:bg-secondary focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-none"
                                        >
                                            <span
                                                className={`mt-0.5 flex size-9 shrink-0 items-center justify-center rounded-full ${
                                                    item.kind === 'accepted'
                                                        ? 'bg-accent text-brand'
                                                        : 'bg-warning-surface text-warning'
                                                }`}
                                            >
                                                <Icon className="size-4" aria-hidden="true" />
                                            </span>
                                            <span className="min-w-0 flex-1">
                                                <span className="flex items-center gap-2">
                                                    <span className="text-sm font-medium">
                                                        {t(TITLE_KEYS[item.kind])}
                                                    </span>
                                                    {isNew ? (
                                                        <span
                                                            className="size-2 shrink-0 rounded-full bg-primary"
                                                            aria-label={t('newBadge')}
                                                        />
                                                    ) : null}
                                                </span>
                                                <span className="block truncate text-sm text-muted-foreground">
                                                    {[item.donor, item.bloodType, item.hospital]
                                                        .filter(Boolean)
                                                        .join(' · ')}
                                                </span>
                                                <RelativeTime
                                                    iso={item.at}
                                                    className="text-xs text-muted-foreground tabular-nums"
                                                />
                                            </span>
                                        </Link>
                                    </li>
                                );
                            })}
                        </ul>
                    )}
                </div>
            )}
        </div>
    );
}
