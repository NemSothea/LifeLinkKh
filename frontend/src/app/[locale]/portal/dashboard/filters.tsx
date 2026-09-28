import Link from 'next/link';
import { getTranslations } from 'next-intl/server';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import type { DashboardRange } from '@/lib/api/dashboard';

const iso = (d: Date) => d.toISOString().slice(0, 10);

/**
 * The period, in one row above the charts: three presets, a year, and a custom from–to. All of it
 * lives in the URL (a plain GET form and links), so a view can be bookmarked or sent to someone,
 * and it works before any JavaScript has loaded.
 */
export default async function DashboardFilters({
    locale,
    range,
    years,
}: {
    locale: string;
    range: DashboardRange;
    years: number[];
}) {
    const t = await getTranslations('dashboard');
    const base = `/${locale}/portal/dashboard`;
    const presets = [
        { key: '7d', href: `${base}?range=7d`, label: t('preset7d') },
        { key: '30d', href: `${base}?range=30d`, label: t('preset30d') },
        { key: 'year', href: `${base}?range=year`, label: t('presetYear') },
    ] as const;
    const lastDay = new Date(range.to.getTime() - 24 * 3600_000);

    return (
        <div
            data-testid="dashboard-filters"
            className="flex flex-col gap-4 rounded-2xl border border-border bg-card p-4 shadow-sm"
        >
            <div className="flex flex-col gap-1.5">
                <span className="px-1 text-xs font-medium text-muted-foreground">
                    {t('filterLabel')}
                </span>
                <div className="flex max-w-full gap-1 overflow-x-auto rounded-full border border-border p-1">
                    {presets.map((p) => {
                        const active =
                            range.preset === p.key &&
                            (p.key !== 'year' || range.year === new Date().getUTCFullYear());
                        return (
                            <Link
                                key={p.key}
                                href={p.href}
                                aria-current={active ? 'true' : undefined}
                                data-testid={`dashboard-preset-${p.key}`}
                                className={`flex min-h-11 shrink-0 items-center rounded-full px-4 text-sm font-medium whitespace-nowrap transition-colors focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-none ${
                                    active
                                        ? 'bg-primary text-primary-foreground'
                                        : 'text-muted-foreground hover:bg-secondary hover:text-foreground'
                                }`}
                            >
                                {p.label}
                            </Link>
                        );
                    })}
                </div>
            </div>

            <div className="flex flex-col gap-4 md:flex-row md:items-end md:gap-6">
                <form
                    method="get"
                    action={base}
                    className="flex flex-wrap items-end gap-2"
                    data-testid="dashboard-year-form"
                >
                    <label className="flex flex-col gap-1.5 text-xs font-medium text-muted-foreground">
                        {t('yearLabel')}
                        <select
                            name="year"
                            defaultValue={range.year ?? ''}
                            data-testid="dashboard-year"
                            className="min-h-11 rounded-xl border border-input bg-background px-3 text-base text-foreground shadow-xs focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-none dark:bg-input/20"
                        >
                            <option value="" disabled>
                                —
                            </option>
                            {years.map((y) => (
                                <option key={y} value={y}>
                                    {y}
                                </option>
                            ))}
                        </select>
                    </label>
                    <Button type="submit" variant="outline">
                        {t('applyCta')}
                    </Button>
                </form>
                <span className="hidden h-11 w-px self-end bg-border md:block" aria-hidden="true" />
                <form
                    method="get"
                    action={base}
                    className="flex flex-wrap items-end gap-2"
                    data-testid="dashboard-custom-form"
                >
                    <label className="flex flex-col gap-1.5 text-xs font-medium text-muted-foreground">
                        {t('fromLabel')}
                        <Input
                            type="date"
                            name="from"
                            required
                            defaultValue={iso(range.from)}
                            max={iso(new Date())}
                            className="text-foreground"
                        />
                    </label>
                    <label className="flex flex-col gap-1.5 text-xs font-medium text-muted-foreground">
                        {t('toLabel')}
                        <Input
                            type="date"
                            name="to"
                            required
                            defaultValue={iso(lastDay)}
                            max={iso(new Date())}
                            className="text-foreground"
                        />
                    </label>
                    <Button type="submit" variant="outline">
                        {t('applyCta')}
                    </Button>
                </form>
            </div>
        </div>
    );
}
