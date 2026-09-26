import { firestoreQuery, type ApiResult } from './client';

/**
 * Proves browser → Next server → Firestore end to end, unmocked: one public read of the
 * reference data. `UP` when it answers; the page shows "unreachable" otherwise.
 */
export type Health = { status: string };

export async function getHealth(): Promise<ApiResult<Health>> {
    const result = await firestoreQuery({ collection: 'districts', limit: 1 }, null);
    return result.ok ? { ok: true, data: { status: 'UP' } } : result;
}
