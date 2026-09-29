import type { NextConfig } from 'next';
import createNextIntlPlugin from 'next-intl/plugin';

/**
 * Sent on every response (SEC-REVIEW-003 F-06). The CSP is the part that does not depend on
 * how Next injects its scripts: nothing may frame the portal (the sign-in page was framable,
 * which is clickjacking), no plugins, no `<base>` hijack, forms post only here. A script-src
 * would need per-request nonces for Next's inline scripts and an allowance for Google's
 * sign-in client — worth doing, but not as a header that silently breaks sign-in.
 */
const SECURITY_HEADERS = [
    {
        key: 'Content-Security-Policy',
        value: "frame-ancestors 'none'; object-src 'none'; base-uri 'self'; form-action 'self'",
    },
    { key: 'X-Frame-Options', value: 'DENY' },
    { key: 'X-Content-Type-Options', value: 'nosniff' },
    { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
    { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
];

const nextConfig: NextConfig = {
    // firebase-admin (ADR 0010) is loaded by Node at runtime, not bundled: it carries gRPC and
    // protobuf files that the bundler cannot follow.
    serverExternalPackages: ['firebase-admin'],
    async headers() {
        return [{ source: '/:path*', headers: SECURITY_HEADERS }];
    },
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
