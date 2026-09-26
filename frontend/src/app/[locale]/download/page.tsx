import { getTranslations } from 'next-intl/server';
import Link from 'next/link';
import LanguageSwitcher from '@/components/LanguageSwitcher';
import LegalLinks from '@/components/LegalLinks';
import { IconDroplet } from '@/components/icons';
import { firestoreGet } from '@/lib/api/client';

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

export default async function DownloadPage({ params }: { params: Promise<{ locale: string }> }) {
    const { locale } = await params;
    const t = await getTranslations('download');
    const apkUrl = process.env.APK_DOWNLOAD_URL?.trim() || DEFAULT_APK_URL;
    const certSha256 = process.env.APK_CERT_SHA256?.trim() || null;

    const config = await firestoreGet('config/app', null);
    const versionName =
        config.ok && typeof config.data?.data.latestVersionName === 'string'
            ? config.data.data.latestVersionName
            : null;

    return (
        <main className="mx-auto max-w-2xl p-6 sm:p-10">
            <header className="mb-8 flex items-start justify-between gap-4">
                <div className="flex items-center gap-3">
                    <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-brand text-white shadow-sm">
                        <IconDroplet className="h-5 w-5" />
                    </span>
                    <div>
                        <p className="text-sm font-semibold tracking-wide text-brand uppercase">
                            LifeLink KH
                        </p>
                        <h1 className="text-2xl font-bold tracking-tight">{t('title')}</h1>
                    </div>
                </div>
                <LanguageSwitcher />
            </header>

            <p className="mb-6 text-sm text-black/80 dark:text-white/80">{t('intro')}</p>

            <a
                href={apkUrl}
                data-testid="download-apk"
                className="mb-2 inline-flex items-center gap-2 rounded-xl bg-brand px-5 py-3 text-base font-semibold text-white shadow-sm hover:opacity-90 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand"
            >
                {t('downloadCta')}
            </a>
            <p className="mb-8 text-xs text-black/50 dark:text-white/50">
                {versionName ? t('versionLabel', { version: versionName }) : t('androidOnly')}
            </p>

            <section className="mb-8">
                <h2 className="mb-2 text-lg font-semibold">{t('stepsHeading')}</h2>
                <ol className="list-decimal space-y-1 pl-5 text-sm text-black/80 dark:text-white/80">
                    <li>{t('step1')}</li>
                    <li>{t('step2')}</li>
                    <li>{t('step3')}</li>
                    <li>{t('step4')}</li>
                </ol>
            </section>

            <section className="mb-8">
                <h2 className="mb-2 text-lg font-semibold">{t('warningHeading')}</h2>
                <p className="text-sm text-black/80 dark:text-white/80">{t('warningBody')}</p>
                {certSha256 ? (
                    <p className="mt-2 text-xs break-all text-black/60 dark:text-white/60">
                        {t('certLabel')} <code className="font-mono">{certSha256}</code>
                    </p>
                ) : null}
            </section>

            <section className="mb-8">
                <h2 className="mb-2 text-lg font-semibold">{t('updatesHeading')}</h2>
                <p className="text-sm text-black/80 dark:text-white/80">{t('updatesBody')}</p>
            </section>

            <p className="mb-8 text-sm text-black/60 dark:text-white/60">{t('iphone')}</p>

            <div className="flex flex-col gap-4">
                <LegalLinks locale={locale} />
                <Link
                    href={`/${locale}`}
                    className="text-sm font-medium text-black/60 underline-offset-4 hover:underline dark:text-white/60"
                >
                    {t('backCta')}
                </Link>
            </div>
        </main>
    );
}
