import PillLink from '@/components/PillLink';
import { Button } from '@/components/ui/button';
import { IconKey, IconLogOut } from '@/components/icons';
import { getTranslations } from 'next-intl/server';
import { signOutAction } from '@/app/[locale]/sign-in/actions';
import { portalHasPassword } from '@/lib/api/session';

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
    const hasPassword = await portalHasPassword();

    return (
        <form action={signOutAction} className="flex flex-wrap items-center gap-2">
            <input type="hidden" name="locale" value={locale} />
            {/* Which account this is. v1 has one portal role, so the badge only ever says
                Admin — it stays so a shared machine answers "who is signed in" at a glance. */}
            <span className="flex items-center gap-2 pr-1">
                {displayName ? (
                    <span className="text-sm font-medium text-foreground/85">{displayName}</span>
                ) : null}
                {role ? (
                    <span
                        data-testid="portal-role"
                        className="rounded-full bg-brand/10 px-2 py-0.5 text-xs font-semibold tracking-wide text-brand uppercase"
                    >
                        {roles('staffRoleAdmin')}
                    </span>
                ) : null}
            </span>
            {hasPassword ? (
                <PillLink
                    href={`/${locale}/portal/password`}
                    icon={<IconKey />}
                    testId="change-password-link"
                >
                    {password('title')}
                </PillLink>
            ) : null}
            <Button type="submit" variant="outline" className="rounded-full" data-testid="sign-out">
                <IconLogOut />
                {t('signOutCta')}
            </Button>
        </form>
    );
}
