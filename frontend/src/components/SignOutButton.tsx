import Link from 'next/link';
import { getTranslations } from 'next-intl/server';
import { signOutAction } from '@/app/[locale]/sign-in/actions';

/**
 * Who is signed in, and the way out. A portal with a login and no visible sign-out is a
 * shared browser at a ward desk staying signed in until the token expires on its own.
 *
 * A plain form posting to a Server Action, not a client component: signing out is one
 * `cookies().delete()` and a redirect, and nothing about it needs to run in the browser.
 */
export default async function SignOutButton({
    locale,
    displayName,
    role,
}: {
    locale: string;
    displayName: string | null;
    role: string | null;
}) {
    const t = await getTranslations('signIn');
    const roles = await getTranslations('admin');
    const password = await getTranslations('password');

    return (
        <form action={signOutAction} className="flex items-center gap-2">
            <input type="hidden" name="locale" value={locale} />
            {/* Which account this is, and what it can do. Before this the role was only
                inferable from whether the "Manage staff" link had appeared — and on a shared
                ward machine, "am I the admin or this one hospital?" is worth answering
                without a click. */}
            <span className="hidden items-baseline gap-2 sm:flex">
                {displayName ? (
                    <span className="text-sm text-black/60 dark:text-white/60">{displayName}</span>
                ) : null}
                {role ? (
                    <span
                        data-testid="portal-role"
                        className={`rounded-full px-2 py-0.5 text-xs font-semibold tracking-wide uppercase ${
                            role === 'ADMIN'
                                ? 'bg-brand/10 text-brand'
                                : 'bg-black/[0.05] text-black/60 dark:bg-white/10 dark:text-white/60'
                        }`}
                    >
                        {role === 'ADMIN' ? roles('staffRoleAdmin') : roles('staffRoleHospital')}
                    </span>
                ) : null}
            </span>
            <Link
                href={`/${locale}/portal/password`}
                data-testid="change-password-link"
                className="text-sm font-medium text-black/60 underline-offset-4 hover:underline dark:text-white/60"
            >
                {password('title')}
            </Link>
            <button
                type="submit"
                data-testid="sign-out"
                className="rounded-full border border-black/10 px-3 py-1.5 text-sm font-medium text-black/70 transition-colors hover:bg-black/[0.03] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:border-white/15 dark:text-white/70 dark:hover:bg-white/[0.05]"
            >
                {t('signOutCta')}
            </button>
        </form>
    );
}
