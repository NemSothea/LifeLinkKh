import { getTranslations } from 'next-intl/server';
import { redirect } from 'next/navigation';
import LanguageSwitcher from '@/components/LanguageSwitcher';
import { IconDroplet } from '@/components/icons';
import { hasPortalSession } from '@/lib/api/session';
import SignInForm from './sign-in-form';

/**
 * Portal staff sign-in — the screen that replaces `PORTAL_DEV_JWT`.
 *
 * Donors and requesters never see this page. They authenticate through Google or Telegram
 * in the mobile app (ADR 0002) and hold no username; a password exists only for the handful
 * of named hospital and admin accounts that have to reach this portal from a desktop
 * browser with no phone in the loop.
 */
export default async function SignInPage({
    params,
}: {
    params: Promise<{ locale: string }>;
}) {
    const { locale } = await params;
    const t = await getTranslations('signIn');

    // Already signed in: the portal is where they were going.
    if (await hasPortalSession()) {
        redirect(`/${locale}/portal`);
    }

    return (
        <main className="mx-auto flex min-h-screen max-w-md flex-col justify-center p-6">
            <div className="mb-8 flex items-start justify-between gap-4">
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
            </div>

            <p className="mb-6 text-sm text-black/60 dark:text-white/60">{t('intro')}</p>

            <SignInForm
                locale={locale}
                copy={{
                    usernameLabel: t('usernameLabel'),
                    passwordLabel: t('passwordLabel'),
                    submitCta: t('submitCta'),
                    submitting: t('submitting'),
                    failed: t('failed'),
                    failedRateLimited: t('failedRateLimited'),
                    failedUnreachable: t('failedUnreachable'),
                    showPassword: t('showPassword'),
                    hidePassword: t('hidePassword'),
                    rememberUsername: t('rememberUsername'),
                    rememberHint: t('rememberHint'),
                    usernamePlaceholder: t('usernamePlaceholder'),
                    passwordPlaceholder: t('passwordPlaceholder'),
                }}
            />

            <p className="mt-8 text-xs text-black/45 dark:text-white/45">{t('noSelfSignup')}</p>
        </main>
    );
}
