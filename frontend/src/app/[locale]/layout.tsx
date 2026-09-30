import type { Metadata } from 'next';
import { NextIntlClientProvider } from 'next-intl';
import { getTranslations } from 'next-intl/server';
import { notFound } from 'next/navigation';
import { Inter, Kantumruy_Pro } from 'next/font/google';
import { routing, type Locale } from '@/i18n/routing';
import ThemeProvider from '@/components/ThemeProvider';
import SiteFooter from '@/components/SiteFooter';
import { SITE_URL, jsonLd, pageMetadata, siteJsonLd } from '@/lib/seo';
import '../globals.css';

// Same pairing as the Flutter app's AppTheme: Inter for Latin, Kantumruy Pro filling in
// the Khmer glyphs Inter has none of. One typographic identity across both clients
// rather than the portal inventing its own.
const inter = Inter({ subsets: ['latin'], variable: '--font-inter', display: 'swap' });
//
// Kantumruy Pro is the variable font: one file covers the 500 and 600 the portal uses as much as
// 400 and 700, where four static weights were four downloads. Only the Khmer subset is preloaded,
// since Inter already covers Latin. `optional` rather than `swap`: under swap the Khmer <h1>
// painted at ~0.9 s in a fallback font and again when Kantumruy arrived, and that second paint
// was the page's LCP (3.2 s on slow 4G, docs/tech-lead/seo-report.md). With `optional` a
// first visit on a slow link may keep the phone's own Khmer font; every later visit has it cached.
const kantumruyPro = Kantumruy_Pro({
    subsets: ['khmer'],
    variable: '--font-kantumruy',
    display: 'optional',
});

export async function generateMetadata({
    params,
}: {
    params: Promise<{ locale: string }>;
}): Promise<Metadata> {
    const { locale } = await params;
    const t = await getTranslations({ locale, namespace: 'app' });
    // Search Console / Bing Webmaster verification codes, pasted on Vercel. Unset renders no tag.
    const google = process.env.GOOGLE_SITE_VERIFICATION?.trim();
    const bing = process.env.BING_SITE_VERIFICATION?.trim();
    const home = pageMetadata({
        locale,
        path: '',
        title: t('metaTitle'),
        description: t('metaDescription'),
    });
    return {
        ...home,
        metadataBase: new URL(SITE_URL),
        // Child pages set a bare title; the template adds the brand once.
        title: { default: t('metaTitle'), template: '%s · LifeLink KH' },
        applicationName: 'LifeLink KH',
        verification: {
            ...(google ? { google } : {}),
            ...(bing ? { other: { 'msvalidate.01': bing } } : {}),
        },
    };
}

export default async function LocaleLayout({
    children,
    params,
}: {
    children: React.ReactNode;
    params: Promise<{ locale: string }>;
}) {
    const { locale } = await params;
    if (!routing.locales.includes(locale as Locale)) {
        notFound();
    }
    const t = await getTranslations({ locale, namespace: 'app' });

    return (
        // suppressHydrationWarning: next-themes sets the class on <html> before React hydrates.
        <html
            lang={locale}
            className={`${inter.variable} ${kantumruyPro.variable}`}
            suppressHydrationWarning
        >
            <body className="flex min-h-screen flex-col antialiased">
                <script
                    type="application/ld+json"
                    dangerouslySetInnerHTML={{
                        __html: jsonLd(siteJsonLd(locale, t('metaDescription'))),
                    }}
                />
                <ThemeProvider>
                    <NextIntlClientProvider>
                        <div className="flex-1">{children}</div>
                        <SiteFooter locale={locale} />
                    </NextIntlClientProvider>
                </ThemeProvider>
            </body>
        </html>
    );
}
