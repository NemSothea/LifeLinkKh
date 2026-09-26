import Link from 'next/link';
import { getTranslations } from 'next-intl/server';

/**
 * The two pages the Play listing points at (privacy policy, account deletion), linked from every
 * public entry point so a donor or a reviewer can reach them without knowing the URLs.
 */
export default async function LegalLinks({ locale }: { locale: string }) {
    const t = await getTranslations('privacy');
    return (
        <nav className="flex gap-4 text-xs text-black/50 dark:text-white/50">
            <Link href={`/${locale}/privacy`} className="underline-offset-4 hover:underline">
                {t('title')}
            </Link>
            <Link href={`/${locale}/delete-account`} className="underline-offset-4 hover:underline">
                {t('deleteLink')}
            </Link>
        </nav>
    );
}
