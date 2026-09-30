import type { MetadataRoute } from 'next';
import { SITE_URL } from '@/lib/seo';

/**
 * Crawl everything except the API. `/portal` and `/sign-in` are deliberately *not* disallowed:
 * they carry `noindex`, and a crawler that is refused the page never reads that tag, so it could
 * still list the bare URL.
 */
export default function robots(): MetadataRoute.Robots {
    return {
        rules: { userAgent: '*', allow: '/', disallow: '/api/' },
        sitemap: `${SITE_URL}/sitemap.xml`,
        host: SITE_URL,
    };
}
