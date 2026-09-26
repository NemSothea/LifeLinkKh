import type { NextConfig } from 'next';
import createNextIntlPlugin from 'next-intl/plugin';

const nextConfig: NextConfig = {
    // Required by the Docker runtime stage — ships a minimal server bundle instead of
    // the whole node_modules tree.
    output: 'standalone',

    async redirects() {
        return [
            {
                // The staff page lived at /portal/admin, then /portal/staff. v1 has no
                // hospital staff and no staff page (ADR 0009, phase 5), so both old paths
                // land on the portal itself rather than a 404 — they are still in
                // docs/demo-runbook.md and in the team's bookmarks.
                source: '/:locale(km|en)/portal/:page(admin|staff)',
                destination: '/:locale/portal',
                permanent: true,
            },
        ];
    },
};

const withNextIntl = createNextIntlPlugin();

export default withNextIntl(nextConfig);
