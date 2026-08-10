import { render, screen } from '@testing-library/react';
import { NextIntlClientProvider } from 'next-intl';
import { describe, expect, it } from 'vitest';
import en from '@/messages/en.json';
import km from '@/messages/km.json';
import HealthStatus from './HealthStatus';

function renderWith(locale: 'km' | 'en', props: { reachable: boolean; status?: string }) {
    return render(
        <NextIntlClientProvider locale={locale} messages={locale === 'km' ? km : en}>
            <HealthStatus {...props} />
        </NextIntlClientProvider>,
    );
}

describe('HealthStatus', () => {
    it('renders the up state with the reported status', () => {
        renderWith('en', { reachable: true, status: 'UP' });

        expect(screen.getByTestId('health-up')).toHaveTextContent('API is up');
        expect(screen.queryByTestId('health-down')).toBeNull();
    });

    // The M2 acceptance criterion: a stopped backend is a handled state, not a crash.
    it('renders a handled error state when the API is unreachable', () => {
        renderWith('en', { reachable: false });

        expect(screen.getByTestId('health-down')).toHaveTextContent('Cannot reach the API');
        expect(screen.queryByTestId('health-up')).toBeNull();
    });

    // Khmer is the default locale, so its strings must resolve — not fall back to English.
    it('renders Khmer strings under the km locale', () => {
        renderWith('km', { reachable: true, status: 'UP' });

        expect(screen.getByTestId('health-up')).toHaveTextContent(km.app.healthUp);
    });
});
