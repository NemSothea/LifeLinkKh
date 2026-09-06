import type { NextConfig } from 'next';
import createNextIntlPlugin from 'next-intl/plugin';

const nextConfig: NextConfig = {
    // Required by the Docker runtime stage — ships a minimal server bundle instead of
    // the whole node_modules tree.
    output: 'standalone',

    async redirects() {
        return [
            {
                // The staff page used to live at /portal/admin, which named who may open
                // it rather than what it is for — and everything else about it (its
                // title, the link that reaches it, the `/admin/staff` endpoint behind it)
                // said "staff". Permanent, and kept rather than dropped: the old path is
                // in docs/demo-runbook.md, in the team's bookmarks, and in whatever was
                // written down during M5.
                source: '/:locale(km|en)/portal/admin',
                destination: '/:locale/portal/staff',
                permanent: true,
            },
        ];
    },
};

const withNextIntl = createNextIntlPlugin();

export default withNextIntl(nextConfig);
