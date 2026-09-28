import { getTranslations } from 'next-intl/server';
import AccountMenuPopup from '@/components/AccountMenuPopup';
import { portalHasPassword } from '@/lib/api/session';

/**
 * Who is signed in, and the way out. A portal with a login and no visible sign-out is a
 * shared browser at a ward desk staying signed in until the token expires on its own.
 *
 * Lives in the header's top row beside the bell and the language menu, so the account's
 * controls stop competing with the page's own (the tabs, the counts) for the toolbar row.
 * This half reads the session and the copy on the server; the popup is the client half.
 */
export default async function AccountMenu({
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
        <AccountMenuPopup
            locale={locale}
            displayName={displayName}
            // v1 has one portal role, so the badge only ever says Admin — it stays so a shared
            // machine answers "who is signed in" at a glance.
            roleLabel={role ? roles('staffRoleAdmin') : null}
            passwordHref={hasPassword ? `/${locale}/portal/password` : null}
            copy={{
                menu: t('accountMenu'),
                changePassword: password('title'),
                signOut: t('signOutCta'),
            }}
        />
    );
}
