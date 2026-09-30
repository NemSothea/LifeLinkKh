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
            // next-themes renders an inline <script> that sets the theme class before paint.
            // The server copy is the one that runs; on the client React 19 warns about any
            // script it renders, so there it is marked inert JSON. The tag already has
            // suppressHydrationWarning, so the differing `type` does not trip hydration.
            scriptProps={typeof window === 'undefined' ? undefined : { type: 'application/json' }}
        >
            {children}
        </NextThemesProvider>
    );
}
