import { getTranslations } from 'next-intl/server';
import Link from 'next/link';
import LanguageSwitcher from '@/components/LanguageSwitcher';
import { IconDroplet } from '@/components/icons';

/**
 * The web link Google Play requires for account deletion (DEC-016). Public — the whole point is
 * that someone who lost their phone can still reach it.
 *
 * It does not delete anything itself. The app's Delete account does it with a fresh Google
 * sign-in; this page has no Google sign-in to build that on, and a form that deleted an account
 * from an email address alone would let anyone delete anyone. So it gives the in-app steps and,
 * for someone who cannot use the app, the address to write to — an operator verifies the person
 * and runs `npm run delete-account` (firebase/functions/scripts/delete-account.mjs).
 *
 * `SUPPORT_EMAIL` is read on the server. Unset, the page still gives the in-app steps and says
 * the address is not configured — which is a launch blocker, not a state to ship in.
 */
export default async function DeleteAccountPage({
    params,
}: {
    params: Promise<{ locale: string }>;
}) {
    const { locale } = await params;
    const t = await getTranslations('deleteAccount');
    const supportEmail = process.env.SUPPORT_EMAIL?.trim() || null;

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

            <section className="mb-8">
                <h2 className="mb-2 text-lg font-semibold">{t('inAppHeading')}</h2>
                <ol className="list-decimal space-y-1 pl-5 text-sm text-black/80 dark:text-white/80">
                    <li>{t('inAppStep1')}</li>
                    <li>{t('inAppStep2')}</li>
                    <li>{t('inAppStep3')}</li>
                </ol>
            </section>

            <section className="mb-8">
                <h2 className="mb-2 text-lg font-semibold">{t('noAppHeading')}</h2>
                <p className="text-sm text-black/80 dark:text-white/80">{t('noAppBody')}</p>
                {supportEmail ? (
                    <p className="mt-3 text-sm">
                        <a
                            href={`mailto:${supportEmail}?subject=${encodeURIComponent(t('mailSubject'))}`}
                            data-testid="delete-account-email"
                            className="font-medium text-brand underline-offset-4 hover:underline"
                        >
                            {supportEmail}
                        </a>
                    </p>
                ) : (
                    <p
                        data-testid="delete-account-no-email"
                        className="mt-3 rounded-xl border border-amber-300 bg-amber-50 p-3 text-sm text-amber-800 dark:border-amber-800 dark:bg-amber-950/40 dark:text-amber-300"
                    >
                        {t('noEmailConfigured')}
                    </p>
                )}
            </section>

            <section className="mb-8">
                <h2 className="mb-2 text-lg font-semibold">{t('whatHeading')}</h2>
                <ul className="list-disc space-y-1 pl-5 text-sm text-black/80 dark:text-white/80">
                    <li>{t('whatDeleted')}</li>
                    <li>{t('whatClosed')}</li>
                    <li>{t('whatKept')}</li>
                </ul>
            </section>

            <Link
                href={`/${locale}`}
                className="text-sm font-medium text-black/60 underline-offset-4 hover:underline dark:text-white/60"
            >
                {t('backCta')}
            </Link>
        </main>
    );
}
