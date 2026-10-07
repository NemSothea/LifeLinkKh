import Link from 'next/link';
import { getTranslations } from 'next-intl/server';
import { IconBrandMark } from '@/components/icons';
import FooterVariant from './FooterVariant';
import styles from './public-site.module.css';

const HANDBOOK_URL = 'https://nemsothea.github.io/LifeLinkKh/';
const SOURCE_URL = 'https://github.com/NemSothea/LifeLinkKh';

export default async function SiteFooter({ locale }: { locale: string }) {
    const t = await getTranslations({ locale, namespace: 'app' });
    const landing = await getTranslations({ locale, namespace: 'landing' });
    const signIn = await getTranslations({ locale, namespace: 'signIn' });
    const handbook = locale === 'en' ? `${HANDBOOK_URL}en/` : HANDBOOK_URL;
    const copyright = t('copyright', { year: new Date().getFullYear() });
    return (
        <FooterVariant
            publicFooter={
                <footer className={styles.footerSurface} data-testid="site-footer">
                    <div className={`${styles.container} ${styles.footer}`}>
                        <Link href={`/${locale}`} className={styles.brand}>
                            <span className={styles.brandMark}>
                                <IconBrandMark className="size-5" />
                            </span>
                            LifeLink KH
                        </Link>
                        <nav
                            className={styles.footerLinks}
                            aria-label={landing('footerNavigation')}
                            data-testid="legal-links"
                        >
                            <Link href={`/${locale}/privacy`}>{landing('privacyShort')}</Link>
                            <Link href={`/${locale}/delete-account`}>{landing('deleteShort')}</Link>
                            <a href={handbook} data-testid="site-footer-handbook">
                                {t('handbook')}
                            </a>
                            <a href={SOURCE_URL} target="_blank" rel="noopener noreferrer">
                                GitHub
                            </a>
                            <Link href={`/${locale}/sign-in`}>{signIn('title')}</Link>
                        </nav>
                        <div className={styles.footerFinePrint}>
                            <p data-testid="site-footer-disclaimer">{t('disclaimer')}</p>
                            <p>{copyright}</p>
                        </div>
                    </div>
                </footer>
            }
            portalFooter={
                <footer
                    className="space-y-2 px-6 py-6 text-center text-sm text-muted-foreground"
                    data-testid="site-footer"
                >
                    <p className="mx-auto max-w-prose" data-testid="site-footer-disclaimer">
                        {t('disclaimer')}
                    </p>
                    <p>
                        <a
                            href={handbook}
                            className="underline-offset-4 hover:underline"
                            data-testid="site-footer-handbook"
                        >
                            {t('handbook')}
                        </a>
                        {' · '}
                        {copyright}
                    </p>
                </footer>
            }
        />
    );
}
