import { describe, expect, test } from 'vitest';
import { ANDROID_CHANNEL_ID, buildMessage, inboxEntry, sendAll } from '../../../src/server/push.js';

const args = {
    token: 't',
    requestId: 'r1',
    patientBloodType: 'AB+',
    hospitalName: 'Calmette Hospital',
};

describe('buildMessage', () => {
    test('Android puts it on the high-importance channel, with sound', () => {
        // Without the channel it lands on FCM's fallback, which files it silently in the tray.
        expect(buildMessage('REQUEST_ALERT', { ...args, language: 'en' }).android).toEqual({
            priority: 'high',
            notification: { channelId: ANDROID_CHANNEL_ID, sound: 'default' },
        });
        expect(ANDROID_CHANNEL_ID).toBe('lifelink_urgent_requests');
    });

    test("the backend's donor alert, in English", () => {
        const m = buildMessage('REQUEST_ALERT', { ...args, language: 'en' });
        expect(m.notification).toEqual({
            title: 'Urgent blood request',
            body: 'AB+ needed at Calmette Hospital',
        });
        // PushArrival routes on these two; without them the tap opens nothing.
        expect(m.data).toEqual({ type: 'REQUEST_ALERT', requestId: 'r1' });
    });

    test('anything but en reads Khmer', () => {
        expect(buildMessage('REQUEST_ALERT', { ...args, language: null }).notification.title).toBe(
            'សំណើឈាមបន្ទាន់',
        );
    });

    test('an approval that matched nobody says so, instead of "donors are being alerted"', () => {
        const some = buildMessage('REQUEST_APPROVED', { ...args, language: 'en', alerted: 3 });
        const none = buildMessage('REQUEST_APPROVED', { ...args, language: 'en', alerted: 0 });
        expect(some.notification.body).toBe(
            'AB+ at Calmette Hospital — donors nearby are being alerted',
        );
        expect(none.notification.body).toMatch(/no eligible donor is nearby/);
        expect(none.notification.title).toBe(some.notification.title);
        // The app routes on the data half; both open the request.
        expect(none.data).toEqual({ type: 'REQUEST_APPROVED', requestId: 'r1' });
    });

    test('the acceptance push names no donor — it can sit on a lock screen', () => {
        const m = buildMessage('DONOR_ACCEPTED', { ...args, language: 'en' });
        expect(m.notification.body).toBe(
            'AB+ at Calmette Hospital — open LifeLink to see your request',
        );
        expect(m.data.type).toBe('DONOR_ACCEPTED');
    });
});

describe('sendAll', () => {
    test('sorts delivered, dead and transient failures', async () => {
        const messaging = {
            sendEach: async () => ({
                responses: [
                    { success: true },
                    {
                        success: false,
                        error: { code: 'messaging/registration-token-not-registered' },
                    },
                    { success: false, error: { code: 'messaging/internal-error' } },
                ],
            }),
        };
        const out = await sendAll(messaging, [{ uid: 'ok' }, { uid: 'dead' }, { uid: 'flaky' }]);
        expect(out).toEqual({ sent: ['ok'], dead: ['dead'] });
    });

    test('nothing to send makes no call', async () => {
        const messaging = {
            sendEach: () => {
                throw new Error('called');
            },
        };
        expect(await sendAll(messaging, [])).toEqual({ sent: [], dead: [] });
    });
});

describe('inboxEntry', () => {
    test('the same words as the push, unread, under the id it was given', () => {
        const entry = inboxEntry('REQUEST_APPROVED', {
            ...args,
            id: 'REQUEST_APPROVED_r1',
            language: 'en',
            alerted: 0,
        });
        const push = buildMessage('REQUEST_APPROVED', { ...args, language: 'en', alerted: 0 });
        expect(entry.id).toBe('REQUEST_APPROVED_r1');
        expect(entry.data).toMatchObject({
            type: 'REQUEST_APPROVED',
            requestId: 'r1',
            title: push.notification.title,
            body: push.notification.body,
            readAt: null,
        });
        expect(entry.data).not.toHaveProperty('token');
    });
});
