'use client';

import { useLocale } from 'next-intl';
import { Link, usePathname } from '@/i18n/navigation';
import { routing } from '@/i18n/routing';

const LOCALE_LABEL: Record<string, string> = { km: 'ខ្មែរ', en: 'English' };

/**
 * Swaps the locale segment of the current path, keeping the rest of the URL —
 * confirming a donation on the portal shouldn't bounce staff back to the request list.
 */
export default function LanguageSwitcher() {
    const pathname = usePathname();
    const activeLocale = useLocale();

    return (
        <div
            data-testid="language-switcher"
            className="flex items-center gap-1 rounded-full border border-black/10 bg-black/[0.02] p-1 text-sm dark:border-white/15 dark:bg-white/[0.04]"
        >
            {routing.locales.map((locale) => (
                <Link
                    key={locale}
                    href={pathname}
                    locale={locale}
                    data-testid={`language-switcher-${locale}`}
                    aria-current={locale === activeLocale ? 'true' : undefined}
                    className={`rounded-full px-3 py-1 font-medium transition-colors ${
                        locale === activeLocale
                            ? 'bg-brand text-white'
                            : 'text-black/60 hover:text-black dark:text-white/60 dark:hover:text-white'
                    }`}
                >
                    {LOCALE_LABEL[locale]}
                </Link>
            ))}
        </div>
    );
}
