import { afterEach, describe, expect, it, vi } from 'vitest';
import { apiGet } from './client';

afterEach(() => {
    vi.unstubAllGlobals();
});

describe('apiGet', () => {
    it('returns the parsed body on 200', async () => {
        vi.stubGlobal(
            'fetch',
            vi.fn().mockResolvedValue({ ok: true, status: 200, json: async () => ({ status: 'UP' }) }),
        );

        const result = await apiGet<{ status: string }>('/health');

        expect(result).toEqual({ ok: true, data: { status: 'UP' } });
    });

    it('reports a failure status without throwing', async () => {
        vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 503 }));

        const result = await apiGet('/health');

        expect(result).toEqual({ ok: false, error: 'HTTP 503' });
    });

    /**
     * A network failure must never surface the underlying cause: an error rendered in a page
     * must not describe the server (docs/security/asvs-baseline.md, error-handling control).
     */
    it('swallows the cause when the request throws', async () => {
        vi.stubGlobal(
            'fetch',
            vi.fn().mockRejectedValue(new Error('connect ECONNREFUSED backend:8080')),
        );

        const result = await apiGet('/health');

        expect(result).toEqual({ ok: false, error: 'unreachable' });
        expect(JSON.stringify(result)).not.toContain('backend:8080');
    });
});
