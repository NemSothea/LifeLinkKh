// The admin portal's "App version" page: publish a new build to config/app, the document every
// installed app reads to decide between "a new version is available" and "update required".
// Before this, the only writer was scripts/release.mjs, which needed a terminal and the Admin SDK.
// The rules still refuse every client write to config/app — this function is the one way in, so
// the checks below are the only thing standing between a typo and every phone being locked out.
import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError } from './https-error.js';
import { isAdmin } from './portal-accounts.js';

export const VERSION_NAME_MAX = 32;
export const NOTES_MAX = 500;
// Android's own ceiling for versionCode.
const VERSION_CODE_MAX = 2_100_000_000;

/**
 * @param {object} deps
 * @param {import('firebase-admin/firestore').Firestore} deps.db
 * @param {{uid: string, token: object}|null|undefined} deps.caller
 * @param {{
 *   latestVersionCode: number, latestVersionName: string, minVersionCode: number,
 *   downloadUrl: string, privacyUrl?: string, releaseNotesEn?: string, releaseNotesKm?: string,
 * }} deps.data
 * @param {boolean} [deps.allowHttp] plain http links too — defaults to on against the Firestore
 *   emulator, where the portal is served from a laptop without TLS
 */
export async function setAppConfig({
    db,
    caller,
    data,
    allowHttp = Boolean(process.env.FIRESTORE_EMULATOR_HOST),
    log = console,
}) {
    if (!(await isAdmin(db, caller))) throw new HttpsError('permission-denied', 'Admins only.');

    const input = data ?? {};
    const invalid = (message, code) => {
        throw new HttpsError('invalid-argument', message, { code });
    };

    const latestVersionCode = input.latestVersionCode;
    const minVersionCode = input.minVersionCode;
    if (!isVersionCode(latestVersionCode))
        invalid('latestVersionCode is a whole number ≥ 1.', 'BAD_VERSION_CODE');
    if (!isVersionCode(minVersionCode))
        invalid('minVersionCode is a whole number ≥ 1.', 'BAD_VERSION_CODE');
    // A minimum above the newest build would block every phone with nothing to update to.
    if (minVersionCode > latestVersionCode) {
        invalid('minVersionCode cannot be above latestVersionCode.', 'MIN_ABOVE_LATEST');
    }

    const latestVersionName =
        typeof input.latestVersionName === 'string' ? input.latestVersionName.trim() : '';
    if (latestVersionName === '' || latestVersionName.length > VERSION_NAME_MAX) {
        invalid(`latestVersionName is 1–${VERSION_NAME_MAX} characters.`, 'BAD_VERSION_NAME');
    }

    // Required: the app refuses to block, or even announce, an update it cannot link to.
    const downloadUrl = webLink(input.downloadUrl, allowHttp);
    if (!downloadUrl) invalid('downloadUrl must be an https:// link.', 'BAD_DOWNLOAD_URL');

    const privacyUrl = optionalText(input.privacyUrl);
    if (privacyUrl && !webLink(privacyUrl, allowHttp))
        invalid('privacyUrl must be an https:// link.', 'BAD_PRIVACY_URL');

    const releaseNotesEn = optionalText(input.releaseNotesEn);
    const releaseNotesKm = optionalText(input.releaseNotesKm);
    for (const notes of [releaseNotesEn, releaseNotesKm]) {
        if (notes && notes.length > NOTES_MAX)
            invalid(`Release notes are at most ${NOTES_MAX} characters.`, 'NOTES_TOO_LONG');
    }

    // An empty optional field removes it rather than storing "", so the app sees "no information".
    const ref = db.doc('config/app');
    const previous = (await ref.get()).data() ?? {};
    await ref.set(
        {
            latestVersionCode,
            latestVersionName,
            minVersionCode,
            downloadUrl,
            privacyUrl: privacyUrl ?? FieldValue.delete(),
            releaseNotesEn: releaseNotesEn ?? FieldValue.delete(),
            releaseNotesKm: releaseNotesKm ?? FieldValue.delete(),
            updatedBy: caller.uid,
            updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
    );

    log.info(
        `config/app latest=${latestVersionName} (${latestVersionCode}) min=${minVersionCode} ` +
            `was latest=${previous.latestVersionCode ?? '-'} min=${previous.minVersionCode ?? '-'} by=${caller.uid}`,
    );
    return { latestVersionCode, latestVersionName, minVersionCode };
}

function isVersionCode(value) {
    return Number.isInteger(value) && value >= 1 && value <= VERSION_CODE_MAX;
}

function optionalText(value) {
    if (typeof value !== 'string') return null;
    const trimmed = value.trim();
    return trimmed === '' ? null : trimmed;
}

/** Only a web link with a host — the app hands this straight to a browser. */
function webLink(value, allowHttp) {
    const text = optionalText(value);
    if (!text) return null;
    let url;
    try {
        url = new URL(text);
    } catch {
        return null;
    }
    if (!url.hostname) return null;
    if (url.protocol === 'https:' || (allowHttp && url.protocol === 'http:')) return text;
    return null;
}
