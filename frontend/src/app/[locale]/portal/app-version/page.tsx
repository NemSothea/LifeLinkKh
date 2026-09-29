import { getTranslations } from 'next-intl/server';
import { redirect } from 'next/navigation';
import { Smartphone } from 'lucide-react';
import Notice from '@/components/Notice';
import PageHeader from '@/components/PageHeader';
import PortalTabs from '@/components/PortalTabs';
import AccountMenu from '@/components/AccountMenu';
import { getAppConfig } from '@/lib/api/app-config';
import { portalDisplayName, portalRole } from '@/lib/api/session';
import { adminNotifications } from '@/lib/notifications';
import { listOpenRequests, listPendingRequests } from '@/lib/api/portal';
import AppVersionForm from './app-version-form';

/**
 * The admin publishing a new APK to every installed app: the newest build, the oldest one still
 * allowed to run, where to download it, and what changed. The app re-reads this on every launch
 * and every return to the foreground, so a raised minimum reaches phones within minutes.
 * Admin only; everyone else is sent to sign in.
 */
export default async function AppVersionPage({ params }: { params: Promise<{ locale: string }> }) {
    const { locale } = await params;
    if ((await portalRole()) !== 'ADMIN') redirect(`/${locale}/sign-in`);

    const t = await getTranslations('appVersion');
    const [config, displayName, pendingResult, openResult] = await Promise.all([
        getAppConfig(),
        portalDisplayName(),
        listPendingRequests(),
        listOpenRequests(),
    ]);
    const notifications = adminNotifications(
        locale,
        pendingResult.ok ? pendingResult.data : [],
        openResult.ok ? openResult.data : [],
    );

    const updated =
        config.ok && config.data.updatedAt
            ? new Intl.DateTimeFormat(locale === 'km' ? 'km-KH' : 'en-GB', {
                  dateStyle: 'medium',
                  timeStyle: 'short',
                  timeZone: 'Asia/Phnom_Penh',
              }).format(new Date(config.data.updatedAt))
            : null;

    return (
        <main className="mx-auto max-w-3xl p-6 sm:p-10">
            <PageHeader
                locale={locale}
                title={t('title')}
                subtitle={t('intro')}
                notifications={notifications}
                account={<AccountMenu locale={locale} displayName={displayName} role="ADMIN" />}
            >
                <div className="flex">
                    <PortalTabs locale={locale} active="appVersion" />
                </div>
            </PageHeader>

            {!config.ok ? (
                <Notice tone="error" testId="app-version-unreachable" className="mt-6">
                    {t('unreachable')}
                </Notice>
            ) : (
                <>
                    <section
                        data-testid="app-version-current"
                        className="mt-6 flex items-start gap-3 rounded-2xl border border-border bg-card p-5 text-sm shadow-sm"
                    >
                        <Smartphone
                            className="mt-0.5 size-5 shrink-0 text-brand"
                            aria-hidden="true"
                        />
                        <div>
                            <p className="font-semibold">
                                {config.data.latestVersionCode === null
                                    ? t('currentNone')
                                    : t('currentLive', {
                                          name: config.data.latestVersionName,
                                          code: config.data.latestVersionCode,
                                          min: config.data.minVersionCode ?? 1,
                                      })}
                            </p>
                            {updated ? (
                                <p className="mt-1 text-muted-foreground">
                                    {t('updatedAt', { when: updated })}
                                </p>
                            ) : null}
                        </div>
                    </section>

                    <section className="mt-6 rounded-2xl border border-border bg-card p-5 shadow-sm sm:p-6">
                        <AppVersionForm
                            current={config.data}
                            copy={{
                                versionNameLabel: t('versionNameLabel'),
                                versionNameHint: t('versionNameHint'),
                                versionCodeLabel: t('versionCodeLabel'),
                                versionCodeHint: t('versionCodeHint'),
                                minCodeLabel: t('minCodeLabel'),
                                minCodeHint: t('minCodeHint'),
                                minToLatestCta: t('minToLatestCta'),
                                downloadUrlLabel: t('downloadUrlLabel'),
                                downloadUrlHint: t('downloadUrlHint'),
                                privacyUrlLabel: t('privacyUrlLabel'),
                                notesEnLabel: t('notesEnLabel'),
                                notesKmLabel: t('notesKmLabel'),
                                notesHint: t('notesHint'),
                                submitCta: t('submitCta'),
                                submitting: t('submitting'),
                                confirmTitle: t('confirmTitle'),
                                // Filled in by the form with the minimum being published.
                                confirmBody: t.raw('confirmBody') as string,
                                confirmCta: t('confirmCta'),
                                cancelCta: t('cancelCta'),
                                results: {
                                    saved: t('saved'),
                                    badVersionCode: t('badVersionCode'),
                                    minAboveLatest: t('minAboveLatest'),
                                    badVersionName: t('badVersionName'),
                                    badDownloadUrl: t('badDownloadUrl'),
                                    badPrivacyUrl: t('badPrivacyUrl'),
                                    notesTooLong: t('notesTooLong'),
                                    failed: t('failed'),
                                },
                            }}
                        />
                    </section>

                    <p className="mt-6 text-xs text-muted-foreground">{t('noteUploadFirst')}</p>
                </>
            )}
        </main>
    );
}
