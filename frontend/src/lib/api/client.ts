/**
 * The only place this app talks HTTP. Components never call `fetch` directly
 * (docs/tech-lead/coding-standards.md).
 *
 * Inside docker compose `API_BASE_URL` resolves to the `backend` service name —
 * `localhost` inside the web container is the web container itself.
 *
 * Never read a secret through `NEXT_PUBLIC_`: that prefix embeds the value in the
 * browser bundle where anyone can read it.
 */
const BASE_URL = process.env.API_BASE_URL ?? 'http://127.0.0.1:8080/api';

export type ApiResult<T> = { ok: true; data: T } | { ok: false; error: string };

export async function apiGet<T>(path: string): Promise<ApiResult<T>> {
    try {
        // no-store: a health check must never be served from a cache, or the page
        // reports a backend that stopped minutes ago as healthy.
        const response = await fetch(`${BASE_URL}${path}`, { cache: 'no-store' });

        if (!response.ok) {
            return { ok: false, error: `HTTP ${response.status}` };
        }
        return { ok: true, data: (await response.json()) as T };
    } catch {
        // The cause is deliberately not surfaced — an error string rendered in a page
        // must not describe the server's internals.
        return { ok: false, error: 'unreachable' };
    }
}
