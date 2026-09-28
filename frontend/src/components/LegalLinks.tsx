import { getTranslations } from 'next-intl/server';
import PillLink from '@/components/PillLink';
import { IconShield, IconTrash } from '@/components/icons';

/**
 * The two pages the Play listing points at (privacy policy, account deletion), linked from every
 * public entry point so a donor or a reviewer can reach them without knowing the URLs. Buttons
 * with an icon, not footer fine print: they answer "what do you keep about me, and how do I make
 * you stop", and someone looking for that should not have to hunt.
 */
export default async function LegalLinks({ locale }: { locale: string }) {
    const t = await getTranslations('privacy');
    return (
        <nav className="flex flex-wrap gap-2" data-testid="legal-links">
            <PillLink href={`/${locale}/privacy`} icon={<IconShield />}>
                {t('title')}
            </PillLink>
            <PillLink href={`/${locale}/delete-account`} icon={<IconTrash />}>
                {t('deleteLink')}
            </PillLink>
        </nav>
    );
}
