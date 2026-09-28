import type { Metadata } from 'next';
import { NextIntlClientProvider } from 'next-intl';
import { getTranslations } from 'next-intl/server';
import { notFound } from 'next/navigation';
import { Inter, Kantumruy_Pro } from 'next/font/google';
import { routing, type Locale } from '@/i18n/routing';
import ThemeProvider from '@/components/ThemeProvider';
import SiteFooter from '@/components/SiteFooter';
import '../globals.css';

// Same pairing as the Flutter app's AppTheme: Inter for Latin, Kantumruy Pro filling in
// the Khmer glyphs Inter has none of. One typographic identity across both clients
// rather than the portal inventing its own.
const inter = Inter({ subsets: ['latin'], variable: '--font-inter', display: 'swap' });
const kantumruyPro = Kantumruy_Pro({
    subsets: ['khmer', 'latin'],
    weight: ['400', '500', '600', '700'],
    variable: '--font-kantumruy',
    display: 'swap',
});

export async function generateMetadata({
    params,
}: {
    params: Promise<{ locale: string }>;
}): Promise<Metadata> {
    const { locale } = await params;
    const t = await getTranslations({ locale, namespace: 'app' });
    return { title: 'LifeLink KH', description: t('metaDescription') };
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

    return (
        // suppressHydrationWarning: next-themes sets the class on <html> before React hydrates.
        <html
            lang={locale}
            className={`${inter.variable} ${kantumruyPro.variable}`}
            suppressHydrationWarning
        >
            <body className="flex min-h-screen flex-col antialiased">
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
