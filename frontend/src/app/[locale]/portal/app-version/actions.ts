'use server';

import { revalidatePath } from 'next/cache';
import { setAppConfig } from '@/lib/api/app-config';
import { NOTES_MAX, VERSION_NAME_MAX } from '@/lib/app-config-limits';
import { portalRole } from '@/lib/api/session';

/**
 * Every way publishing can fail, at a granularity the admin can act on. The same checks run again
 * in `setAppConfig`; these are here so a typo is caught before the round trip, and because the
 * function's own reason does not survive `callFunction` (only its status does).
 */
export type AppVersionResult =
    | 'saved'
    | 'badVersionCode'
    | 'minAboveLatest'
    | 'badVersionName'
    | 'badDownloadUrl'
    | 'badPrivacyUrl'
    | 'notesTooLong'
    | 'failed';

export async function saveAppVersionAction(
    _previous: AppVersionResult | null | undefined,
    formData: FormData,
): Promise<AppVersionResult> {
    if ((await portalRole()) !== 'ADMIN') return 'failed';

    const text = (key: string) => {
        const value = formData.get(key);
        return typeof value === 'string' ? value.trim() : '';
    };
    const code = (key: string) => (/^\d+$/.test(text(key)) ? Number(text(key)) : NaN);

    const latestVersionCode = code('latestVersionCode');
    const minVersionCode = code('minVersionCode');
    const input = {
        latestVersionCode,
        minVersionCode,
        latestVersionName: text('latestVersionName'),
        downloadUrl: text('downloadUrl'),
        privacyUrl: text('privacyUrl'),
        releaseNotesEn: text('releaseNotesEn'),
        releaseNotesKm: text('releaseNotesKm'),
    };

    if (!(latestVersionCode >= 1) || !(minVersionCode >= 1)) return 'badVersionCode';
    if (minVersionCode > latestVersionCode) return 'minAboveLatest';
    if (input.latestVersionName === '' || input.latestVersionName.length > VERSION_NAME_MAX) {
        return 'badVersionName';
    }
    if (!isWebLink(input.downloadUrl)) return 'badDownloadUrl';
    if (input.privacyUrl !== '' && !isWebLink(input.privacyUrl)) return 'badPrivacyUrl';
    if (input.releaseNotesEn.length > NOTES_MAX || input.releaseNotesKm.length > NOTES_MAX) {
        return 'notesTooLong';
    }

    const result = await setAppConfig(input);
    if (!result.ok) return 'failed';

    revalidatePath('/[locale]/portal/app-version', 'page');
    revalidatePath('/[locale]/download', 'page');
    return 'saved';
}

/** `http` too: the function itself refuses it outside the emulator. */
function isWebLink(value: string): boolean {
    try {
        const url = new URL(value);
        return (url.protocol === 'https:' || url.protocol === 'http:') && url.hostname !== '';
    } catch {
        return false;
    }
}
