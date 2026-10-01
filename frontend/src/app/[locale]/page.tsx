import { getTranslations } from 'next-intl/server';
import Link from 'next/link';
import LegalLinks from '@/components/LegalLinks';
import { BookOpen, CodeXml, Download, Mail, Phone } from 'lucide-react';
import { IconArrowRight, IconInbox, IconShield, IconUsers } from '@/components/icons';
import PageHeader from '@/components/PageHeader';
import { Button } from '@/components/ui/button';
import { SUPPORT_PHONE } from '@/lib/support';
import type { CSSProperties } from 'react';

const SOURCE_URL = 'https://github.com/NemSothea/LifeLinkKh';

type Step = { title: string; body: string };
/** One row of the numbered team list — a name and what that person built. */
type TeamMember = { name: string; role: string };

/**
 * The portal's front door. Most visitors are donors or families who came for the app, so
 * "Get the app" is the first, filled card; the request board is the second. The API health
 * line moved to the admin's portal page — a donor has no use for it.
 *
 * Below the cards, the page answers what a wary visitor asks before installing an app from
 * outside the Play Store: what happens to a request, what LifeLink will never ask for, who is
 * behind it, and how to reach them.
 */
export default async function HomePage({ params }: { params: Promise<{ locale: string }> }) {
    const { locale } = await params;
    const t = await getTranslations('app');
    const th = await getTranslations('home');
    const steps = th.raw('steps') as Step[];
    const safety = th.raw('safety') as string[];
    const team = th.raw('team') as TeamMember[];
    const supportEmail = process.env.SUPPORT_EMAIL?.trim() || null;

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
                    index={0}
                />
                <EntryCard
                    href={`/${locale}/portal`}
                    testId="home-portal-link"
                    icon={<IconInbox className="h-6 w-6" />}
                    title={t('portalCardTitle')}
                    body={t('portalCardBody')}
                    index={1}
                />
                {/* DEC-019: how families actually get blood, and what a donor checks first. */}
                <EntryCard
                    href={`/${locale}/getting-blood`}
                    testId="home-guide-link"
                    icon={<BookOpen className="size-6" aria-hidden="true" />}
                    title={t('guideCardTitle')}
                    body={t('guideCardBody')}
                    index={2}
                />
            </div>

            <section className="mt-12" data-testid="home-how">
                <h2 className="mb-4 text-xl font-semibold">{th('howHeading')}</h2>
                <ol className="flex flex-col gap-4">
                    {steps.map((step, i) => (
                        <li key={step.title} className="flex gap-4">
                            <span className="flex size-8 shrink-0 items-center justify-center rounded-full bg-accent text-sm font-semibold text-brand tabular-nums">
                                {i + 1}
                            </span>
                            <div className="min-w-0 pt-0.5">
                                <h3 className="font-semibold">{step.title}</h3>
                                <p className="mt-1 text-sm text-muted-foreground">{step.body}</p>
                            </div>
                        </li>
                    ))}
                </ol>
            </section>

            <section
                className="mt-10 rounded-2xl border border-emerald-300 bg-emerald-50 p-5 text-emerald-900 dark:border-emerald-900 dark:bg-emerald-950/50 dark:text-emerald-200"
                data-testid="home-safety"
            >
                <h2 className="mb-3 flex items-center gap-2 text-lg font-semibold">
                    <IconShield className="h-5 w-5 shrink-0" />
                    {th('safetyHeading')}
                </h2>
                <ul className="list-disc space-y-1.5 pl-5 text-sm">
                    {safety.map((item) => (
                        <li key={item}>{item}</li>
                    ))}
                </ul>
            </section>

            <section
                className="mt-10 rounded-2xl border border-border bg-card p-5 text-card-foreground shadow-sm"
                data-testid="home-about"
            >
                <h2 className="mb-3 flex items-center gap-2 text-lg font-semibold">
                    <IconUsers className="h-5 w-5 shrink-0 text-brand" />
                    {th('aboutHeading')}
                </h2>
                <p className="text-sm text-foreground">{th('aboutBody')}</p>
                <h3 className="mt-4 mb-2 text-sm font-semibold">{th('teamLabel')}</h3>
                <ol className="space-y-2 text-sm" data-testid="home-team">
                    {team.map((member, i) => (
                        <li key={member.name} className="flex items-baseline gap-3">
                            <span className="w-5 shrink-0 text-right font-semibold text-brand tabular-nums">
                                {i + 1}.
                            </span>
                            <span>
                                <span className="font-medium text-foreground">{member.name}</span>
                                <span className="text-muted-foreground"> — {member.role}</span>
                            </span>
                        </li>
                    ))}
                </ol>
                <p className="mt-4 border-t border-border pt-3 text-sm" data-testid="home-lecturer">
                    <span className="font-semibold">{th('lecturerLabel')}</span>{' '}
                    <span className="text-foreground">{th('lecturer')}</span>
                </p>
                <div className="mt-4 flex flex-wrap gap-2">
                    <Button asChild variant="outline" className="rounded-full">
                        <a href={SOURCE_URL} target="_blank" rel="noopener noreferrer">
                            <CodeXml aria-hidden="true" />
                            {th('sourceLink')}
                        </a>
                    </Button>
                </div>
            </section>

            <section className="mt-10" data-testid="home-contact">
                <h2 className="mb-2 text-lg font-semibold">{th('contactHeading')}</h2>
                <p className="mb-3 text-sm text-muted-foreground">{th('contactBody')}</p>
                <div className="flex flex-wrap gap-2">
                    <Button asChild variant="outline" className="rounded-full">
                        <a href={`tel:${SUPPORT_PHONE.tel}`} data-testid="home-contact-phone">
                            <Phone aria-hidden="true" />
                            {SUPPORT_PHONE.carrier}: {SUPPORT_PHONE.display}
                        </a>
                    </Button>
                    {supportEmail ? (
                        <Button asChild variant="outline" className="rounded-full">
                            <a href={`mailto:${supportEmail}`}>
                                <Mail aria-hidden="true" />
                                {supportEmail}
                            </a>
                        </Button>
                    ) : null}
                </div>
            </section>

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
    index,
}: {
    href: string;
    testId: string;
    icon: React.ReactNode;
    title: string;
    body: string;
    primary?: boolean;
    index: number;
}) {
    return (
        <Link
            href={href}
            data-testid={testId}
            style={{ '--i': index } as CSSProperties}
            className={`animate-rise group flex items-start gap-4 rounded-2xl border p-5 shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-none ${
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
