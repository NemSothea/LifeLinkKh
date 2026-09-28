import Link from 'next/link';
import type { ReactNode } from 'react';
import SiteControls from '@/components/SiteControls';
import { IconDroplet } from '@/components/icons';

/**
 * The top of every page, one shape: the LifeLink mark (a link home) with the theme and language
 * buttons on one row, then the page title on a full-width line of its own. Sharing a row with the
 * buttons squeezed titles like "Admin sign-in" onto two lines on a phone.
 */
export default function PageHeader({
    locale,
    title,
    subtitle,
    children,
    className = 'mb-8',
}: {
    locale: string;
    title: ReactNode;
    subtitle?: ReactNode;
    /** Anything that belongs under the title, such as the portal's actions. */
    children?: ReactNode;
    className?: string;
}) {
    return (
        <header className={`flex flex-col gap-5 ${className}`}>
            <div className="flex items-center justify-between gap-3">
                <Link
                    href={`/${locale}`}
                    className="flex min-h-11 items-center gap-2.5 rounded-xl focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-none"
                >
                    <span className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary text-primary-foreground shadow-sm">
                        <IconDroplet className="h-5 w-5" />
                    </span>
                    <span className="text-sm font-semibold tracking-wide whitespace-nowrap text-brand uppercase">
                        LifeLink KH
                    </span>
                </Link>
                <SiteControls />
            </div>
            <div>
                <h1 className="text-2xl font-bold tracking-tight text-balance sm:text-3xl">
                    {title}
                </h1>
                {subtitle ? (
                    <p className="mt-1.5 text-sm text-muted-foreground">{subtitle}</p>
                ) : null}
            </div>
            {children}
        </header>
    );
}
