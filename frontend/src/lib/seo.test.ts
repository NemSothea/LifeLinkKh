import { describe, expect, it } from 'vitest';
import robots from '@/app/robots';
import sitemap from '@/app/sitemap';
import {
    INDEXED_PATHS,
    SITE_URL,
    jsonLd,
    localizedAlternates,
    mobileAppJsonLd,
    pageMetadata,
} from './seo';

describe('localizedAlternates', () => {
    it('points the canonical at its own locale and lists both languages plus x-default', () => {
        expect(localizedAlternates('en', '/download')).toEqual({
            canonical: '/en/download',
            languages: { km: '/km/download', en: '/en/download', 'x-default': '/km/download' },
        });
    });
});

describe('pageMetadata', () => {
    it('gives every page its own canonical, never the home page one', () => {
        const meta = pageMetadata({ locale: 'km', path: '/privacy', title: 'x' });
        expect(meta.alternates?.canonical).toBe('/km/privacy');
        expect(meta.openGraph).toMatchObject({ url: '/km/privacy', locale: 'km_KH' });
        expect(meta.robots).toBeUndefined();
        // Setting openGraph drops the file-convention image, so the helper must restate it.
        expect(meta.openGraph?.images).toEqual([
            expect.objectContaining({ url: '/opengraph-image.png', width: 1200, height: 630 }),
        ]);
    });

    it('marks a page noindex when asked', () => {
        expect(pageMetadata({ locale: 'en', path: '/portal', index: false }).robots).toEqual({
            index: false,
            follow: false,
        });
    });
});

describe('sitemap', () => {
    const entries = sitemap();

    it('lists every indexable page in both locales', () => {
        expect(entries).toHaveLength(INDEXED_PATHS.length * 2);
        expect(entries.map((e) => e.url)).toContain(`${SITE_URL}/km/getting-blood`);
        expect(entries.map((e) => e.url)).toContain(`${SITE_URL}/en`);
    });

    it('never lists the board or the sign-in page (DEC-009 donor names, admin-only)', () => {
        const urls = entries.map((e) => e.url).join(' ');
        expect(urls).not.toMatch(/\/portal/);
        expect(urls).not.toMatch(/\/sign-in/);
    });
});

describe('robots', () => {
    it('does not block the noindex pages, so crawlers can read their noindex tag', () => {
        const rules = robots().rules;
        const disallow = [rules].flat().flatMap((r) => [r.disallow ?? []].flat());
        expect(disallow).toEqual(['/api/']);
        expect(robots().sitemap).toBe(`${SITE_URL}/sitemap.xml`);
    });
});

describe('jsonLd', () => {
    it('cannot close its script tag', () => {
        expect(jsonLd({ name: '</script><script>alert(1)</script>' })).not.toContain('</script>');
    });

    it('describes the app without an invented rating', () => {
        const app = mobileAppJsonLd({
            locale: 'km',
            description: 'd',
            downloadUrl: 'https://x/a.apk',
        });
        expect(app).toMatchObject({ '@type': 'MobileApplication', operatingSystem: 'Android' });
        expect(app).not.toHaveProperty('aggregateRating');
    });
});
