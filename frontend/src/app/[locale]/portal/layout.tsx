import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { pageMetadata } from '@/lib/seo';

/**
 * `/portal` is the public request board (DEC-009), and signed in it is the admin portal. It is
 * public, but it names the donors who said yes, so it stays out of search results: an indexed
 * page would tie a person to a hospital and a blood type, and a search cache would keep that
 * after they delete their account (DEC-016). Every admin sub-page inherits the tag. Not blocked
 * in robots.txt, because a crawler that cannot fetch a page never sees its `noindex`.
 */
export async function generateMetadata({
    params,
}: {
    params: Promise<{ locale: string }>;
}): Promise<Metadata> {
    const { locale } = await params;
    const t = await getTranslations({ locale, namespace: 'portal' });
    return pageMetadata({ locale, path: '/portal', title: t('title'), index: false });
}

export default function PortalLayout({ children }: { children: React.ReactNode }) {
    return children;
}
