import { getTranslations } from 'next-intl/server';

/** The handbook (docs/book/), Khmer at the root and English under /en/. */
const HANDBOOK_URL = 'https://nemsothea.github.io/LifeLinkKh/';

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
            <p>
                <a
                    href={locale === 'en' ? `${HANDBOOK_URL}en/` : HANDBOOK_URL}
                    className="underline-offset-4 hover:underline"
                    data-testid="site-footer-handbook"
                >
                    {t('handbook')}
                </a>
                {' · '}
                {t('copyright', { year: new Date().getFullYear() })}
            </p>
        </footer>
    );
}
