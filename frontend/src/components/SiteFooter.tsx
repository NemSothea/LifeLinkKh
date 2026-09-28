import { getTranslations } from 'next-intl/server';

/**
 * The copyright line under every page, portal included. Rendered from the locale layout so no
 * page can forget it; the page-level legal links stay where they are.
 */
export default async function SiteFooter({ locale }: { locale: string }) {
    const t = await getTranslations({ locale, namespace: 'app' });
    return (
        <footer
            className="px-6 py-6 text-center text-sm text-muted-foreground"
            data-testid="site-footer"
        >
            {t('copyright', { year: new Date().getFullYear() })}
        </footer>
    );
}
