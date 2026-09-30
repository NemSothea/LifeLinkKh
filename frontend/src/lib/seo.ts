import type { Metadata } from 'next';
import { routing, type Locale } from '@/i18n/routing';

/**
 * Where the portal is served. `lifelinkkh.vercel.app` until a free custom domain exists; moving
 * is one env change on Vercel, and every canonical, hreflang and sitemap URL follows it.
 */
export const SITE_URL = (
    process.env.NEXT_PUBLIC_SITE_URL?.trim() || 'https://lifelinkkh.vercel.app'
).replace(/\/+$/, '');

export const SOURCE_URL = 'https://github.com/NemSothea/LifeLinkKh';

/**
 * The pages search engines may index. `/portal` is public too, but it is not here: the board
 * names the donors who accepted, and a search result would tie a person to a hospital and a
 * blood type long after they deleted their account (DEC-016). It and `/sign-in` are `noindex`.
 */
export const INDEXED_PATHS = [
    '',
    '/getting-blood',
    '/download',
    '/privacy',
    '/delete-account',
] as const;

const OG_LOCALE: Record<Locale, string> = { km: 'km_KH', en: 'en_US' };

/**
 * `app/opengraph-image.png`, bilingual and already rendered in Kantumruy Pro. Named here because
 * a page that sets its own `openGraph` loses the file-convention image (Next.js replaces the
 * parent's object), and link previews on Telegram and Facebook would go blank.
 */
const OG_IMAGE = {
    url: '/opengraph-image.png',
    width: 1200,
    height: 630,
    type: 'image/png',
    alt: 'LifeLink KH (ជីវិត) — a free app connecting voluntary blood donors in Phnom Penh with families who urgently need blood.',
};

/** Canonical for this locale, plus one hreflang per locale and `x-default` on Khmer. */
export function localizedAlternates(
    locale: string,
    path = '',
): NonNullable<Metadata['alternates']> {
    const languages: Record<string, string> = {};
    for (const l of routing.locales) languages[l] = `/${l}${path}`;
    languages['x-default'] = `/${routing.defaultLocale}${path}`;
    return { canonical: `/${locale}${path}`, languages };
}

/**
 * A page's full metadata. Next.js replaces, rather than merges, a parent's `openGraph` and
 * `alternates`, so every page states all of it — otherwise a page would inherit the home page's
 * canonical and tell Google it is a duplicate of `/`.
 */
export function pageMetadata({
    locale,
    path,
    title,
    description,
    index = true,
}: {
    locale: string;
    path: string;
    title?: string;
    description?: string;
    index?: boolean;
}): Metadata {
    const alternateLocale = routing.locales.filter((l) => l !== locale).map((l) => OG_LOCALE[l]);
    return {
        ...(title ? { title } : {}),
        ...(description ? { description } : {}),
        alternates: localizedAlternates(locale, path),
        openGraph: {
            type: 'website',
            siteName: 'LifeLink KH',
            url: `/${locale}${path}`,
            locale: OG_LOCALE[locale as Locale] ?? OG_LOCALE.km,
            alternateLocale,
            images: [OG_IMAGE],
            ...(title ? { title } : {}),
            ...(description ? { description } : {}),
        },
        twitter: {
            card: 'summary_large_image',
            images: [OG_IMAGE.url],
            ...(title ? { title } : {}),
            ...(description ? { description } : {}),
        },
        ...(index ? {} : { robots: { index: false, follow: false } }),
    };
}

/**
 * JSON for a `<script type="application/ld+json">`. `<` is escaped so a string in the data can
 * never close the script tag (the Next.js JSON-LD guide's own advice).
 */
export function jsonLd(data: object): string {
    return JSON.stringify(data).replace(/</g, '\\u003c');
}

export function siteJsonLd(locale: string, description: string) {
    return {
        '@context': 'https://schema.org',
        '@graph': [
            {
                '@type': 'Organization',
                '@id': `${SITE_URL}/#organization`,
                name: 'LifeLink KH',
                alternateName: 'ជីវិត',
                url: SITE_URL,
                logo: `${SITE_URL}/icon.png`,
                sameAs: [SOURCE_URL],
            },
            {
                '@type': 'WebSite',
                '@id': `${SITE_URL}/#website`,
                name: 'LifeLink KH',
                alternateName: 'ជីវិត — LifeLink KH',
                url: `${SITE_URL}/${locale}`,
                description,
                inLanguage: [...routing.locales],
                publisher: { '@id': `${SITE_URL}/#organization` },
            },
        ],
    };
}

/** No `aggregateRating`: there are no real ratings, and inventing one is a Google policy breach. */
export function mobileAppJsonLd({
    locale,
    description,
    downloadUrl,
    version,
}: {
    locale: string;
    description: string;
    downloadUrl: string;
    version?: string;
}) {
    return {
        '@context': 'https://schema.org',
        '@type': 'MobileApplication',
        name: 'LifeLink KH',
        alternateName: 'ជីវិត',
        description,
        operatingSystem: 'Android',
        applicationCategory: 'HealthApplication',
        downloadUrl,
        installUrl: `${SITE_URL}/${locale}/download`,
        ...(version ? { softwareVersion: version } : {}),
        inLanguage: [...routing.locales],
        offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
        publisher: { '@id': `${SITE_URL}/#organization` },
    };
}
