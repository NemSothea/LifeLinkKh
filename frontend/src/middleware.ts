import createMiddleware from 'next-intl/middleware';
import { routing } from './i18n/routing';

// Negotiates the locale and redirects `/` to `/km`.
export default createMiddleware(routing);

export const config = {
    // Everything except Next internals, the API route handlers and static files.
    matcher: ['/', '/(km|en)/:path*', '/((?!api|_next|_vercel|.*\\..*).*)'],
};
