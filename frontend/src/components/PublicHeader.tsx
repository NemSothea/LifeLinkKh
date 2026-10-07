import Link from 'next/link';
import { getTranslations } from 'next-intl/server';
import { Download } from 'lucide-react';
import SiteControls from '@/components/SiteControls';
import { IconBrandMark } from '@/components/icons';
import styles from './public-site.module.css';

export default async function PublicHeader({
    locale,
    home = false,
}: {
    locale: string;
    home?: boolean;
}) {
    const t = await getTranslations('landing');
    const h = await getTranslations('home');
    const app = await getTranslations('app');
    return (
        <header className={styles.header}>
            <Link href={`/${locale}`} className={styles.brand} aria-label={app('title')}>
                <span className={styles.brandMark}>
                    <IconBrandMark className="size-6" />
                </span>
                LifeLink KH
            </Link>
            <nav className={styles.navigation} aria-label={t('navigation')}>
                <Link href={home ? '#how-it-works' : `/${locale}#how-it-works`}>
                    {h('howHeading')}
                </Link>
                <Link href={`/${locale}/portal`}>{app('portalCardTitle')}</Link>
                <Link href={home ? '#about' : `/${locale}#about`}>{t('aboutNav')}</Link>
            </nav>
            <div className={styles.controls}>
                <SiteControls />
                <Link
                    href={`/${locale}/download`}
                    className={`${styles.button} ${styles.primary} ${styles.headerDownload}`}
                >
                    <Download size={17} aria-hidden="true" />
                    {t('headerDownload')}
                </Link>
            </div>
        </header>
    );
}
