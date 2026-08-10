import type { Metadata } from 'next';
import { NextIntlClientProvider } from 'next-intl';
import { notFound } from 'next/navigation';
import { routing, type Locale } from '@/i18n/routing';
import '../globals.css';

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
        <html lang={locale}>
            {/*
              Explicit Khmer-capable font stack. The default system stack renders Khmer
              inconsistently across Windows and macOS, and a portal that looks broken on a
              hospital's PC is a portal nobody uses.
            */}
            <body
                style={{
                    fontFamily:
                        "'Noto Sans Khmer', 'Khmer OS Battambang', 'Khmer OS', system-ui, -apple-system, 'Segoe UI', sans-serif",
                }}
                className="antialiased"
            >
                <NextIntlClientProvider>{children}</NextIntlClientProvider>
            </body>
        </html>
    );
}
