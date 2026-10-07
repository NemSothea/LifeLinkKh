import { render, screen } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';
import FooterVariant from './FooterVariant';

const route = vi.hoisted(() => ({ pathname: '/' }));
vi.mock('@/i18n/navigation', () => ({ usePathname: () => route.pathname }));

const publicFooter = <footer>Public navigation</footer>;
const portalFooter = <footer>Portal disclaimer</footer>;

describe('FooterVariant', () => {
    it('changes the footer when navigating between public and admin pages without duplicating it', () => {
        const { rerender } = render(
            <FooterVariant publicFooter={publicFooter} portalFooter={portalFooter} />,
        );
        expect(screen.getAllByRole('contentinfo')).toHaveLength(1);
        expect(screen.getByRole('contentinfo')).toHaveTextContent('Public navigation');

        route.pathname = '/portal';
        rerender(<FooterVariant publicFooter={publicFooter} portalFooter={portalFooter} />);
        expect(screen.getAllByRole('contentinfo')).toHaveLength(1);
        expect(screen.getByRole('contentinfo')).toHaveTextContent('Portal disclaimer');

        route.pathname = '/getting-blood';
        rerender(<FooterVariant publicFooter={publicFooter} portalFooter={portalFooter} />);
        expect(screen.getAllByRole('contentinfo')).toHaveLength(1);
        expect(screen.getByRole('contentinfo')).toHaveTextContent('Public navigation');
    });
});
