/**
 * `PORTAL_DEV_JWT` is a session minted directly for a seeded account (see
 * `scripts/mint-portal-jwt.java`) and pasted into the root `.env`; it expires in one hour
 * like any other session (ADR 0007) and has to be re-minted, not renewed. Server-side
 * only — never read this under a `NEXT_PUBLIC_` name, or the token ships in the browser
 * bundle.
 *
 * **Temporary.** No Firebase Web app is registered yet, so there is no Google Sign-In
 * button on the portal — see `docs/po/prototypes/web/PORTAL-open-requests/README.md`.
 */
export function portalAuthHeader(): HeadersInit {
    const token = process.env.PORTAL_DEV_JWT;
    if (!token) {
        throw new Error(
            'PORTAL_DEV_JWT is not set. See docs/po/prototypes/web/PORTAL-open-requests/README.md.',
        );
    }
    return { Authorization: `Bearer ${token}` };
}

/**
 * Reads the `role` claim straight out of the token, unverified — good enough to decide
 * whether to render the "Manage staff" link, never to authorize a write. The backend
 * checks the real, signed claim on every `/admin/*` call regardless of what this returns.
 */
export function portalRole(): string | null {
    const token = process.env.PORTAL_DEV_JWT;
    if (!token) return null;
    try {
        const payload = token.split('.')[1];
        const json = Buffer.from(payload, 'base64url').toString('utf-8');
        return (JSON.parse(json) as { role?: string }).role ?? null;
    } catch {
        return null;
    }
}
