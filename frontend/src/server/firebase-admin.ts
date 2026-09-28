import 'server-only';
import { type App, applicationDefault, cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging, type Message } from 'firebase-admin/messaging';

/**
 * The Admin SDK on the Next server (ADR 0010). This is the one credential the portal holds, and
 * it holds it only here: the handlers under `src/server/` take `db`/`auth`/`messaging` as
 * arguments, so nothing else imports `firebase-admin`, and every Server Action and page keeps
 * reading Firestore as the signed-in admin through `client.ts` exactly as before.
 *
 * Where the credential comes from, in order:
 *   1. `FIREBASE_SERVICE_ACCOUNT` — the service-account JSON, as one environment variable. This
 *      is what production (Vercel) sets. Never `NEXT_PUBLIC_`.
 *   2. The emulators (`FIRESTORE_EMULATOR_HOST` set) — no credential; the SDK talks to them
 *      with the project id alone.
 *   3. Application Default Credentials (`GOOGLE_APPLICATION_CREDENTIALS`) — a developer's
 *      machine against the real project, the same way the seed scripts run.
 */
const PROJECT_ID = process.env.FIREBASE_PROJECT_ID?.trim() || 'lifelinkkh';

function serviceAccount(): Record<string, string> | null {
    const raw = process.env.FIREBASE_SERVICE_ACCOUNT?.trim();
    if (!raw) return null;
    try {
        return JSON.parse(raw);
    } catch {
        throw new Error('FIREBASE_SERVICE_ACCOUNT is set but is not the service-account JSON');
    }
}

function app(): App {
    const existing = getApps().find((a) => a.name === 'lifelink-server');
    if (existing) return existing;
    const account = serviceAccount();
    const onEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
    return initializeApp(
        {
            projectId: PROJECT_ID,
            ...(account
                ? { credential: cert(account) }
                : onEmulator
                  ? {}
                  : { credential: applicationDefault() }),
        },
        'lifelink-server',
    );
}

export function serverDb() {
    return getFirestore(app());
}

export function serverAuth() {
    return getAuth(app());
}

/** What the handlers send through — firebase-admin Messaging, or the fake below. */
export type Messaging = {
    sendEach(messages: Message[]): Promise<{
        responses: { success: boolean; error?: { code?: string } }[];
    }>;
};

/**
 * FCM has no emulator. On a `demo-` project (the tests), and on the emulators without a
 * credential (a rehearsal), every message is written to `_outbox` instead of sent, so a test
 * can read exactly what a donor would have received. No rule matches `_outbox`, so no client
 * can read it. With a credential the send is real even against the emulators — that is how a
 * phone gets a push in a local demo.
 */
export function serverMessaging(): Messaging {
    const fake =
        PROJECT_ID.startsWith('demo-') ||
        (Boolean(process.env.FIRESTORE_EMULATOR_HOST) && !serviceAccount());
    if (!fake) return getMessaging(app());
    const db = serverDb();
    return {
        async sendEach(messages) {
            await Promise.all(messages.map((m) => db.collection('_outbox').add(m)));
            return { responses: messages.map(() => ({ success: true })) };
        },
    };
}
