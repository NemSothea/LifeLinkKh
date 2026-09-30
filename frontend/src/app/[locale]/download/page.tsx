import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { jsonLd, mobileAppJsonLd, pageMetadata } from '@/lib/seo';
import PillLink from '@/components/PillLink';
import LegalLinks from '@/components/LegalLinks';
import { IconArrowLeft } from '@/components/icons';
import { firestoreGet } from '@/lib/api/client';
import Image from 'next/image';
import { Download, FileCheck, RefreshCw, ShieldAlert } from 'lucide-react';
import { Button } from '@/components/ui/button';
import PageHeader from '@/components/PageHeader';

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
    const apkUrl = process.env.APK_DOWNLOAD_URL?.trim() || DEFAULT_APK_URL;
    const certSha256 = process.env.APK_CERT_SHA256?.trim() || null;
    const isGithubRelease = apkUrl === DEFAULT_APK_URL;

    const config = await firestoreGet('config/app', null);
    const versionName =
        config.ok && typeof config.data?.data.latestVersionName === 'string'
            ? config.data.data.latestVersionName
            : null;

    return (
        <main className="mx-auto max-w-2xl p-6 sm:p-10">
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
            <PageHeader locale={locale} title={t('title')} />

            <p className="mb-6 text-sm text-foreground">{t('intro')}</p>

            <Button asChild size="lg" className="w-full rounded-2xl sm:w-auto">
                <a href={apkUrl} data-testid="download-apk">
                    <Download className="size-5" aria-hidden="true" />
                    {t('downloadCta')}
                </a>
            </Button>
            <p className="mt-2 mb-8 text-xs text-muted-foreground">
                {versionName ? t('versionLabel', { version: versionName }) : t('androidOnly')}
            </p>

            {/* For someone reading this on a computer: the APK has to reach their phone, and a
                QR code of this page is the shortest way there. Phones never see it. */}
            <div
                className="mb-8 hidden items-center gap-4 rounded-2xl border border-border bg-card p-4 shadow-sm sm:flex"
                data-testid="download-qr"
            >
                <Image
                    src={`/download-qr-${locale === 'en' ? 'en' : 'km'}.png`}
                    alt={t('qrAlt')}
                    width={112}
                    height={112}
                    className="shrink-0 rounded-lg bg-white p-1"
                />
                <p className="text-sm text-muted-foreground">{t('qrBody')}</p>
            </div>

            <section className="mb-6 rounded-2xl border border-border bg-card p-5 shadow-sm">
                <h2 className="mb-4 text-lg font-semibold">{t('stepsHeading')}</h2>
                <ol className="flex flex-col gap-3 text-sm">
                    {(['step1', 'step2', 'step3', 'step4'] as const).map((key, i) => (
                        <li key={key} className="flex gap-3">
                            <span className="flex size-7 shrink-0 items-center justify-center rounded-full bg-accent text-sm font-semibold text-brand tabular-nums">
                                {i + 1}
                            </span>
                            <span className="pt-0.5">{t(key)}</span>
                        </li>
                    ))}
                </ol>
            </section>

            {/* The Play Protect warning is the moment people give up on a sideloaded app, so it
                reads as a warning, not as one more paragraph. */}
            <section className="mb-6 rounded-2xl border border-amber-300 bg-warning-surface p-5 text-warning dark:border-amber-900">
                <h2 className="mb-2 flex items-start gap-2 text-lg font-semibold">
                    <ShieldAlert className="mt-0.5 size-5 shrink-0" aria-hidden="true" />
                    {t('warningHeading')}
                </h2>
                <p className="text-sm">{t('warningBody')}</p>
                {certSha256 ? (
                    <p className="mt-2 text-xs break-all opacity-90">
                        {t('certLabel')} <code className="font-mono">{certSha256}</code>
                    </p>
                ) : null}
            </section>

            {/* Only for the GitHub release: it publishes lifelink-kh.apk.sha256 next to the APK
                (scripts/build-release-apk.sh). A custom APK_DOWNLOAD_URL has no known checksum. */}
            {isGithubRelease ? (
                <section
                    className="mb-6 rounded-2xl border border-border bg-card p-5 shadow-sm"
                    data-testid="download-verify"
                >
                    <h2 className="mb-2 flex items-center gap-2 text-lg font-semibold">
                        <FileCheck className="size-5 text-brand" aria-hidden="true" />
                        {t('verifyHeading')}
                    </h2>
                    <p className="mb-3 text-sm text-muted-foreground">{t('verifyBody')}</p>
                    <p className="flex flex-wrap gap-x-4 gap-y-1 text-sm">
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

            <section className="mb-6 rounded-2xl border border-border bg-card p-5 shadow-sm">
                <h2 className="mb-2 flex items-center gap-2 text-lg font-semibold">
                    <RefreshCw className="size-5 text-brand" aria-hidden="true" />
                    {t('updatesHeading')}
                </h2>
                <p className="text-sm text-muted-foreground">{t('updatesBody')}</p>
            </section>

            <p className="mb-8 text-sm text-muted-foreground">{t('iphone')}</p>

            <div className="flex flex-col gap-4">
                <LegalLinks locale={locale} />
                <div>
                    <PillLink href={`/${locale}`} icon={<IconArrowLeft />}>
                        {t('backCta')}
                    </PillLink>
                </div>
            </div>
        </main>
    );
}
