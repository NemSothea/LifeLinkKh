import Link from 'next/link';
import { getTranslations } from 'next-intl/server';
import { LayoutDashboard, ListChecks } from 'lucide-react';

/** Requests | Dashboard, for the admin. Two plain links, so each view keeps its own URL. */
export default async function PortalTabs({
    locale,
    active,
}: {
    locale: string;
    active: 'requests' | 'dashboard';
}) {
    const t = await getTranslations('dashboard');
    const tabs = [
        { key: 'requests', href: `/${locale}/portal`, label: t('tabRequests'), icon: ListChecks },
        {
            key: 'dashboard',
            href: `/${locale}/portal/dashboard`,
            label: t('tabDashboard'),
            icon: LayoutDashboard,
        },
    ] as const;
    return (
        <nav
            aria-label={t('title')}
            data-testid="portal-tabs"
            className="flex w-full gap-1 rounded-full border border-border bg-secondary/40 p-1 sm:w-auto"
        >
            {tabs.map(({ key, href, label, icon: Icon }) => {
                const isActive = key === active;
                return (
                    <Link
                        key={key}
                        href={href}
                        aria-current={isActive ? 'page' : undefined}
                        data-testid={`portal-tab-${key}`}
                        className={`flex min-h-11 flex-1 items-center justify-center gap-2 rounded-full px-4 text-sm font-medium transition-colors focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-none sm:flex-none ${
                            isActive
                                ? 'bg-primary text-primary-foreground shadow-sm'
                                : 'text-muted-foreground hover:bg-secondary hover:text-foreground'
                        }`}
                    >
                        <Icon className="size-4" aria-hidden="true" />
                        {label}
                    </Link>
                );
            })}
        </nav>
    );
}
