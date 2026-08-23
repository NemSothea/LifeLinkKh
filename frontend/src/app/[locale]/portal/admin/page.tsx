import { getTranslations } from 'next-intl/server';
import Link from 'next/link';
import { listCandidates, listStaff } from '@/lib/api/admin';
import { portalRole } from '@/lib/api/dev-auth';
import { listHospitals } from '@/lib/api/hospitals';
import { IconAlertTriangle, IconCheck } from '../icons';
import { assignStaffRoleAction } from './actions';

/**
 * TM-AUTH-001 E1 as a screen: an ADMIN grants HOSPITAL/ADMIN access to someone who has
 * already signed in once, rather than Tech Lead hand-running `V8__portal_access.sql`.
 *
 * A Server Component, like the rest of the portal — `portalRole()` reads the dev bearer
 * token's own claim to decide what to render, but the real gate is `SecurityConfig` on
 * the backend; a wrong guess here only changes what this page shows, never what the API
 * allows.
 */
export default async function AdminPage({
    params,
    searchParams,
}: {
    params: Promise<{ locale: string }>;
    searchParams: Promise<{ promoted?: string; promoteError?: string }>;
}) {
    const { locale } = await params;
    const { promoted, promoteError } = await searchParams;
    const t = await getTranslations('admin');

    if (portalRole() !== 'ADMIN') {
        return (
            <main className="mx-auto max-w-2xl p-6 sm:p-10">
                <p
                    data-testid="admin-forbidden"
                    className="flex items-center gap-2 rounded-xl border border-black/10 bg-black/[0.02] p-6 text-black/70 dark:border-white/15 dark:bg-white/[0.04] dark:text-white/70"
                >
                    <IconAlertTriangle className="h-5 w-5 shrink-0" />
                    {t('adminsOnly')}
                </p>
            </main>
        );
    }

    const [staffResult, candidatesResult, hospitalsResult] = await Promise.all([
        listStaff(),
        listCandidates(),
        listHospitals(),
    ]);

    const staff = staffResult.ok ? staffResult.data : [];
    const candidates = candidatesResult.ok ? candidatesResult.data : [];
    const hospitals = hospitalsResult.ok ? hospitalsResult.data : [];

    return (
        <main className="mx-auto max-w-2xl p-6 sm:p-10">
            <header className="mb-8 flex flex-wrap items-end justify-between gap-3">
                <div>
                    <p className="text-sm font-medium tracking-wide text-red-700 uppercase dark:text-red-400">
                        LifeLink KH
                    </p>
                    <h1 className="text-3xl font-bold tracking-tight">{t('title')}</h1>
                </div>
                <Link
                    href={`/${locale}/portal`}
                    className="text-sm font-medium text-black/60 underline-offset-4 hover:underline dark:text-white/60"
                >
                    {t('backToRequests')}
                </Link>
            </header>

            {promoted ? (
                <p
                    data-testid="promote-success"
                    className="mb-6 flex items-center gap-2 rounded-xl border border-emerald-300 bg-emerald-50 p-4 text-emerald-800 dark:border-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300"
                >
                    <IconCheck className="h-5 w-5 shrink-0" />
                    {t('promoted', { name: promoted })}
                </p>
            ) : null}

            {promoteError ? (
                <p
                    data-testid="promote-error"
                    className="mb-6 flex items-center gap-2 rounded-xl border border-red-300 bg-red-50 p-4 text-red-700 dark:border-red-800 dark:bg-red-950/60 dark:text-red-400"
                >
                    <IconAlertTriangle className="h-5 w-5 shrink-0" />
                    {t('promoteFailed')}
                </p>
            ) : null}

            <section className="mb-10">
                <h2 className="mb-3 text-lg font-semibold">{t('currentStaffHeading')}</h2>
                {staff.length === 0 ? (
                    <p
                        data-testid="staff-empty"
                        className="text-sm text-black/50 dark:text-white/50"
                    >
                        {t('noStaffYet')}
                    </p>
                ) : (
                    <ul data-testid="staff-list" className="flex flex-col gap-2">
                        {staff.map((member) => (
                            <li
                                key={member.id}
                                data-testid={`staff-${member.id}`}
                                className="flex items-center justify-between gap-3 rounded-xl border border-black/10 bg-white p-3 text-sm dark:border-white/10 dark:bg-white/[0.03]"
                            >
                                <span className="font-medium">
                                    {member.displayName ?? member.id}
                                </span>
                                <span className="text-black/60 dark:text-white/60">
                                    {member.role === 'ADMIN'
                                        ? t('staffRoleAdmin')
                                        : t('staffRoleHospital')}
                                    {member.hospitalName ? ` · ${member.hospitalName}` : ''}
                                </span>
                            </li>
                        ))}
                    </ul>
                )}
            </section>

            <section>
                <h2 className="mb-1 text-lg font-semibold">{t('promoteHeading')}</h2>
                <p className="mb-4 text-sm text-black/60 dark:text-white/60">{t('promoteHint')}</p>

                {candidates.length === 0 ? (
                    <p
                        data-testid="candidates-empty"
                        className="text-sm text-black/50 dark:text-white/50"
                    >
                        {t('noCandidates')}
                    </p>
                ) : (
                    <form
                        action={assignStaffRoleAction}
                        className="flex flex-col gap-4 rounded-2xl border border-black/10 bg-white p-5 dark:border-white/15 dark:bg-white/[0.03]"
                    >
                        <input type="hidden" name="locale" value={locale} />

                        <label className="flex flex-col gap-1 text-sm">
                            {t('candidateLabel')}
                            <select
                                name="userId"
                                required
                                defaultValue=""
                                data-testid="admin-candidate-select"
                                className="rounded-md border border-black/20 px-2 py-1.5 dark:border-white/25 dark:bg-black/30"
                            >
                                <option value="" disabled>
                                    {t('candidateHint')}
                                </option>
                                {candidates.map((candidate) => (
                                    <option key={candidate.id} value={candidate.id}>
                                        {candidate.displayName} · {candidate.role}
                                    </option>
                                ))}
                            </select>
                        </label>

                        <label className="flex flex-col gap-1 text-sm">
                            {t('roleLabel')}
                            <select
                                name="role"
                                required
                                defaultValue="HOSPITAL"
                                data-testid="admin-role-select"
                                className="rounded-md border border-black/20 px-2 py-1.5 dark:border-white/25 dark:bg-black/30"
                            >
                                <option value="HOSPITAL">{t('staffRoleHospital')}</option>
                                <option value="ADMIN">{t('staffRoleAdmin')}</option>
                            </select>
                        </label>

                        <label className="flex flex-col gap-1 text-sm">
                            {t('hospitalLabel')}
                            <select
                                name="hospitalId"
                                data-testid="admin-hospital-select"
                                className="rounded-md border border-black/20 px-2 py-1.5 dark:border-white/25 dark:bg-black/30"
                            >
                                <option value="">{t('hospitalNone')}</option>
                                {hospitals.map((hospital) => (
                                    <option key={hospital.id} value={hospital.id}>
                                        {hospital.name}
                                    </option>
                                ))}
                            </select>
                        </label>

                        <button
                            type="submit"
                            data-testid="admin-submit"
                            className="flex items-center justify-center gap-1.5 self-start rounded-md bg-red-700 px-4 py-2 text-sm font-medium text-white shadow-sm transition-colors hover:bg-red-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"
                        >
                            <IconCheck className="h-4 w-4" />
                            {t('submitCta')}
                        </button>
                    </form>
                )}
            </section>
        </main>
    );
}
