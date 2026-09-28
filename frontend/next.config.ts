import type { NextConfig } from 'next';
import createNextIntlPlugin from 'next-intl/plugin';

const nextConfig: NextConfig = {
    // firebase-admin (ADR 0010) is loaded by Node at runtime, not bundled: it carries gRPC and
    // protobuf files that the bundler cannot follow.
    serverExternalPackages: ['firebase-admin'],
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
