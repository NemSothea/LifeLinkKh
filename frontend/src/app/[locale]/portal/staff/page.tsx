import { getTranslations } from 'next-intl/server';
import Link from 'next/link';
import { listCandidates, listStaff } from '@/lib/api/admin';
import { redirect } from 'next/navigation';
import { hasPortalSession, portalRole } from '@/lib/api/session';
import { listHospitals } from '@/lib/api/hospitals';
import { IconAlertTriangle, IconCheck } from '@/components/icons';
import { assignStaffRoleAction } from './actions';
import SearchableSelect from './searchable-select';
import StaffRoleFields from './staff-role-fields';
import CreateAccountForm from './create-account-form';
import StaffRowActions from './staff-row-actions';
import { portalUserId } from '@/lib/api/session';

/**
 * TM-AUTH-001 E1 as a screen: an ADMIN grants HOSPITAL/ADMIN access to someone who has
 * already signed in once, rather than Tech Lead hand-running `V8__portal_access.sql`.
 *
 * Lives at `/portal/staff`, not `/portal/admin`. Everything about this page says "staff"
 * — its title, the link that reaches it, the endpoint behind it (`/admin/staff`) — and
 * only the route said "admin", which is who may open it rather than what it is for.
 * `/portal/admin` still resolves, permanently redirected in `next.config.ts`.
 *
 * A Server Component, like the rest of the portal — `portalRole()` reads the session
 * cookie's own claim to decide what to render, but the real gate is `SecurityConfig` on
 * the backend; a wrong guess here only changes what this page shows, never what the API
 * allows.
 */
