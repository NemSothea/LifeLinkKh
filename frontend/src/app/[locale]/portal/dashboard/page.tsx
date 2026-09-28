import { getTranslations } from 'next-intl/server';
import { redirect } from 'next/navigation';
import { Activity, BellRing, Clock, HeartHandshake, Timer, UserPlus } from 'lucide-react';
import type { CSSProperties, ReactNode } from 'react';
import Notice from '@/components/Notice';
import PageHeader from '@/components/PageHeader';
import PortalTabs from '@/components/PortalTabs';
import AccountMenu from '@/components/AccountMenu';
import BarChart, { type Series } from '@/components/charts/BarChart';
import ChartCard from '@/components/charts/ChartCard';
import PieChart from '@/components/charts/PieChart';
import ExportExcelButton from '@/components/charts/ExportExcelButton';
import { foldSlices } from '@/components/charts/slices';
import { loadDashboard, OUTCOMES, resolveRange } from '@/lib/api/dashboard';
import { portalDisplayName, portalRole } from '@/lib/api/session';
import DashboardFilters from './filters';
import CountUp from '@/components/CountUp';
import { adminNotifications } from '@/lib/notifications';
import { listOpenRequests, listPendingRequests } from '@/lib/api/portal';

/**
 * The admin's dashboard: the five PRD metrics plus the review time as tiles, then requests over
 * time, blood-type demand against available donors, and requests per hospital / donors per
 * district — all for the period in the URL. Admin only; everyone else is sent to sign in.
 */
