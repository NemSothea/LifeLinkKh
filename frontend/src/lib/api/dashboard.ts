import { firestoreQuery, type ApiResult, type Doc } from './client';
import { requirePortalToken } from './session';

/**
 * The admin dashboard's numbers, for one period — the same definitions as
 * `firebase/scripts/metrics.mjs`, so a figure on this page and one quoted from `npm run metrics`
 * at the defense agree. Reads every donor, request, match and donation once as the signed-in
 * admin (the rules already let an admin read all four) and filters in memory: fine for a pilot,
 * the same trade the metrics script makes.
 */

export const BLOOD_TYPES = ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'] as const;

/** The four outcome groups the requests-over-time chart stacks, in chart order. */
export const OUTCOMES = ['fulfilled', 'open', 'pending', 'closed'] as const;
export type Outcome = (typeof OUTCOMES)[number];

export type RangePreset = '7d' | '30d' | 'year' | 'custom';

export type DashboardRange = {
    preset: RangePreset;
    /** Inclusive start, UTC midnight. */
    from: Date;
    /** Exclusive end. */
    to: Date;
    bucket: 'day' | 'month';
    /** The calendar year, when the range is one. */
    year: number | null;
};

const DAY = 24 * 3600_000;

function utcMidnight(date: Date): Date {
    return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

function parseDate(value: string | undefined): Date | null {
    if (!value || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return null;
    const date = new Date(`${value}T00:00:00Z`);
    return Number.isNaN(date.getTime()) ? null : date;
}

/**
 * The period from the URL: `?range=7d|30d|year`, `?year=2026`, or `?from=YYYY-MM-DD&to=YYYY-MM-DD`
 * (both inclusive). Anything unreadable falls back to the last 30 days rather than an error page.
 * Ranges of more than 92 days are bucketed by month, shorter ones by day.
 */
export function resolveRange(
    params: { range?: string; year?: string; from?: string; to?: string },
    now: Date = new Date(),
): DashboardRange {
    const today = utcMidnight(now);
    const tomorrow = new Date(today.getTime() + DAY);

    const from = parseDate(params.from);
    const to = parseDate(params.to);
    if (from && to && from <= to) {
        const end = new Date(to.getTime() + DAY);
        const span = (end.getTime() - from.getTime()) / DAY;
        return { preset: 'custom', from, to: end, bucket: span > 92 ? 'month' : 'day', year: null };
    }

    const year = params.year && /^\d{4}$/.test(params.year) ? Number(params.year) : null;
    if (year && year >= 2020 && year <= today.getUTCFullYear()) {
        return {
            preset: year === today.getUTCFullYear() ? 'year' : 'custom',
            from: new Date(Date.UTC(year, 0, 1)),
            to: new Date(Date.UTC(year + 1, 0, 1)),
            bucket: 'month',
            year,
        };
    }

    if (params.range === 'year') {
        const y = today.getUTCFullYear();
        return {
            preset: 'year',
            from: new Date(Date.UTC(y, 0, 1)),
            to: new Date(Date.UTC(y + 1, 0, 1)),
            bucket: 'month',
            year: y,
        };
    }
    const days = params.range === '7d' ? 7 : 30;
    return {
        preset: days === 7 ? '7d' : '30d',
        from: new Date(tomorrow.getTime() - days * DAY),
        to: tomorrow,
        bucket: 'day',
        year: null,
    };
}

export type Kpis = {
    donorsRegistered: number;
    donorsTotal: number;
    /** Share of live requests accepted within 60 minutes, 0–1, or null with no live request. */
    acceptedWithinHour: number | null;
    liveRequests: number;
    medianFirstAcceptMinutes: number | null;
    acceptedRequests: number;
    donationsConfirmed: number;
    /** Share of alerts FCM accepted, 0–1, or null with no alert. */
    pushSuccess: number | null;
    alerts: number;
    medianReviewMinutes: number | null;
    waitingForReview: number;
};

export type Dashboard = {
    range: DashboardRange;
    kpis: Kpis;
    /** One entry per day or month in the range, oldest first; `key` is YYYY-MM-DD or YYYY-MM. */
    overTime: { key: string; counts: Record<Outcome, number> }[];
    bloodTypes: { type: string; requests: number; donors: number }[];
    hospitals: { name: string; requests: number }[];
    districts: { code: string; nameEn: string; nameKm: string; donors: number }[];
};

type Raw = {
    donors: Doc[];
    requests: Doc[];
    matches: Doc[];
    donations: Doc[];
    districts: Doc[];
};

const time = (value: unknown): number | null => {
    if (typeof value !== 'string') return null;
    const t = Date.parse(value);
    return Number.isNaN(t) ? null : t;
};

function median(values: number[]): number | null {
    if (values.length === 0) return null;
    const sorted = [...values].sort((a, b) => a - b);
    const mid = Math.floor(sorted.length / 2);
    return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

function outcomeOf(status: unknown): Outcome {
    if (status === 'FULFILLED') return 'fulfilled';
    if (status === 'OPEN') return 'open';
    if (status === 'PENDING') return 'pending';
    return 'closed';
}

function bucketKey(t: number, bucket: 'day' | 'month'): string {
    const iso = new Date(t).toISOString();
    return bucket === 'day' ? iso.slice(0, 10) : iso.slice(0, 7);
}

function bucketKeys(range: DashboardRange): string[] {
    const keys: string[] = [];
    if (range.bucket === 'day') {
        for (let t = range.from.getTime(); t < range.to.getTime(); t += DAY) {
            keys.push(bucketKey(t, 'day'));
        }
    } else {
        const cursor = new Date(range.from);
        while (cursor < range.to) {
            keys.push(bucketKey(cursor.getTime(), 'month'));
            cursor.setUTCMonth(cursor.getUTCMonth() + 1);
        }
    }
    return keys;
}

/** Pure: the whole page's numbers from the raw collections. Unit-tested. */
export function computeDashboard(raw: Raw, range: DashboardRange): Dashboard {
    const from = range.from.getTime();
    const to = range.to.getTime();
    const inRange = (t: number | null) => t != null && t >= from && t < to;

    const requests = raw.requests.filter((r) => inRange(time(r.data.createdAt)));
    const requestIds = new Set(requests.map((r) => r.id));

    // First acceptance per request, from its matches.
    const firstAccepted = new Map<string, number>();
    for (const m of raw.matches) {
        if (m.data.response !== 'ACCEPTED') continue;
        const at = time(m.data.respondedAt);
        const id = m.data.requestId;
        if (at == null || typeof id !== 'string') continue;
        const prev = firstAccepted.get(id);
        if (prev == null || at < prev) firstAccepted.set(id, at);
    }

    // Live = not withdrawn and not judged unreal (metrics.mjs, metrics 2 and 3).
    const live = requests.filter(
        (r) => !['CANCELLED', 'EXPIRED', 'REJECTED'].includes(String(r.data.status)),
    );
    const waits = live.flatMap((r) => {
        const created = time(r.data.createdAt);
        const accepted = firstAccepted.get(r.id);
        return created != null && accepted != null ? [(accepted - created) / 60_000] : [];
    });
    const reviews = requests.flatMap((r) => {
        const created = time(r.data.createdAt);
        const reviewed = time(r.data.reviewedAt);
        return created != null && reviewed != null ? [(reviewed - created) / 60_000] : [];
    });

    const alerts = raw.matches.filter(
        (m) => typeof m.data.requestId === 'string' && requestIds.has(m.data.requestId),
    );

    const kpis: Kpis = {
        donorsRegistered: raw.donors.filter((d) => inRange(time(d.data.createdAt))).length,
        donorsTotal: raw.donors.length,
        acceptedWithinHour:
            live.length === 0 ? null : waits.filter((w) => w <= 60).length / live.length,
        liveRequests: live.length,
        medianFirstAcceptMinutes: median(waits),
        acceptedRequests: waits.length,
        donationsConfirmed: raw.donations.filter(
            (d) => d.data.confirmedBy && inRange(time(d.data.donatedOn ?? d.data.createdAt)),
        ).length,
        pushSuccess:
            alerts.length === 0
                ? null
                : alerts.filter((m) => m.data.notifiedAt).length / alerts.length,
        alerts: alerts.length,
        medianReviewMinutes: median(reviews),
        waitingForReview: raw.requests.filter((r) => r.data.status === 'PENDING').length,
    };

    const zero = (): Record<Outcome, number> => ({ fulfilled: 0, open: 0, pending: 0, closed: 0 });
    const byBucket = new Map(bucketKeys(range).map((key) => [key, zero()]));
    for (const r of requests) {
        const t = time(r.data.createdAt);
        const counts = t == null ? undefined : byBucket.get(bucketKey(t, range.bucket));
        if (counts) counts[outcomeOf(r.data.status)] += 1;
    }

    const bloodTypes = BLOOD_TYPES.map((type) => ({
        type,
        requests: requests.filter((r) => r.data.patientBloodType === type).length,
        // Donors who could answer today: registered and marked available. Current, not per period.
        donors: raw.donors.filter((d) => d.data.bloodType === type && d.data.isAvailable !== false)
            .length,
    }));

    const perHospital = new Map<string, number>();
    for (const r of requests) {
        const hospital = r.data.hospital as { name?: unknown } | undefined;
        const name =
            typeof hospital?.name === 'string' ? hospital.name : String(r.data.hospitalId ?? '—');
        perHospital.set(name, (perHospital.get(name) ?? 0) + 1);
    }
    const hospitals = [...perHospital.entries()]
        .map(([name, count]) => ({ name, requests: count }))
        .sort((a, b) => b.requests - a.requests || a.name.localeCompare(b.name));

    const perDistrict = new Map<string, number>();
    for (const d of raw.donors) {
        const code = typeof d.data.districtCode === 'string' ? d.data.districtCode : null;
        if (code) perDistrict.set(code, (perDistrict.get(code) ?? 0) + 1);
    }
    const districts = raw.districts
        .map((d) => ({
            code: d.id,
            nameEn: String(d.data.nameEn ?? d.id),
            nameKm: String(d.data.nameKm ?? d.data.nameEn ?? d.id),
            donors: perDistrict.get(d.id) ?? 0,
        }))
        .sort((a, b) => b.donors - a.donors || a.nameEn.localeCompare(b.nameEn));

    return {
        range,
        kpis,
        overTime: [...byBucket.entries()].map(([key, counts]) => ({ key, counts })),
        bloodTypes,
        hospitals,
        districts,
    };
}

/** Reads the collections as the signed-in admin, then computes. */
export async function loadDashboard(range: DashboardRange): Promise<ApiResult<Dashboard>> {
    const token = await requirePortalToken();
    const names = ['donors', 'requests', 'matches', 'donations', 'districts'] as const;
    // What computeDashboard reads from a donor, and nothing else: no coordinates (ADR 0003).
    const select: Partial<Record<(typeof names)[number], string[]>> = {
        donors: ['createdAt', 'bloodType', 'isAvailable', 'districtCode'],
    };
    const results = await Promise.all(
        names.map((collection) =>
            firestoreQuery({ collection, select: select[collection] }, token),
        ),
    );
    const failed = results.find((r) => !r.ok);
    if (failed && !failed.ok) return failed;
    const [donors, requests, matches, donations, districts] = results.map((r) =>
        r.ok ? r.data : [],
    );
    return {
        ok: true,
        data: computeDashboard({ donors, requests, matches, donations, districts }, range),
    };
}
