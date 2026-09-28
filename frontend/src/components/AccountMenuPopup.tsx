'use client';

import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { KeyRound } from 'lucide-react';
import { IconChevron, IconLogOut } from '@/components/icons';
import { signOutAction } from '@/app/[locale]/sign-in/actions';

/**
 * The signed-in admin's button in the header's top row: their initial, which opens a small menu
 * with who is signed in, change password and sign out. Same open/close behaviour as the
 * language menu beside it — outside tap and Escape close it.
 */
export default function AccountMenuPopup({
    locale,
    displayName,
    roleLabel,
    passwordHref,
    copy,
}: {
    locale: string;
    displayName: string | null;
    roleLabel: string | null;
    /** Absent for a Google-only admin, who has no portal password to change. */
    passwordHref: string | null;
    copy: { menu: string; changePassword: string; signOut: string };
}) {
    const [open, setOpen] = useState(false);
    const rootRef = useRef<HTMLDivElement>(null);
    const buttonRef = useRef<HTMLButtonElement>(null);

    useEffect(() => {
        if (!open) return;
        const onPointerDown = (e: PointerEvent) => {
            if (!rootRef.current?.contains(e.target as Node)) setOpen(false);
        };
        const onKeyDown = (e: KeyboardEvent) => {
            if (e.key === 'Escape') {
                setOpen(false);
                buttonRef.current?.focus();
            }
        };
        document.addEventListener('pointerdown', onPointerDown);
        document.addEventListener('keydown', onKeyDown);
        return () => {
            document.removeEventListener('pointerdown', onPointerDown);
            document.removeEventListener('keydown', onKeyDown);
        };
    }, [open]);

    const initial = (displayName?.trim()[0] ?? '?').toUpperCase();
    const itemClass =
        'flex min-h-11 w-full items-center gap-3 rounded-lg px-3 text-left text-foreground/80 transition-colors hover:bg-secondary hover:text-foreground';

    return (
        <div ref={rootRef} data-testid="account-menu" className="relative text-sm">
            <button
                ref={buttonRef}
                type="button"
                onClick={() => setOpen((v) => !v)}
                aria-haspopup="menu"
                aria-expanded={open}
                aria-label={displayName ? `${copy.menu}: ${displayName}` : copy.menu}
                data-testid="account-menu-button"
                className="flex min-h-11 items-center gap-1.5 rounded-full border border-border bg-secondary/40 py-1 pr-2.5 pl-1 transition-colors hover:bg-secondary focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-none"
            >
                <span className="flex size-8 items-center justify-center rounded-full bg-primary text-sm font-semibold text-primary-foreground">
                    {initial}
                </span>
                <IconChevron
                    className={`h-4 w-4 text-muted-foreground transition-transform ${open ? 'rotate-180' : ''}`}
                />
            </button>

            {open && (
                <div
                    role="menu"
                    aria-label={copy.menu}
                    className="animate-pop absolute right-0 z-50 mt-2 w-60 overflow-hidden rounded-xl border border-border bg-popover p-1 text-popover-foreground shadow-lg"
                >
                    <div className="flex items-center gap-3 px-3 py-3">
                        <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-primary font-semibold text-primary-foreground">
                            {initial}
                        </span>
                        <div className="min-w-0">
                            {displayName ? (
                                <p className="truncate font-medium">{displayName}</p>
                            ) : null}
                            {roleLabel ? (
                                <span
                                    data-testid="portal-role"
                                    className="mt-0.5 inline-block rounded-full bg-brand/10 px-2 py-0.5 text-xs font-semibold text-brand"
                                >
                                    {roleLabel}
                                </span>
                            ) : null}
                        </div>
                    </div>
                    <div className="my-1 h-px bg-border" />
                    {passwordHref ? (
                        <Link
                            href={passwordHref}
                            role="menuitem"
                            onClick={() => setOpen(false)}
                            data-testid="change-password-link"
                            className={itemClass}
                        >
                            <KeyRound className="size-4 shrink-0" aria-hidden="true" />
                            {copy.changePassword}
                        </Link>
                    ) : null}
                    <form action={signOutAction}>
                        <input type="hidden" name="locale" value={locale} />
                        <button
                            type="submit"
                            role="menuitem"
                            data-testid="sign-out"
                            className={`${itemClass} text-brand hover:text-brand`}
                        >
                            <IconLogOut className="h-4 w-4 shrink-0" />
                            {copy.signOut}
                        </button>
                    </form>
                </div>
            )}
        </div>
    );
}