export default async function DashboardPage({
    params,
    searchParams,
}: {
    params: Promise<{ locale: string }>;
    searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
    const { locale } = await params;
    if ((await portalRole()) !== 'ADMIN') redirect(`/${locale}/sign-in`);

    const query = await searchParams;
    const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
    const range = resolveRange({
        range: one(query.range),
        year: one(query.year),
        from: one(query.from),
        to: one(query.to),
    });

    const t = await getTranslations('dashboard');
    const [result, displayName, pendingResult, openResult] = await Promise.all([
        loadDashboard(range),
        portalDisplayName(),
        listPendingRequests(),
        listOpenRequests(),
    ]);
    const notifications = adminNotifications(
        locale,
        pendingResult.ok ? pendingResult.data : [],
        openResult.ok ? openResult.data : [],
    );

    const intlLocale = locale === 'km' ? 'km-KH' : 'en-GB';
    const dayFmt = new Intl.DateTimeFormat(intlLocale, {
        day: 'numeric',
        month: 'short',
        timeZone: 'UTC',
    });
    const monthFmt = new Intl.DateTimeFormat(intlLocale, { month: 'short', timeZone: 'UTC' });
    const longFmt = new Intl.DateTimeFormat(intlLocale, {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
        timeZone: 'UTC',
    });
    const periodLabel = t('periodLabel', {
        from: longFmt.format(range.from),
        to: longFmt.format(new Date(range.to.getTime() - 24 * 3600_000)),
    });
    const thisYear = new Date().getUTCFullYear();
    const years = Array.from({ length: thisYear - 2026 + 1 }, (_, i) => thisYear - i);

    const outcomeSeries: Series[] = OUTCOMES.map((key, i) => ({
        key,
        label: t(`outcome${key[0].toUpperCase()}${key.slice(1)}` as 'outcomeFulfilled'),
        color: `var(--series-${i + 1})`,
    }));
    const bloodSeries: Series[] = [
        { key: 'requests', label: t('seriesRequests'), color: 'var(--series-1)' },
        { key: 'donors', label: t('seriesDonors'), color: 'var(--series-2)' },
    ];
    const pct = (v: number | null) => (v == null ? t('none') : `${Math.round(v * 100)}%`);
    const mins = (v: number | null) =>
        v == null ? t('none') : t('minutes', { n: v < 10 ? v.toFixed(1) : Math.round(v) });

    const iso = (d: Date) => d.toISOString().slice(0, 10);
    const fileBase = `lifelink-${iso(range.from)}_${iso(new Date(range.to.getTime() - 24 * 3600_000))}`;
    const data = result.ok ? result.data : null;
    const hospitalSlices = data
        ? foldSlices(
              data.hospitals.map((h) => ({ key: h.name, label: h.name, value: h.requests })),
              5,
              t('other'),
          )
        : [];
    const districtName = (d: { nameKm: string; nameEn: string }) =>
        locale === 'km' ? d.nameKm : d.nameEn;
    const districtSlices = data
        ? foldSlices(
              data.districts.map((d) => ({ key: d.code, label: districtName(d), value: d.donors })),
              5,
              t('other'),
          )
        : [];
    const share = (value: number, total: number) =>
        total === 0 ? '0%' : `${Math.round((value / total) * 100)}%`;
    const hospitalTotal = data ? data.hospitals.reduce((n, h) => n + h.requests, 0) : 0;
    const districtTotal = data ? data.districts.reduce((n, d) => n + d.donors, 0) : 0;
    const sheets = data
        ? [
              {
                  name: t('sheetSummary'),
                  rows: [
                      [t('colMetric'), t('colValue'), t('colDetail'), t('colTarget')],
                      [
                          t('periodLabel', {
                              from: iso(range.from),
                              to: iso(new Date(range.to.getTime() - 24 * 3600_000)),
                          }),
                          '',
                          '',
                          '',
                      ],
                      [
                          t('kpiDonors'),
                          data.kpis.donorsRegistered,
                          t('kpiDonorsSub', { total: data.kpis.donorsTotal }),
                          '',
                      ],
                      [
                          t('kpiAccepted'),
                          pct(data.kpis.acceptedWithinHour),
                          t('kpiAcceptedSub', {
                              n: Math.round(
                                  (data.kpis.acceptedWithinHour ?? 0) * data.kpis.liveRequests,
                              ),
                              total: data.kpis.liveRequests,
                          }),
                          '≥ 70%',
                      ],
                      [
                          t('kpiMedian'),
                          mins(data.kpis.medianFirstAcceptMinutes),
                          t('kpiMedianSub', { n: data.kpis.acceptedRequests }),
                          '< 30 min',
                      ],
                      [
                          t('kpiDonations'),
                          data.kpis.donationsConfirmed,
                          t('kpiDonationsSub'),
                          '≥ 50',
                      ],
                      [
                          t('kpiPush'),
                          pct(data.kpis.pushSuccess),
                          t('kpiPushSub', {
                              n: Math.round((data.kpis.pushSuccess ?? 0) * data.kpis.alerts),
                              total: data.kpis.alerts,
                          }),
                          '≥ 95%',
                      ],
                      [
                          t('kpiReview'),
                          mins(data.kpis.medianReviewMinutes),
                          t('kpiReviewSub', { n: data.kpis.waitingForReview }),
                          '',
                      ],
                  ],
              },
              {
                  name: t('overTimeTitle'),
                  rows: [
                      [t('colPeriod'), ...outcomeSeries.map((x) => x.label), t('colTotal')],
                      ...data.overTime.map((b) => [
                          b.key,
                          ...OUTCOMES.map((o) => b.counts[o]),
                          OUTCOMES.reduce((n, o) => n + b.counts[o], 0),
                      ]),
                  ],
              },
              {
                  name: t('colBloodType'),
                  rows: [
                      [t('colBloodType'), t('seriesRequests'), t('seriesDonors')],
                      ...data.bloodTypes.map((b) => [b.type, b.requests, b.donors]),
                  ],
              },
              {
                  name: t('colHospital'),
                  rows: [
                      [t('colHospital'), t('colRequests'), t('colShare')],
                      ...data.hospitals.map((h) => [
                          h.name,
                          h.requests,
                          share(h.requests, hospitalTotal),
                      ]),
                  ],
              },
              {
                  name: t('colDistrict'),
                  rows: [
                      [t('colDistrict'), t('colDonors'), t('colShare')],
                      ...data.districts.map((d) => [
                          districtName(d),
                          d.donors,
                          share(d.donors, districtTotal),
                      ]),
                  ],
              },
          ]
        : [];

    return (
        <main className="mx-auto max-w-5xl p-6 sm:p-10">
            <PageHeader
                locale={locale}
                title={t('title')}
                subtitle={`${t('intro')} ${periodLabel}`}
                notifications={notifications}
                account={<AccountMenu locale={locale} displayName={displayName} role="ADMIN" />}
            >
                <div className="flex">
                    <PortalTabs locale={locale} active="dashboard" />
                </div>
            </PageHeader>

            <DashboardFilters locale={locale} range={range} years={years} />
            {data ? (
                <div className="mt-4 flex justify-end">
                    <ExportExcelButton
                        sheets={sheets}
                        fileName={fileBase}
                        label={t('exportExcel')}
                    />
                </div>
            ) : null}

            {!result.ok ? (
                <Notice tone="error" testId="dashboard-unreachable" className="mt-6">
                    {t('unreachable')}
                </Notice>
            ) : (
                <>
                    <section
                        data-testid="dashboard-kpis"
                        className="mt-6 grid grid-cols-1 gap-3 min-[420px]:grid-cols-2 lg:grid-cols-3"
                    >
                        <StatTile
                            index={0}
                            icon={<UserPlus />}
                            label={t('kpiDonors')}
                            value={String(result.data.kpis.donorsRegistered)}
                            sub={t('kpiDonorsSub', { total: result.data.kpis.donorsTotal })}
                        />
                        <StatTile
                            index={1}
                            icon={<Timer />}
                            label={t('kpiAccepted')}
                            value={pct(result.data.kpis.acceptedWithinHour)}
                            sub={t('kpiAcceptedSub', {
                                n: Math.round(
                                    (result.data.kpis.acceptedWithinHour ?? 0) *
                                        result.data.kpis.liveRequests,
                                ),
                                total: result.data.kpis.liveRequests,
                            })}
                            target={t('target', { target: '≥ 70%' })}
                        />
                        <StatTile
                            index={2}
                            icon={<Clock />}
                            label={t('kpiMedian')}
                            value={mins(result.data.kpis.medianFirstAcceptMinutes)}
                            sub={t('kpiMedianSub', { n: result.data.kpis.acceptedRequests })}
                            target={t('target', { target: '< 30 min' })}
                        />
                        <StatTile
                            index={3}
                            icon={<HeartHandshake />}
                            label={t('kpiDonations')}
                            value={String(result.data.kpis.donationsConfirmed)}
                            sub={t('kpiDonationsSub')}
                            target={t('target', { target: '≥ 50' })}
                        />
                        <StatTile
                            index={4}
                            icon={<BellRing />}
                            label={t('kpiPush')}
                            value={pct(result.data.kpis.pushSuccess)}
                            sub={t('kpiPushSub', {
                                n: Math.round(
                                    (result.data.kpis.pushSuccess ?? 0) * result.data.kpis.alerts,
                                ),
                                total: result.data.kpis.alerts,
                            })}
                            target={t('target', { target: '≥ 95%' })}
                        />
                        <StatTile
                            index={5}
                            icon={<Activity />}
                            label={t('kpiReview')}
                            value={mins(result.data.kpis.medianReviewMinutes)}
                            sub={t('kpiReviewSub', { n: result.data.kpis.waitingForReview })}
                        />
                    </section>
                    <p className="mt-2 text-xs text-muted-foreground">{t('smallSample')}</p>

                    <div className="mt-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
                        <div className="lg:col-span-2">
                            <ChartCard
                                testId="dashboard-over-time"
                                exportImage={{
                                    fileName: `${fileBase}-requests-over-time`,
                                    label: t('exportImage'),
                                }}
                                title={t('overTimeTitle')}
                                note={
                                    range.bucket === 'day'
                                        ? t('overTimeNoteDay')
                                        : t('overTimeNoteMonth')
                                }
                                series={outcomeSeries}
                                tableLabel={t('showTable')}
                                table={{
                                    head: [
                                        t('colPeriod'),
                                        ...outcomeSeries.map((s) => s.label),
                                        t('colTotal'),
                                    ],
                                    rows: result.data.overTime.map((b) => [
                                        b.key,
                                        ...OUTCOMES.map((o) => b.counts[o]),
                                        OUTCOMES.reduce((sum, o) => sum + b.counts[o], 0),
                                    ]),
                                }}
                            >
                                <BarChart
                                    mode="stacked"
                                    ariaLabel={t('overTimeTitle')}
                                    series={outcomeSeries}
                                    rows={result.data.overTime.map((b) => {
                                        const d = new Date(
                                            b.key.length === 7
                                                ? `${b.key}-01T00:00:00Z`
                                                : `${b.key}T00:00:00Z`,
                                        );
                                        return {
                                            key: b.key,
                                            label:
                                                range.bucket === 'day'
                                                    ? dayFmt.format(d)
                                                    : monthFmt.format(d),
                                            values: b.counts,
                                        };
                                    })}
                                />
                            </ChartCard>
                        </div>

                        <div className="lg:col-span-2">
                            <ChartCard
                                testId="dashboard-blood-types"
                                exportImage={{
                                    fileName: `${fileBase}-blood-types`,
                                    label: t('exportImage'),
                                }}
                                title={t('bloodTitle')}
                                note={t('bloodNote')}
                                series={bloodSeries}
                                tableLabel={t('showTable')}
                                table={{
                                    head: [
                                        t('colBloodType'),
                                        t('seriesRequests'),
                                        t('seriesDonors'),
                                    ],
                                    rows: result.data.bloodTypes.map((b) => [
                                        b.type,
                                        b.requests,
                                        b.donors,
                                    ]),
                                }}
                            >
                                <BarChart
                                    mode="grouped"
                                    labelEvery={1}
                                    ariaLabel={t('bloodTitle')}
                                    series={bloodSeries}
                                    rows={result.data.bloodTypes.map((b) => ({
                                        key: b.type,
                                        label: b.type,
                                        values: { requests: b.requests, donors: b.donors },
                                    }))}
                                />
                            </ChartCard>
                        </div>

                        <ChartCard
                            testId="dashboard-hospitals"
                            title={t('hospitalsTitle')}
                            tableLabel={t('showTable')}
                            table={{
                                head: [t('colHospital'), t('colRequests'), t('colShare')],
                                rows: result.data.hospitals.map((h) => [
                                    h.name,
                                    h.requests,
                                    share(h.requests, hospitalTotal),
                                ]),
                            }}
                            exportImage={{
                                fileName: `${fileBase}-hospitals`,
                                label: t('exportImage'),
                                legend: hospitalSlices.map((x) => ({
                                    label: x.label,
                                    color: x.color,
                                    value: `${x.value} · ${share(x.value, hospitalTotal)}`,
                                })),
                            }}
                        >
                            <PieChart
                                slices={hospitalSlices}
                                ariaLabel={t('hospitalsTitle')}
                                emptyLabel={t('empty')}
                            />
                        </ChartCard>

                        <ChartCard
                            testId="dashboard-districts"
                            title={t('districtsTitle')}
                            note={t('districtsNote')}
                            tableLabel={t('showTable')}
                            table={{
                                head: [t('colDistrict'), t('colDonors'), t('colShare')],
                                rows: result.data.districts.map((d) => [
                                    districtName(d),
                                    d.donors,
                                    share(d.donors, districtTotal),
                                ]),
                            }}
                            exportImage={{
                                fileName: `${fileBase}-districts`,
                                label: t('exportImage'),
                                legend: districtSlices.map((x) => ({
                                    label: x.label,
                                    color: x.color,
                                    value: `${x.value} · ${share(x.value, districtTotal)}`,
                                })),
                            }}
                        >
                            <PieChart
                                donut
                                slices={districtSlices}
                                centerLabel={t('donorsCenter')}
                                ariaLabel={t('districtsTitle')}
                                emptyLabel={t('empty')}
                            />
                        </ChartCard>
                    </div>
                </>
            )}
        </main>
    );
}

/** One headline number: what it is, the number, the sample behind it, and the PRD target. */
function StatTile({
    index,
    icon,
    label,
    value,
    sub,
    target,
}: {
    index: number;
    icon: ReactNode;
    label: string;
    value: string;
    sub: string;
    target?: string;
}) {
    return (
        <div
            className="animate-rise flex flex-col gap-2 rounded-2xl border border-border bg-card p-4 text-card-foreground shadow-sm"
            style={{ '--i': index } as CSSProperties}
        >
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <span className="flex size-8 shrink-0 items-center justify-center rounded-lg bg-accent text-brand [&>svg]:size-4">
                    {icon}
                </span>
                <span className="leading-tight">{label}</span>
            </div>
            <p className="text-3xl font-bold tracking-tight tabular-nums">
                <CountUp text={value} />
            </p>
            <div className="flex flex-wrap items-center justify-between gap-x-3 gap-y-1 text-xs text-muted-foreground">
                <span>{sub}</span>
                {target ? (
                    <span className="rounded-full bg-secondary px-2 py-0.5 font-medium">
                        {target}
                    </span>
                ) : null}
            </div>
        </div>
    );
}
