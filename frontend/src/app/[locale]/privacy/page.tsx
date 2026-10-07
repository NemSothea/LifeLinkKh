import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { pageMetadata } from '@/lib/seo';
import PillLink from '@/components/PillLink';
import { IconArrowLeft, IconTrash } from '@/components/icons';
import PublicPage from '@/components/PublicPage';
import styles from '@/components/public-site.module.css';
import Highlight from '@/components/Highlight';
import { SUPPORT_PHONE } from '@/lib/support';

/**
 * The privacy policy — the public URL the Play listing and the Data safety form point at.
 *
 * The text lives in `messages/{en,km}.json` under `privacy`, one entry per section, so both
 * languages are the same document and a change to one is visibly missing from the other. Every
 * statement in it is checked against the code: what `firestore.rules` lets each person read, what
 * the Functions write, what `deleteAccountData` deletes (DEC-016). Change the code, change this.
 *
 * `SUPPORT_EMAIL` is the contact, the same one `/delete-account` gives; `SUPPORT_PHONE` sits
 * beside it for questions.
 */
type Section = { heading: string; paragraphs?: string[]; items?: string[] };

export async function generateMetadata({
    params,
}: {
    params: Promise<{ locale: string }>;
}): Promise<Metadata> {
    const { locale } = await params;
    const t = await getTranslations({ locale, namespace: 'privacy' });
    return pageMetadata({
        locale,
        path: '/privacy',
        title: t('title'),
        description: t('metaDescription'),
    });
}

export default async function PrivacyPage({ params }: { params: Promise<{ locale: string }> }) {
    const { locale } = await params;
    const t = await getTranslations('privacy');
    const ui = await getTranslations('publicPages');
    const sections = t.raw('sections') as Section[];
    const supportEmail = process.env.SUPPORT_EMAIL?.trim() || null;

    return (
        <PublicPage
            locale={locale}
            title={t('title')}
            eyebrow={ui('privacyEyebrow')}
            subtitle={t('effective')}
        >
            <div className={styles.document}>
                <p className={styles.articleIntro}>
                    <Highlight text={t('intro')} />
                </p>

                {sections.map((section) => (
                    <section key={section.heading} className={styles.card}>
                        <h2 className="mb-2 text-lg font-semibold">{section.heading}</h2>
                        {section.paragraphs?.map((p) => (
                            <p key={p} className="mb-2 text-sm text-foreground">
                                <Highlight text={p} />
                            </p>
                        ))}
                        {section.items ? (
                            <ul className="list-disc space-y-1 pl-5 text-sm text-foreground">
                                {section.items.map((item) => (
                                    <li key={item}>
                                        <Highlight text={item} />
                                    </li>
                                ))}
                            </ul>
                        ) : null}
                    </section>
                ))}

                <section className={styles.card}>
                    <h2 className="mb-2 text-lg font-semibold">{t('contactHeading')}</h2>
                    <p className="text-sm text-foreground">{t('contactBody')}</p>
                    {supportEmail ? (
                        <p className="mt-2 text-sm">
                            <a
                                href={`mailto:${supportEmail}`}
                                data-testid="privacy-email"
                                className="font-medium text-brand underline-offset-4 hover:underline"
                            >
                                {supportEmail}
                            </a>
                        </p>
                    ) : null}
                    <p className="mt-2 text-sm">
                        <a
                            href={`tel:${SUPPORT_PHONE.tel}`}
                            data-testid="privacy-phone"
                            className="font-medium text-brand underline-offset-4 hover:underline"
                        >
                            {SUPPORT_PHONE.carrier}: {SUPPORT_PHONE.display}
                        </a>
                    </p>
                    <p className="mt-3">
                        <PillLink href={`/${locale}/delete-account`} icon={<IconTrash />}>
                            {t('deleteLink')}
                        </PillLink>
                    </p>
                </section>

                <PillLink href={`/${locale}`} icon={<IconArrowLeft />}>
                    {t('backCta')}
                </PillLink>
            </div>
        </PublicPage>
    );
}
