import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { jsonLd, mobileAppJsonLd, pageMetadata } from '@/lib/seo';
import Image from 'next/image';
import Link from 'next/link';
import PublicPage from '@/components/PublicPage';
import styles from '@/components/public-site.module.css';
import { firestoreGet } from '@/lib/api/client';
import { ArrowLeft, Download, RefreshCw, ShieldAlert, Smartphone } from 'lucide-react';

/**
 * Where Android users get the app. LifeLink is not on the Play Store until it has 500 users, so
 * the APK is downloaded — from the K.O.S.I.G.N store when `APK_DOWNLOAD_URL` points there, from
 * GitHub Releases otherwise — and installed by hand — which Android and Play
 * Protect warn about, and this page has to say that warning is expected, or nobody installs it.
 *
 * Without `APK_DOWNLOAD_URL` the link is the latest GitHub release's asset: `scripts/build-release-apk.sh`
 * always names it `lifelink-kh.apk`, so the link never changes between releases. The version shown
 * comes from `config/app` (written by `npm run release`), one public read per visit. If that read
 * fails the page still offers the download; it just does not name a version.
 */
const DEFAULT_APK_URL =
    'https://github.com/NemSothea/LifeLinkKh/releases/latest/download/lifelink-kh.apk';

export async function generateMetadata({
    params,
}: {
    params: Promise<{ locale: string }>;
}): Promise<Metadata> {
    const { locale } = await params;
    const t = await getTranslations({ locale, namespace: 'download' });
    return pageMetadata({
        locale,
        path: '/download',
        title: t('title'),
        description: t('metaDescription'),
    });
}

export default async function DownloadPage({ params }: { params: Promise<{ locale: string }> }) {
    const { locale } = await params;
    const t = await getTranslations('download');
    const ui = await getTranslations('publicPages');
    const landing = await getTranslations('landing');
    const installTitles = ui.raw('installTitles') as string[];
    const apkUrl = process.env.APK_DOWNLOAD_URL?.trim() || DEFAULT_APK_URL;
    const certSha256 = process.env.APK_CERT_SHA256?.trim() || null;

    const config = await firestoreGet('config/app', null);
    const versionName =
        config.ok && typeof config.data?.data.latestVersionName === 'string'
            ? config.data.data.latestVersionName
            : null;

    return (
        <PublicPage locale={locale}>
            <script
                type="application/ld+json"
                dangerouslySetInnerHTML={{
                    __html: jsonLd(
                        mobileAppJsonLd({
                            locale,
                            description: t('metaDescription'),
                            downloadUrl: apkUrl,
                            version: versionName ?? undefined,
                        }),
                    ),
                }}
            />
            <section className={styles.hero} aria-labelledby="download-title">
                <div>
                    <p className={styles.eyebrow}>{ui('downloadEyebrow')}</p>
                    <h1 id="download-title">{t('title')}</h1>
                    <p className={styles.intro}>{t('intro')}</p>
                    <div className={styles.heroActions}>
                        <a
                            href={apkUrl}
                            data-testid="download-apk"
                            className={`${styles.button} ${styles.primary}`}
                        >
                            <Download size={21} aria-hidden="true" />
                            {t('downloadCta')}
                        </a>
                    </div>
                    <p className={styles.note}>
                        {versionName
                            ? t('versionLabel', { version: versionName })
                            : t('androidOnly')}
                    </p>
                    <p className={styles.note}>{landing('installNote')}</p>
                </div>
                <figure>
                    <div className={styles.preview}>
                        <div className={styles.phone}>
                            <Image
                                src={`/landing/app-home-${locale === 'km' ? 'km' : 'en'}.png`}
                                width={720}
                                height={1760}
                                sizes="180px"
                                alt={landing('appAlt')}
                                preload
                            />
                        </div>
                    </div>
                    <figcaption className={styles.previewCaption}>
                        {landing('appCaption')}
                    </figcaption>
                </figure>
            </section>
            <div className={styles.twoColumns}>
                <section className={styles.card} aria-labelledby="install-heading">
                    <h2 id="install-heading">{t('stepsHeading')}</h2>
                    <ol className={styles.installSteps}>
                        {(['step1', 'step2', 'step3', 'step4'] as const).map((key, i) => (
                            <li key={key}>
                                <span className={styles.stepNumber}>
                                    {String(i + 1).padStart(2, '0')}
                                </span>
                                <div>
                                    <h3>{installTitles[i]}</h3>
                                    <p>{t(key)}</p>
                                </div>
                            </li>
                        ))}
                    </ol>
                </section>
                <div className={styles.stack}>
                    <section className={`${styles.card} ${styles.warning}`}>
                        <h2 className={styles.cardTitle}>
                            <ShieldAlert size={23} aria-hidden="true" />
                            {t('warningHeading')}
                        </h2>
                        <p>{t('warningBody')}</p>
                        {certSha256 && (
                            <p className="mt-4 break-all">
                                <strong>{t('certLabel')}</strong>{' '}
                                <code className="font-mono text-xs">{certSha256}</code>
                            </p>
                        )}
                    </section>
                    <section className={styles.card}>
                        <h2 className={styles.cardTitle}>
                            <RefreshCw size={23} aria-hidden="true" />
                            {t('updatesHeading')}
                        </h2>
                        <p>{t('updatesBody')}</p>
                    </section>
                    <p className={`${styles.note} flex items-start gap-2`}>
                        <Smartphone size={17} aria-hidden="true" />
                        {t('iphone')}
                    </p>
                </div>
            </div>
            <div className={styles.bottomActions}>
                <Link href={`/${locale}`} className={styles.button}>
                    <ArrowLeft size={17} aria-hidden="true" />
                    {t('backCta')}
                </Link>
                <Link href={`/${locale}/getting-blood`} className={styles.button}>
                    {landing('familyAction')}
                </Link>
            </div>
        </PublicPage>
    );
}
