// setAppConfig on the Firestore emulator: only an admin, a minimum never above the newest build,
// a download link always, and an emptied optional field removed rather than stored blank.
import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'vitest';
import { deleteApp, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { setAppConfig } from '../../../src/server/app-config.js';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
const PROJECT = 'demo-lifelink';

let app;
let db;
const quiet = { info() {}, warn() {} };
const admin = { uid: 'admin-1', token: { role: 'ADMIN' } };
const valid = {
    latestVersionCode: 3,
    latestVersionName: '1.0.2',
    minVersionCode: 2,
    downloadUrl: 'https://lifelinkkh.vercel.app/km/download',
    privacyUrl: 'https://lifelinkkh.vercel.app/km/privacy',
    releaseNotesEn: 'Faster request alerts.',
    releaseNotesKm: 'ការជូនដំណឹងលឿនជាងមុន។',
};
const publish = (data, caller = admin, allowHttp = false) =>
    setAppConfig({ db, caller, data: { ...valid, ...data }, allowHttp, log: quiet });

async function refused(promise, code, detail) {
    const error = await promise.then(
        () => null,
        (e) => e,
    );
    expect(error, 'expected a refusal').not.toBeNull();
    expect(error.code).toBe(code);
    if (detail) expect(error.details?.code).toBe(detail);
}

beforeAll(() => {
    app = initializeApp({ projectId: PROJECT }, 'app-config-test');
    db = getFirestore(app);
});
afterAll(() => deleteApp(app));
beforeEach(async () => {
    await fetch(
        `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`,
        { method: 'DELETE' },
    );
    await db.doc('admins/admin-1').set({ displayName: 'Soborey', username: 'soborey' });
});

describe('setAppConfig', () => {
    test('an admin publishes the whole document and is recorded as its author', async () => {
        expect(await publish({})).toEqual({
            latestVersionCode: 3,
            latestVersionName: '1.0.2',
            minVersionCode: 2,
        });
        const doc = (await db.doc('config/app').get()).data();
        expect(doc).toMatchObject({ ...valid, updatedBy: 'admin-1' });
        expect(doc.updatedAt).toBeDefined();
    });

    test('only an admin — a donor, a forged claim with no admin record, nobody signed in', async () => {
        await refused(publish({}, { uid: 'd1', token: { role: 'DONOR' } }), 'permission-denied');
        await refused(publish({}, { uid: 'ghost', token: { role: 'ADMIN' } }), 'permission-denied');
        await refused(publish({}, null), 'permission-denied');
        expect((await db.doc('config/app').get()).exists).toBe(false);
    });

    test('a minimum above the newest build would lock out every phone', async () => {
        await refused(publish({ minVersionCode: 4 }), 'invalid-argument', 'MIN_ABOVE_LATEST');
        // Equal is the "everyone must update" case, and allowed.
        await publish({ minVersionCode: 3 });
        expect((await db.doc('config/app').get()).get('minVersionCode')).toBe(3);
    });

    test('version codes are whole numbers ≥ 1, the name is not blank', async () => {
        await refused(publish({ latestVersionCode: 0 }), 'invalid-argument', 'BAD_VERSION_CODE');
        await refused(publish({ latestVersionCode: 2.5 }), 'invalid-argument', 'BAD_VERSION_CODE');
        await refused(publish({ minVersionCode: '2' }), 'invalid-argument', 'BAD_VERSION_CODE');
        await refused(publish({ latestVersionName: '  ' }), 'invalid-argument', 'BAD_VERSION_NAME');
        await refused(
            publish({ latestVersionName: 'x'.repeat(33) }),
            'invalid-argument',
            'BAD_VERSION_NAME',
        );
    });

    test('links are https web links; http only on the emulator', async () => {
        await refused(publish({ downloadUrl: '' }), 'invalid-argument', 'BAD_DOWNLOAD_URL');
        await refused(
            publish({ downloadUrl: 'intent://evil' }),
            'invalid-argument',
            'BAD_DOWNLOAD_URL',
        );
        await refused(
            publish({ downloadUrl: 'http://192.168.1.5:3000/km/download' }),
            'invalid-argument',
            'BAD_DOWNLOAD_URL',
        );
        await refused(
            publish({ privacyUrl: 'javascript:alert(1)' }),
            'invalid-argument',
            'BAD_PRIVACY_URL',
        );
        await publish({ downloadUrl: 'http://192.168.1.5:3000/km/download' }, admin, true);
        expect((await db.doc('config/app').get()).get('downloadUrl')).toBe(
            'http://192.168.1.5:3000/km/download',
        );
    });

    test('release notes are capped; an emptied optional field is removed, not stored blank', async () => {
        await refused(
            publish({ releaseNotesEn: 'x'.repeat(501) }),
            'invalid-argument',
            'NOTES_TOO_LONG',
        );
        await publish({});
        await publish({ privacyUrl: '', releaseNotesEn: '   ', releaseNotesKm: undefined });
        const doc = (await db.doc('config/app').get()).data();
        expect(doc).not.toHaveProperty('privacyUrl');
        expect(doc).not.toHaveProperty('releaseNotesEn');
        expect(doc).not.toHaveProperty('releaseNotesKm');
    });

    test('a build number can go back down — the way out of a typo that locked everyone out', async () => {
        await publish({ latestVersionCode: 30, minVersionCode: 30 });
        await publish({ latestVersionCode: 3, minVersionCode: 2 });
        expect((await db.doc('config/app').get()).data()).toMatchObject({
            latestVersionCode: 3,
            minVersionCode: 2,
        });
    });
});
