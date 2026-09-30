import { getTranslations } from 'next-intl/server';

/**
 * The medical disclaimer and copyright line under every page, portal included. Rendered from the
 * locale layout so no page can forget them; the page-level legal links stay where they are.
 * The disclaimer is DEC-019's rule that the app never presents itself as the NBTC.
 */
export default async function SiteFooter({ locale }: { locale: string }) {
    const t = await getTranslations({ locale, namespace: 'app' });
    return (
        <footer
            className="space-y-2 px-6 py-6 text-center text-sm text-muted-foreground"
            data-testid="site-footer"
        >
            <p className="mx-auto max-w-prose" data-testid="site-footer-disclaimer">
                {t('disclaimer')}
            </p>
            <p>{t('copyright', { year: new Date().getFullYear() })}</p>
        </footer>
    );
}
