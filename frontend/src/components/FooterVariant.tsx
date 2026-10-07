'use client';
import type { ReactNode } from 'react';
import { usePathname } from '@/i18n/navigation';

const PUBLIC_PAGES = new Set(['/', '/download', '/getting-blood', '/privacy', '/delete-account']);
/** Keep the public site footer together while retaining the portal's existing footer. */
export default function FooterVariant({
    publicFooter,
    portalFooter,
}: {
    publicFooter: ReactNode;
    portalFooter: ReactNode;
}) {
    const pathname = usePathname();
    return PUBLIC_PAGES.has(pathname) ? publicFooter : portalFooter;
}
