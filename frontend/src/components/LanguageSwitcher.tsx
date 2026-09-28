'use client';

import { useEffect, useRef, useState } from 'react';
import { useLocale, useTranslations } from 'next-intl';
import { Link, usePathname } from '@/i18n/navigation';
import { routing } from '@/i18n/routing';
import { IconCheck, IconChevron, IconGlobe } from '@/components/icons';

const LOCALE_LABEL: Record<string, string> = { km: 'ខ្មែរ', en: 'English' };

/**
 * Globe button that opens a small language menu. Picking one swaps the locale segment of
 * the current path, keeping the rest of the URL — confirming a donation on the portal
 * shouldn't bounce staff back to the request list.
 */
export default function LanguageSwitcher() {
    const pathname = usePathname();
    const activeLocale = useLocale();
    const t = useTranslations('app');
    const [open, setOpen] = useState(false);
    const rootRef = useRef<HTMLDivElement>(null);
    const buttonRef = useRef<HTMLButtonElement>(null);

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

    return (
        <div ref={rootRef} data-testid="language-switcher" className="relative text-sm">
            <button
                ref={buttonRef}
                type="button"
                onClick={() => setOpen((v) => !v)}
                aria-haspopup="menu"
                aria-expanded={open}
                aria-label={`${t('language')}: ${LOCALE_LABEL[activeLocale]}`}
                data-testid="language-switcher-button"
                className="flex min-h-11 items-center gap-2 rounded-full border border-black/10 bg-black/[0.02] px-3 font-medium text-black/75 transition-colors hover:bg-black/[0.05] hover:text-black dark:border-white/15 dark:bg-white/[0.04] dark:text-white/75 dark:hover:bg-white/[0.08] dark:hover:text-white"
            >
                <IconGlobe className="h-4 w-4" />
                {LOCALE_LABEL[activeLocale]}
                <IconChevron className={`h-4 w-4 transition-transform ${open ? 'rotate-180' : ''}`} />
            </button>

            {open && (
                <div
                    role="menu"
                    aria-label={t('language')}
                    className="animate-pop absolute right-0 z-50 mt-2 w-44 overflow-hidden rounded-xl border border-black/10 bg-white p-1 shadow-lg dark:border-white/15 dark:bg-neutral-900"
                >
                    {routing.locales.map((locale) => {
                        const active = locale === activeLocale;
                        return (
                            <Link
                                key={locale}
                                href={pathname}
                                locale={locale}
                                role="menuitem"
                                onClick={() => setOpen(false)}
                                data-testid={`language-switcher-${locale}`}
                                aria-current={active ? 'true' : undefined}
                                className={`flex min-h-11 items-center justify-between rounded-lg px-3 transition-colors ${
                                    active
                                        ? 'bg-brand/10 font-semibold text-brand'
                                        : 'text-black/75 hover:bg-black/[0.05] hover:text-black dark:text-white/75 dark:hover:bg-white/[0.08] dark:hover:text-white'
                                }`}
                            >
                                {LOCALE_LABEL[locale]}
                                {active && <IconCheck className="h-4 w-4" />}
                            </Link>
                        );
                    })}
                </div>
            )}
        </div>
    );
}
