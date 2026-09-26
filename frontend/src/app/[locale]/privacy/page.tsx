import { getTranslations } from 'next-intl/server';
import Link from 'next/link';
import LanguageSwitcher from '@/components/LanguageSwitcher';
import { IconDroplet } from '@/components/icons';

/**
 * The privacy policy — the public URL the Play listing and the Data safety form point at.
 *
 * The text lives in `messages/{en,km}.json` under `privacy`, one entry per section, so both
 * languages are the same document and a change to one is visibly missing from the other. Every
 * statement in it is checked against the code: what `firestore.rules` lets each person read, what
 * the Functions write, what `deleteAccountData` deletes (DEC-016). Change the code, change this.
 *
 * `SUPPORT_EMAIL` is the contact, the same one `/delete-account` gives.
 */
type Section = { heading: string; paragraphs?: string[]; items?: string[] };

export default async function PrivacyPage({ params }: { params: Promise<{ locale: string }> }) {
    const { locale } = await params;
    const t = await getTranslations('privacy');
    const sections = t.raw('sections') as Section[];
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
                        <p className="text-xs text-black/50 dark:text-white/50">{t('effective')}</p>
                    </div>
                </div>
                <LanguageSwitcher />
            </header>

            <p className="mb-8 text-sm text-black/80 dark:text-white/80">{t('intro')}</p>

            {sections.map((section) => (
                <section key={section.heading} className="mb-8">
                    <h2 className="mb-2 text-lg font-semibold">{section.heading}</h2>
                    {section.paragraphs?.map((p) => (
                        <p key={p} className="mb-2 text-sm text-black/80 dark:text-white/80">
                            {p}
                        </p>
                    ))}
                    {section.items ? (
                        <ul className="list-disc space-y-1 pl-5 text-sm text-black/80 dark:text-white/80">
                            {section.items.map((item) => (
                                <li key={item}>{item}</li>
                            ))}
                        </ul>
                    ) : null}
                </section>
            ))}

            <section className="mb-8">
                <h2 className="mb-2 text-lg font-semibold">{t('contactHeading')}</h2>
                <p className="text-sm text-black/80 dark:text-white/80">{t('contactBody')}</p>
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
                    <Link
                        href={`/${locale}/delete-account`}
                        className="font-medium text-brand underline-offset-4 hover:underline"
                    >
                        {t('deleteLink')}
                    </Link>
                </p>
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
