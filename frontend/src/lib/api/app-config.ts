import { callFunction, firestoreGet, type ApiResult } from './client';
import { requirePortalToken } from './session';

/**
 * `config/app` — what every installed app reads at launch and on resume to decide between "a new
 * version is available" and "update required". Public to read; written only through the
 * portal function `setAppConfig` (`src/server/app-config.js`) or `npm run release` in `firebase/`), which checks the caller is an admin.
 */
export type AppConfig = {
    latestVersionCode: number | null;
    latestVersionName: string;
    minVersionCode: number | null;
    downloadUrl: string;
    privacyUrl: string;
    releaseNotesEn: string;
    releaseNotesKm: string;
    updatedAt: string | null;
};

/** The same caps `setAppConfig` enforces, so the form stops at them instead of the server. */
export const VERSION_NAME_MAX = 32;
export const NOTES_MAX = 500;

export async function getAppConfig(): Promise<ApiResult<AppConfig>> {
    const result = await firestoreGet('config/app', await requirePortalToken());
    if (!result.ok) return result;
    const data = result.data?.data ?? {};
    const text = (key: string) => (typeof data[key] === 'string' ? (data[key] as string) : '');
    const code = (key: string) =>
        typeof data[key] === 'number' && Number.isInteger(data[key]) ? (data[key] as number) : null;
    return {
        ok: true,
        data: {
            latestVersionCode: code('latestVersionCode'),
            latestVersionName: text('latestVersionName'),
            minVersionCode: code('minVersionCode'),
            downloadUrl: text('downloadUrl'),
            privacyUrl: text('privacyUrl'),
            releaseNotesEn: text('releaseNotesEn'),
            releaseNotesKm: text('releaseNotesKm'),
            updatedAt: text('updatedAt') || null,
        },
    };
}

export type AppConfigInput = Omit<
    AppConfig,
    'updatedAt' | 'latestVersionCode' | 'minVersionCode'
> & {
    latestVersionCode: number;
    minVersionCode: number;
};

export async function setAppConfig(input: AppConfigInput): Promise<ApiResult<unknown>> {
    return callFunction('setAppConfig', input, await requirePortalToken());
}
