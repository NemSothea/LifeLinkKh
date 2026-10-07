import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { pageMetadata } from '@/lib/seo';
import Notice from '@/components/Notice';
import PillLink from '@/components/PillLink';
import { IconArrowLeft, IconShield } from '@/components/icons';
import PublicPage from '@/components/PublicPage';
import styles from '@/components/public-site.module.css';

export async function generateMetadata({
    params,
}: {
    params: Promise<{ locale: string }>;
}): Promise<Metadata> {
    const { locale } = await params;
    const t = await getTranslations({ locale, namespace: 'deleteAccount' });
    return pageMetadata({
        locale,
        path: '/delete-account',
        title: t('title'),
        description: t('metaDescription'),
    });
}

/**
 * The web link Google Play requires for account deletion (DEC-016). Public — the whole point is
 * that someone who lost their phone can still reach it.
 *
 * It does not delete anything itself. The app's Delete account does it with a fresh Google
 * sign-in; this page has no Google sign-in to build that on, and a form that deleted an account
 * from an email address alone would let anyone delete anyone. So it gives the in-app steps and,
 * for someone who cannot use the app, the address to write to — an operator verifies the person
 * and runs `npm run delete-account` (firebase/scripts/delete-account.mjs).
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
    const ui = await getTranslations('publicPages');
    const supportEmail = process.env.SUPPORT_EMAIL?.trim() || null;

    return (
        <PublicPage locale={locale} title={t('title')} eyebrow={ui('deleteEyebrow')}>
            <div className={styles.document}>
                <section className={styles.card}>
                    <h2 className="mb-2 text-lg font-semibold">{t('inAppHeading')}</h2>
                    <ol className="list-decimal space-y-1 pl-5 text-sm text-foreground">
                        <li>{t('inAppStep1')}</li>
                        <li>{t('inAppStep2')}</li>
                        <li>{t('inAppStep3')}</li>
                    </ol>
                </section>

                <section className={styles.card}>
                    <h2 className="mb-2 text-lg font-semibold">{t('noAppHeading')}</h2>
                    <p className="text-sm text-foreground">{t('noAppBody')}</p>
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
                        <Notice tone="warning" testId="delete-account-no-email" className="mt-3">
                            {t('noEmailConfigured')}
                        </Notice>
                    )}
                </section>

                <section className={styles.card}>
                    <h2 className="mb-2 text-lg font-semibold">{t('whatHeading')}</h2>
                    <ul className="list-disc space-y-1 pl-5 text-sm text-foreground">
                        <li>{t('whatDeleted')}</li>
                        <li>{t('whatClosed')}</li>
                        <li>{t('whatKept')}</li>
                    </ul>
                </section>

                <div className={styles.bottomActions}>
                    <PillLink href={`/${locale}/privacy`} icon={<IconShield />}>
                        {t('privacyLink')}
                    </PillLink>
                    <PillLink href={`/${locale}`} icon={<IconArrowLeft />}>
                        {t('backCta')}
                    </PillLink>
                </div>
            </div>
        </PublicPage>
    );
}