export default async function AdminPage({
    params,
    searchParams,
}: {
    params: Promise<{ locale: string }>;
    searchParams: Promise<{
        promoted?: string;
        promoteError?: string;
        created?: string;
        createError?: string;
        revoked?: string;
        demoted?: string;
        actionError?: string;
    }>;
}) {
    const { locale } = await params;
    if (!(await hasPortalSession())) {
        redirect(`/${locale}/sign-in`);
    }

    const { promoted, promoteError, created, createError, revoked, demoted, actionError } =
        await searchParams;
    const signedInAs = await portalUserId();
    const t = await getTranslations('admin');
    const portal = await getTranslations('portal');

    if ((await portalRole()) !== 'ADMIN') {
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
                    <p className="text-sm font-semibold tracking-wide text-brand uppercase">
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

            {revoked || demoted ? (
                <p
                    data-testid="action-success"
                    className="mb-6 flex items-center gap-2 rounded-xl border border-emerald-300 bg-emerald-50 p-4 text-emerald-800 dark:border-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300"
                >
                    <IconCheck className="h-5 w-5 shrink-0" />
                    {revoked ? t('revoked') : t('demoted', { name: demoted ?? '' })}
                </p>
            ) : null}

            {actionError ? (
                <p
                    data-testid="action-error"
                    className="mb-6 flex items-center gap-2 rounded-xl border border-red-300 bg-red-50 p-4 text-red-700 dark:border-red-800 dark:bg-red-950/60 dark:text-red-400"
                >
                    <IconAlertTriangle className="h-5 w-5 shrink-0" />
                    {actionError === 'rule' ? t('actionFailedLastAdmin') : t('actionFailed')}
                </p>
            ) : null}

            {created ? (
                <p
                    data-testid="create-success"
                    className="mb-6 flex items-center gap-2 rounded-xl border border-emerald-300 bg-emerald-50 p-4 text-emerald-800 dark:border-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300"
                >
                    <IconCheck className="h-5 w-5 shrink-0" />
                    {t('created', { name: created })}
                </p>
            ) : null}

            {createError ? (
                <p
                    data-testid="create-error"
                    className="mb-6 flex items-center gap-2 rounded-xl border border-red-300 bg-red-50 p-4 text-red-700 dark:border-red-800 dark:bg-red-950/60 dark:text-red-400"
                >
                    <IconAlertTriangle className="h-5 w-5 shrink-0" />
                    {createError === 'taken' ? t('createFailedTaken') : t('createFailed')}
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
                                {/* A staff account seeded by V8__portal_access.sql predates
                                    display_name (V10) and has never signed in, so there is
                                    genuinely no name to show. A raw UUID is the least useful
                                    thing that could go there — it tells an admin nothing about
                                    who the account belongs to, and two nameless rows look
                                    identical anyway. Say what is actually true, and keep a
                                    short id alongside it so the rows stay distinguishable. */}
                                {member.displayName ? (
                                    <span className="font-medium">{member.displayName}</span>
                                ) : (
                                    <span className="flex items-baseline gap-2">
                                        <span className="text-black/50 italic dark:text-white/50">
                                            {t('staffNoName')}
                                        </span>
                                        <span className="font-mono text-xs text-black/35 dark:text-white/35">
                                            {member.id.slice(0, 8)}
                                        </span>
                                    </span>
                                )}
                                <span className="flex items-center gap-3">
                                    <span className="text-black/60 dark:text-white/60">
                                        {member.role === 'ADMIN'
                                            ? t('staffRoleAdmin')
                                            : t('staffRoleHospital')}
                                        {member.hospitalName ? ` · ${member.hospitalName}` : ''}
                                    </span>
                                    {member.id === signedInAs ? (
                                        // No buttons on your own row. The server refuses it anyway
                                        // (CANNOT_TARGET_SELF); a button whose only outcome is an
                                        // error is worse than no button.
                                        <span className="text-xs text-black/40 dark:text-white/40">
                                            ({t('youLabel')})
                                        </span>
                                    ) : (
                                        <StaffRowActions
                                            userId={member.id}
                                            displayName={member.displayName ?? member.id.slice(0, 8)}
                                            role={member.role}
                                            locale={locale}
                                            hospitals={hospitals}
                                            copy={{
                                                revokeCta: t('revokeCta'),
                                                demoteCta: t('demoteCta'),
                                                revokeDialogTitle: t('revokeDialogTitle'),
                                                revokeDialogBody: t('revokeDialogBody'),
                                                demoteDialogTitle: t('demoteDialogTitle'),
                                                demoteDialogBody: t('demoteDialogBody'),
                                                confirmRevokeCta: t('confirmRevokeCta'),
                                                confirmDemoteCta: t('confirmDemoteCta'),
                                                cancelCta: portal('cancelCta'),
                                                hospitalLabel: t('hospitalLabel'),
                                                hospitalHint: t('hospitalHint'),
                                                noMatches: t('noMatches'),
                                                selectRequired: t('selectRequired'),
                                            }}
                                        />
                                    )}
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
                            <SearchableSelect
                                name="userId"
                                required
                                testId="admin-candidate-select"
                                placeholder={t('candidateHint')}
                                noMatchesLabel={t('noMatches')}
                                requiredMessage={t('selectRequired')}
                                options={candidates.map((candidate) => ({
                                    value: candidate.id,
                                    label: candidate.displayName,
                                    sublabel: candidate.role,
                                    searchText: `${candidate.displayName} ${candidate.role}`,
                                }))}
                            />
                        </label>

                        <StaffRoleFields
                            hospitals={hospitals}
                            copy={{
                                roleLabel: t('roleLabel'),
                                staffRoleHospital: t('staffRoleHospital'),
                                staffRoleAdmin: t('staffRoleAdmin'),
                                hospitalLabel: t('hospitalLabel'),
                                hospitalHint: t('hospitalHint'),
                                adminNoHospital: t('adminNoHospital'),
                                noMatches: t('noMatches'),
                                selectRequired: t('selectRequired'),
                            }}
                        />

                        <button
                            type="submit"
                            data-testid="admin-submit"
                            className="flex items-center justify-center gap-1.5 self-start rounded-xl bg-brand px-4 py-2 text-sm font-medium text-white shadow-sm transition-colors hover:opacity-90 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand"
                        >
                            <IconCheck className="h-4 w-4" />
                            {t('submitCta')}
                        </button>
                    </form>
                )}
            </section>

            <section className="mt-10">
                <h2 className="mb-1 text-lg font-semibold">{t('createHeading')}</h2>
                <p className="mb-4 text-sm text-black/60 dark:text-white/60">{t('createHint')}</p>
                <CreateAccountForm
                    locale={locale}
                    hospitals={hospitals}
                    copy={{
                        usernameLabel: t('usernameLabel'),
                        usernameHint: t('usernameHint'),
                        passwordLabel: t('passwordLabel'),
                        passwordHint: t('passwordHint'),
                        nameLabel: t('nameLabel'),
                        nameHint: t('nameHint'),
                        roleLabel: t('roleLabel'),
                        staffRoleHospital: t('staffRoleHospital'),
                        staffRoleAdmin: t('staffRoleAdmin'),
                        hospitalLabel: t('hospitalLabel'),
                        hospitalHint: t('hospitalHint'),
                        adminNoHospital: t('adminNoHospital'),
                        noMatches: t('noMatches'),
                        selectRequired: t('selectRequired'),
                        createCta: t('createCta'),
                    }}
                />
            </section>
        </main>
    );
}
