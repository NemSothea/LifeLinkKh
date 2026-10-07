import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { jsonLd, mobileAppJsonLd, pageMetadata } from '@/lib/seo';
import Image from 'next/image';
import Link from 'next/link';
import PublicPage from '@/components/PublicPage';
import styles from '@/components/public-site.module.css';
import { firestoreGet } from '@/lib/api/client';
import { ArrowLeft, Download, FileCheck, RefreshCw, ShieldAlert, Smartphone } from 'lucide-react';

/**
 * Where Android users get the app. LifeLink is not on the Play Store until it has 500 users, so
 * the APK is downloaded — from GitHub Releases, or wherever `APK_DOWNLOAD_URL` points — and installed
 * by hand — which Android and Play
 * Protect warn about, and this page has to say that warning is expected, or nobody installs it.
 *
 * Without `APK_DOWNLOAD_URL` the link is the latest GitHub release's asset: `scripts/build-release-apk.sh`
 * always names it `lifelink-kh.apk`, so the link never changes between releases. The version shown
 * comes from `config/app` (written by `npm run release`), one public read per visit. If that read
 * fails the page still offers the download; it just does not name a version.
 */
const RELEASES_URL = 'https://github.com/NemSothea/LifeLinkKh/releases/latest';
const DEFAULT_APK_URL = `${RELEASES_URL}/download/lifelink-kh.apk`;

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
    const isGithubRelease = apkUrl === DEFAULT_APK_URL;

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
                    {/* For someone reading this on a computer: the APK has to reach their phone, and a
                        QR code of this page is the shortest way there. Phones never see it. */}
                    <div
                        className="mt-6 hidden items-center gap-4 sm:flex"
                        data-testid="download-qr"
                    >
                        <Image
                            src={`/download-qr-${locale === 'en' ? 'en' : 'km'}.png`}
                            alt={t('qrAlt')}
                            width={112}
                            height={112}
                            className="shrink-0 rounded-lg bg-white p-1"
                        />
                        <p className={styles.note}>{t('qrBody')}</p>
                    </div>
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
                    {/* Only for the GitHub release: it publishes lifelink-kh.apk.sha256 next to the APK
                        (scripts/build-release-apk.sh). A custom APK_DOWNLOAD_URL has no known checksum. */}
                    {isGithubRelease ? (
                        <section className={styles.card} data-testid="download-verify">
                            <h2 className={styles.cardTitle}>
                                <FileCheck size={23} aria-hidden="true" />
                                {t('verifyHeading')}
                            </h2>
                            <p>{t('verifyBody')}</p>
                            <p className="mt-3 flex flex-wrap gap-x-4 gap-y-1">
                                <a
                                    className="text-brand underline-offset-4 hover:underline"
                                    href={`${apkUrl}.sha256`}
                                >
                                    {t('verifyChecksumCta')}
                                </a>
                                <a
                                    className="text-brand underline-offset-4 hover:underline"
                                    href={RELEASES_URL}
                                >
                                    {t('releaseNotesCta')}
                                </a>
                            </p>
                        </section>
                    ) : null}
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
