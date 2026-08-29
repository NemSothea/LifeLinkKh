import type { Metadata } from 'next';
import { NextIntlClientProvider } from 'next-intl';
import { notFound } from 'next/navigation';
import { Inter, Kantumruy_Pro } from 'next/font/google';
import { routing, type Locale } from '@/i18n/routing';
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

export const metadata: Metadata = {
    title: 'LifeLink KH',
    description: 'Hospital portal — LifeLink KH blood donor matching',
};

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
        <html lang={locale} className={`${inter.variable} ${kantumruyPro.variable}`}>
            <body className="antialiased">
                <NextIntlClientProvider>{children}</NextIntlClientProvider>
            </body>
        </html>
    );
}
