import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { pageMetadata } from '@/lib/seo';
import Image from 'next/image';
import Link from 'next/link';
import PublicPage from '@/components/PublicPage';
import styles from '@/components/public-site.module.css';
import Highlight from '@/components/Highlight';
import {
    ArrowLeft,
    ArrowRight,
    Building2,
    Droplet,
    Heart,
    ShieldCheck,
    Timer,
    Users,
} from 'lucide-react';

/**
 * "How getting blood works" — DEC-019. Public, for families first and donors second.
 *
 * About three-quarters of Cambodian blood is replacement donation: the hospital asks the
 * family to bring donors, and a relative of any blood type counts, because the blood bank
 * issues the patient's type from tested stock. The page also says blood is free by national
 * policy and never to pay a broker, and lists what a donor can check at home before
 * travelling to donate. The same content is in the app (`BloodGuideScreen`,
 * `DonationGuideScreen`). Sources: `docs/po/research/2026-09-cambodia-donation-reality.md`.
 */
type Section = { heading: string; items: string[] };

export async function generateMetadata({
    params,
}: {
    params: Promise<{ locale: string }>;
}): Promise<Metadata> {
    const { locale } = await params;
    const t = await getTranslations({ locale, namespace: 'gettingBlood' });
    return pageMetadata({
        locale,
        path: '/getting-blood',
        title: t('title'),
        description: t('metaDescription'),
    });
}

export default async function GettingBloodPage({
    params,
}: {
    params: Promise<{ locale: string }>;
}) {
    const { locale } = await params;
    const t = await getTranslations('gettingBlood');
    const sections = t.raw('sections') as Section[];
    const ui = await getTranslations('publicPages');
    const icons = [Users, Heart, ShieldCheck, Droplet, Timer, Building2];

    return (
        <PublicPage locale={locale} testId="getting-blood">
            <section className={styles.hero} aria-labelledby="guide-title">
                <div>
                    <p className={styles.eyebrow}>{ui('guideEyebrow')}</p>
                    <h1 id="guide-title">{t('title')}</h1>
                    <p className={styles.intro}>{t('subtitle')}</p>
                    <p className={styles.articleIntro}>
                        <Highlight text={t('intro')} />
                    </p>
                </div>
                <div className={`${styles.preview} ${styles.guideArt}`}>
                    <Image src="/landing/family.svg" width={320} height={240} alt="" />
                </div>
            </section>
            <div className={styles.readingLayout}>
                <nav className={styles.toc} aria-label={ui('onThisPage')}>
                    <h2>{ui('onThisPage')}</h2>
                    {sections.map((section, i) => (
                        <a key={section.heading} href={`#guide-${i + 1}`}>
                            <span>{String(i + 1).padStart(2, '0')}</span>
                            {section.heading}
                        </a>
                    ))}
                </nav>
                <div className={styles.article}>
                    {sections.map((section, i) => {
                        const Icon = icons[i];
                        return (
                            <section
                                id={`guide-${i + 1}`}
                                key={section.heading}
                                className={styles.card}
                            >
                                <h2 className={styles.cardTitle}>
                                    {Icon && <Icon size={24} aria-hidden="true" />}
                                    {section.heading}
                                </h2>
                                <ul>
                                    {section.items.map((item) => (
                                        <li key={item}>
                                            <Highlight text={item} />
                                        </li>
                                    ))}
                                </ul>
                            </section>
                        );
                    })}
                    <p className={styles.source}>{t('source')}</p>
                    <div className={styles.bottomActions}>
                        <Link
                            href={`/${locale}/download`}
                            className={`${styles.button} ${styles.primary}`}
                        >
                            {ui('requestInApp')}
                            <ArrowRight size={17} aria-hidden="true" />
                        </Link>
                        <Link href={`/${locale}`} className={styles.button}>
                            <ArrowLeft size={17} aria-hidden="true" />
                            {t('backHome')}
                        </Link>
                    </div>
                </div>
            </div>
        </PublicPage>
    );
}
