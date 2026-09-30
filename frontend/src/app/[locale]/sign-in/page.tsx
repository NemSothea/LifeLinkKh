import { getTranslations } from 'next-intl/server';
import { redirect } from 'next/navigation';
import LegalLinks from '@/components/LegalLinks';
import { hasPortalSession } from '@/lib/api/session';
import { passwordSignInEnabled } from '@/lib/api/sign-in-options';
import GoogleSignIn from './google-sign-in';
import SignInForm from './sign-in-form';
import PageHeader from '@/components/PageHeader';

/**
 * Portal admin sign-in — the screen that replaces `PORTAL_DEV_JWT`. v1 has no hospital staff.
 *
 * Donors and requesters never see this page. They authenticate through Google or Telegram
 * in the mobile app (ADR 0002) and hold no username; a password exists only for the admin
 * account that has to reach this portal from a desktop browser with no phone in the loop.
 */
export default async function SignInPage({ params }: { params: Promise<{ locale: string }> }) {
    const { locale } = await params;
    const t = await getTranslations('signIn');

    // Already signed in: the portal is where they were going.
    if (await hasPortalSession()) {
        redirect(`/${locale}/portal`);
    }

    const googleClientId = process.env.GOOGLE_CLIENT_ID;
    // Never both off: without a Google client the password form is the only way in.
    const showPassword = passwordSignInEnabled() || !googleClientId;

    return (
        <main className="mx-auto flex min-h-screen max-w-md flex-col justify-center p-6">
            <PageHeader locale={locale} title={t('title')} subtitle={t('intro')} className="mb-6" />

            {showPassword ? (
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
            ) : null}

            {/* Shown only once the OAuth client is configured, so a deploy without it keeps
                the password form alone rather than a button that cannot work. */}
            {googleClientId ? (
                <div className={showPassword ? 'mt-6' : undefined}>
                    <GoogleSignIn
                        clientId={googleClientId}
                        divider={showPassword}
                        locale={locale}
                        copy={{
                            or: t('or'),
                            failed: t('googleFailed'),
                            failedRateLimited: t('failedRateLimited'),
                            failedUnreachable: t('failedUnreachable'),
                            submitting: t('submitting'),
                        }}
                    />
                </div>
            ) : null}

            <p className="mt-8 text-xs text-muted-foreground">{t('noSelfSignup')}</p>
            <div className="mt-4">
                <LegalLinks locale={locale} />
            </div>
        </main>
    );
}
