'use client';

import { useEffect, useRef, useState, useSyncExternalStore } from 'react';
import { useTranslations } from 'next-intl';
import { useTheme } from 'next-themes';
import { Check, Monitor, Moon, Sun } from 'lucide-react';

const OPTIONS = [
    { value: 'light', icon: Sun, label: 'themeLight' },
    { value: 'dark', icon: Moon, label: 'themeDark' },
    { value: 'system', icon: Monitor, label: 'themeSystem' },
] as const;

const subscribe = () => () => {};

/**
 * Light / Dark / Auto, beside the language switcher and built the same way: a 44px button that
 * opens a small menu, Escape or a click outside closes it.
 */
export default function ThemeSwitcher() {
    const t = useTranslations('app');
    const { theme, setTheme } = useTheme();
    // The server cannot know the stored choice; render the neutral icon until hydrated.
    const mounted = useSyncExternalStore(
        subscribe,
        () => true,
        () => false,
    );
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

    const current = OPTIONS.find((o) => o.value === (mounted ? theme : 'system')) ?? OPTIONS[2];
    const CurrentIcon = current.icon;

    return (
        <div ref={rootRef} data-testid="theme-switcher" className="relative text-sm">
            <button
                ref={buttonRef}
                type="button"
                onClick={() => setOpen((v) => !v)}
                aria-haspopup="menu"
                aria-expanded={open}
                aria-label={`${t('theme')}: ${t(current.label)}`}
                data-testid="theme-switcher-button"
                className="flex size-11 items-center justify-center rounded-full border border-border bg-secondary/60 text-foreground/80 transition-colors hover:bg-secondary hover:text-foreground"
            >
                <CurrentIcon className="size-4" aria-hidden="true" />
            </button>

            {open && (
                <div
                    role="menu"
                    aria-label={t('theme')}
                    className="animate-pop absolute right-0 z-50 mt-2 w-44 overflow-hidden rounded-xl border border-border bg-popover p-1 text-popover-foreground shadow-lg"
                >
                    {OPTIONS.map(({ value, icon: Icon, label }) => {
                        const active = mounted && theme === value;
                        return (
                            <button
                                key={value}
                                type="button"
                                role="menuitemradio"
                                aria-checked={active}
                                onClick={() => {
                                    setTheme(value);
                                    setOpen(false);
                                }}
                                data-testid={`theme-switcher-${value}`}
                                className={`flex min-h-11 w-full items-center gap-2 rounded-lg px-3 transition-colors ${
                                    active
                                        ? 'bg-brand/10 font-semibold text-brand'
                                        : 'text-foreground/80 hover:bg-secondary hover:text-foreground'
                                }`}
                            >
                                <Icon className="size-4" aria-hidden="true" />
                                <span className="flex-1 text-left">{t(label)}</span>
                                {active && <Check className="size-4" aria-hidden="true" />}
                            </button>
                        );
                    })}
                </div>
            )}
        </div>
    );
}
