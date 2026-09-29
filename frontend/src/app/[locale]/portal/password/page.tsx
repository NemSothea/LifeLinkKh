import { getTranslations } from 'next-intl/server';
import PillLink from '@/components/PillLink';
import { IconArrowLeft } from '@/components/icons';
import { redirect } from 'next/navigation';
import { hasPortalSession, portalDisplayName } from '@/lib/api/session';
import ChangePasswordForm from './change-password-form';
import PageHeader from '@/components/PageHeader';

/**
 * The signed-in admin changing their own password — not an admin screen. The action
 * behind it takes the account from the session's ID token and has no user field, so this cannot
 * be pointed at somebody else's account.
 *
 * There is no "forgot password" beside it, deliberately: a reset needs a channel to prove identity
 * over, and this product has neither verified email nor verified phone (ADR 0002). A forgotten
 * password is reset by an operator in the Firebase console's Authentication page (or, for the
 * seeded admin, `npm run seed:admin -- --reset-passwords` in `firebase/`).
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
            <PageHeader
                locale={locale}
                title={t('title')}
                subtitle={`${t('intro')}${displayName ? ` (${displayName})` : ''}`}
                className="mb-6"
            />

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
                    failedCommon: t('failedCommon'),
                    failedMismatch: t('failedMismatch'),
                    failedUnchanged: t('failedUnchanged'),
                    failed: t('failed'),
                }}
            />

            <p className="mt-6 text-xs text-black/60 dark:text-white/60">
                {t('noteOtherSessions')}
            </p>

            <div className="mt-6">
                <PillLink href={`/${locale}/portal`} icon={<IconArrowLeft />}>
                    {t('backCta')}
                </PillLink>
            </div>
        </main>
    );
}
