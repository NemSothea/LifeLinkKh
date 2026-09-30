import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { pageMetadata } from '@/lib/seo';
import PillLink from '@/components/PillLink';
import { IconArrowLeft } from '@/components/icons';
import PageHeader from '@/components/PageHeader';
import Highlight from '@/components/Highlight';

/**
 * "How getting blood works" — DEC-019. Public, for families first and donors second.
 *
 * About three-quarters of Cambodian blood is replacement donation: the hospital asks the
 * family to bring donors, and a relative of any blood type counts, because the blood bank
 * issues the patient's type from tested stock. The page also says blood is free by national
 * policy and never to pay a broker, and lists what a donor can check at home before
 * travelling to donate. The same content is in the app (`BloodGuideScreen`,
 * `DonationGuideScreen`). Sources: `docs/po/research/2026-09-cambodia-donation-reality.md`.
 */
type Section = { heading: string; items: string[] };

export async function generateMetadata({
    params,
}: {
    params: Promise<{ locale: string }>;
}): Promise<Metadata> {
    const { locale } = await params;
    const t = await getTranslations({ locale, namespace: 'gettingBlood' });
    return pageMetadata({
        locale,
        path: '/getting-blood',
        title: t('title'),
        description: t('metaDescription'),
    });
}

export default async function GettingBloodPage({
    params,
}: {
    params: Promise<{ locale: string }>;
}) {
    const { locale } = await params;
    const t = await getTranslations('gettingBlood');
    const sections = t.raw('sections') as Section[];

    return (
        <main className="mx-auto max-w-2xl p-6 sm:p-10" data-testid="getting-blood">
            <PageHeader locale={locale} title={t('title')} subtitle={t('subtitle')} />

            <p className="mb-8 text-base text-foreground">
                <Highlight text={t('intro')} />
            </p>

            <div className="flex flex-col gap-4">
                {sections.map((section) => (
                    <section
                        key={section.heading}
                        className="rounded-2xl border border-border bg-card p-5 text-card-foreground shadow-sm"
                    >
                        <h2 className="mb-3 text-lg font-semibold">{section.heading}</h2>
                        <ul className="list-disc space-y-1.5 pl-5 text-sm text-foreground">
                            {section.items.map((item) => (
                                <li key={item}>
                                    <Highlight text={item} />
                                </li>
                            ))}
                        </ul>
                    </section>
                ))}
            </div>

            <p className="mt-8 text-sm text-muted-foreground">{t('source')}</p>

            <p className="mt-8">
                <PillLink href={`/${locale}`} icon={<IconArrowLeft />}>
                    {t('backHome')}
                </PillLink>
            </p>
        </main>
    );
}
