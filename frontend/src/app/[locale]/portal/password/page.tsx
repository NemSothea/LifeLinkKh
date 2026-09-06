import { getTranslations } from 'next-intl/server';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import { hasPortalSession, portalDisplayName } from '@/lib/api/session';
import ChangePasswordForm from './change-password-form';

/**
 * Any signed-in staff member changing their own password — not an admin screen. The endpoint
 * behind it takes the caller from the JWT and has no user field, so this cannot be pointed at
 * somebody else's account.
 *
 * There is no "forgot password" beside it, deliberately: a reset needs a channel to prove identity
 * over, and this product has neither verified email nor verified phone (ADR 0002). A forgotten
 * password is a database change — `docs/demo-runbook.md` section 9.
 */
export default async function ChangePasswordPage({
    params,
}: {
    params: Promise<{ locale: string }>;
}) {
    const { locale } = await params;
    if (!(await hasPortalSession())) {
        redirect(`/${locale}/sign-in`);
    }

    const t = await getTranslations('password');
    const admin = await getTranslations('admin');
    const displayName = await portalDisplayName();

    return (
        <main className="mx-auto max-w-md p-6 sm:p-10">
            <header className="mb-6">
                <p className="text-sm font-semibold tracking-wide text-brand uppercase">LifeLink KH</p>
                <h1 className="text-2xl font-bold tracking-tight">{t('title')}</h1>
                <p className="mt-2 text-sm text-black/60 dark:text-white/60">
                    {t('intro')}
                    {displayName ? ` (${displayName})` : ''}
                </p>
            </header>

            <ChangePasswordForm
                copy={{
                    currentLabel: t('currentLabel'),
                    newLabel: t('newLabel'),
                    confirmLabel: t('confirmLabel'),
                    passwordHint: admin('passwordHint'),
                    submitCta: t('submitCta'),
                    submitting: t('submitting'),
                    changed: t('changed'),
                    failedWrongCurrent: t('failedWrongCurrent'),
                    failedTooShort: t('failedTooShort'),
                    failedMismatch: t('failedMismatch'),
                    failedUnchanged: t('failedUnchanged'),
                    failed: t('failed'),
                }}
            />

            <p className="mt-6 text-xs text-black/45 dark:text-white/45">{t('noteOtherSessions')}</p>

            <Link
                href={`/${locale}/portal`}
                className="mt-6 inline-block text-sm font-medium text-black/60 underline-offset-4 hover:underline dark:text-white/60"
            >
                {t('backCta')}
            </Link>
        </main>
    );
}
