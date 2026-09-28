'use client';

import { ThemeProvider as NextThemesProvider } from 'next-themes';
import type { ReactNode } from 'react';

/**
 * Light / Dark / Auto. `class` on <html>, which the `dark:` variant in globals.css follows;
 * Auto (the default) tracks the device setting. The choice lives in this browser's
 * localStorage only — a display preference, not data about the person.
 */
export default function ThemeProvider({ children }: { children: ReactNode }) {
    return (
        <NextThemesProvider
            attribute="class"
            defaultTheme="system"
            enableSystem
            disableTransitionOnChange
        >
            {children}
        </NextThemesProvider>
    );
}
