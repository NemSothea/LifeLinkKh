import { getTranslations } from 'next-intl/server';
import Link from 'next/link';
import LegalLinks from '@/components/LegalLinks';
import { Download } from 'lucide-react';
import { IconArrowRight, IconInbox } from '@/components/icons';
import PageHeader from '@/components/PageHeader';

/**
 * The portal's front door. Most visitors are donors or families who came for the app, so
 * "Get the app" is the first, filled card; the request board is the second. The API health
 * line moved to the admin's portal page — a donor has no use for it.
 */
export default async function HomePage({ params }: { params: Promise<{ locale: string }> }) {
    const { locale } = await params;
    const t = await getTranslations('app');

    return (
        <main className="mx-auto max-w-3xl p-6 sm:p-10">
            <PageHeader
                locale={locale}
                title={t('title')}
                subtitle={t('tagline')}
                className="mb-10"
            />

            <div className="flex flex-col gap-4">
                <EntryCard
                    href={`/${locale}/download`}
                    testId="home-download-link"
                    icon={<Download className="size-6" aria-hidden="true" />}
                    title={t('downloadCardTitle')}
                    body={t('downloadCardBody')}
                    primary
                />
                <EntryCard
                    href={`/${locale}/portal`}
                    testId="home-portal-link"
                    icon={<IconInbox className="h-6 w-6" />}
                    title={t('portalCardTitle')}
                    body={t('portalCardBody')}
                />
            </div>

            <footer className="pt-10">
                <LegalLinks locale={locale} />
            </footer>
        </main>
    );
}

/**
 * The whole card is the link, not a "learn more" line inside it — a card that looks
 * clickable and only responds along one line of text is the kind of thing staff tap
 * twice. The arrow is the only affordance for the same reason: an inline CTA next to a
 * trailing arrow made one card carry two controls that both went to the same place.
 */
function EntryCard({
    href,
    testId,
    icon,
    title,
    body,
    primary = false,
}: {
    href: string;
    testId: string;
    icon: React.ReactNode;
    title: string;
    body: string;
    primary?: boolean;
}) {
    return (
        <Link
            href={href}
            data-testid={testId}
            className={`group flex items-start gap-4 rounded-2xl border p-5 shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-none ${
                primary
                    ? 'border-primary bg-primary text-primary-foreground'
                    : 'border-border bg-card text-card-foreground hover:border-brand/40'
            }`}
        >
            <span
                className={`flex size-12 shrink-0 items-center justify-center rounded-xl ${
                    primary ? 'bg-white/15 text-white' : 'bg-accent text-brand'
                }`}
            >
                {icon}
            </span>
            <div className="min-w-0 flex-1">
                <h2 className="text-lg font-semibold">{title}</h2>
                <p
                    className={`mt-1 text-sm ${primary ? 'text-white/90' : 'text-muted-foreground'}`}
                >
                    {body}
                </p>
            </div>
            <IconArrowRight
                className={`mt-3 h-5 w-5 shrink-0 transition-transform group-hover:translate-x-1 ${
                    primary ? 'text-white' : 'text-muted-foreground'
                }`}
            />
        </Link>
    );
}
