import { defineRouting } from 'next-intl/routing';

/**
 * Khmer is the default locale — the portal's users are Cambodian hospital staff
 * (docs/po/prd.md section 5), so English-first would be the wrong default.
 */
export const routing = defineRouting({
    locales: ['km', 'en'],
    defaultLocale: 'km',
});

export type Locale = (typeof routing.locales)[number];
