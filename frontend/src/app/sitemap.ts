import type { MetadataRoute } from 'next';
import { routing } from '@/i18n/routing';
import { INDEXED_PATHS, SITE_URL } from '@/lib/seo';

/**
 * Every indexable page in both languages, each entry listing its other-language twin so search
 * engines serve Khmer to Khmer searches. `/portal` and `/sign-in` are left out on purpose
 * (`INDEXED_PATHS`). No `lastModified`: the pages carry no real date, and a made-up one only
 * teaches crawlers to ignore it.
 */
export default function sitemap(): MetadataRoute.Sitemap {
    return INDEXED_PATHS.flatMap((path) =>
        routing.locales.map((locale) => ({
            url: `${SITE_URL}/${locale}${path}`,
            changeFrequency: 'monthly' as const,
            priority: path === '' ? 1 : 0.7,
            alternates: {
                languages: Object.fromEntries(
                    routing.locales.map((l) => [l, `${SITE_URL}/${l}${path}`]),
                ),
            },
        })),
    );
}
