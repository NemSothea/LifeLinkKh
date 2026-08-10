import { apiGet, type ApiResult } from './client';

/**
 * Typed against `GET /api/health` in
 * `docs/fullstack/api-contract/web/openapi.yaml`.
 */
export type Health = { status: string };

export function getHealth(): Promise<ApiResult<Health>> {
    return apiGet<Health>('/health');
}
