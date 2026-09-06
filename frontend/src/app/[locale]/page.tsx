import { getTranslations } from 'next-intl/server';
import Link from 'next/link';
import HealthStatus from '@/components/HealthStatus';
import LanguageSwitcher from '@/components/LanguageSwitcher';
import { IconArrowRight, IconDroplet, IconInbox, IconUsers } from '@/components/icons';
import { getHealth } from '@/lib/api/health';
import { portalRole } from '@/lib/api/session';

/**
 * The portal's front door. Until now this was the M2 health page — a status badge and
 * no way in, so anyone who landed on `/` had to already know `/portal` existed and type
 * it. The health check stays (it still proves browser → Next server → backend →
 * PostgreSQL end to end, unmocked), demoted to a footer line rather than being the
 * whole page.
 *
 * A Server Component like the rest of the portal: `portalRole()` reads the session
 * cookie's own claim server-side to decide whether the staff card is worth showing. A
 * signed-out visitor simply sees neither — following the portal card takes them to
 * sign-in. Same rule as `portal/page.tsx`: a wrong guess here changes what renders, never
 * what the API allows.
 */
export default async function HomePage({
    params,
}: {
    params: Promise<{ locale: string }>;
}) {
    const { locale } = await params;
    const t = await getTranslations('app');
    const health = await getHealth();
    const isAdmin = (await portalRole()) === 'ADMIN';

    return (
        <main className="mx-auto max-w-3xl p-6 sm:p-10">
            <header className="mb-10 flex flex-wrap items-start justify-between gap-4">
                <div className="flex items-center gap-3">
                    <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-brand text-white shadow-sm">
                        <IconDroplet className="h-5 w-5" />
                    </span>
                    <div>
                        <h1 className="text-2xl font-bold tracking-tight sm:text-3xl">
                            {t('title')}
                        </h1>
                        <p className="text-sm text-black/60 dark:text-white/60">{t('tagline')}</p>
                    </div>
                </div>
                <LanguageSwitcher />
            </header>

            <div className="flex flex-col gap-4">
                <EntryCard
                    href={`/${locale}/portal`}
                    testId="home-portal-link"
                    icon={<IconInbox className="h-6 w-6" />}
                    title={t('portalCardTitle')}
                    body={t('portalCardBody')}
                    primary
                />
                {isAdmin ? (
                    <EntryCard
                        href={`/${locale}/portal/staff`}
                        testId="home-admin-link"
                        icon={<IconUsers className="h-6 w-6" />}
                        title={t('adminCardTitle')}
                        body={t('adminCardBody')}
                    />
                ) : null}
            </div>

            <footer className="pt-10">
                <HealthStatus
                    reachable={health.ok}
                    status={health.ok ? health.data.status : undefined}
                />
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
            className={`group flex items-start gap-4 rounded-2xl border bg-white p-5 shadow-sm transition-shadow hover:shadow-md focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:bg-white/[0.03] ${
                primary
                    ? 'border-black/10 border-l-4 border-l-brand dark:border-white/15'
                    : 'border-black/10 dark:border-white/15'
            }`}
        >
            <span
                className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl ${
                    primary
                        ? 'bg-brand text-white'
                        : 'bg-black/[0.04] text-black/60 dark:bg-white/10 dark:text-white/70'
                }`}
            >
                {icon}
            </span>
            <div className="min-w-0 flex-1">
                <h2 className="text-lg font-semibold">{title}</h2>
                <p className="mt-1 text-sm text-black/60 dark:text-white/60">{body}</p>
            </div>
            <IconArrowRight
                className={`mt-2.5 h-5 w-5 shrink-0 transition-transform group-hover:translate-x-0.5 ${
                    primary ? 'text-brand' : 'text-black/30 dark:text-white/30'
                }`}
            />
        </Link>
    );
}
