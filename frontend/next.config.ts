import type { NextConfig } from 'next';
import createNextIntlPlugin from 'next-intl/plugin';

const nextConfig: NextConfig = {
    // Required by the Docker runtime stage — ships a minimal server bundle instead of
    // the whole node_modules tree.
    output: 'standalone',
};

const withNextIntl = createNextIntlPlugin();

export default withNextIntl(nextConfig);
