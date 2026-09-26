import { describe, expect, test } from 'vitest';
import { buildMessage, sendAll } from '../../src/push.js';

const args = { token: 't', requestId: 'r1', patientBloodType: 'AB+', hospitalName: 'Calmette Hospital' };

describe('buildMessage', () => {
  test('the backend\'s donor alert, in English', () => {
    const m = buildMessage('REQUEST_ALERT', { ...args, language: 'en' });
    expect(m.notification).toEqual({ title: 'Urgent blood request', body: 'AB+ needed at Calmette Hospital' });
    // PushArrival routes on these two; without them the tap opens nothing.
    expect(m.data).toEqual({ type: 'REQUEST_ALERT', requestId: 'r1' });
  });

  test('anything but en reads Khmer', () => {
    expect(buildMessage('REQUEST_ALERT', { ...args, language: null }).notification.title).toBe('សំណើឈាមបន្ទាន់');
  });

  test('the acceptance push names no donor — it can sit on a lock screen', () => {
    const m = buildMessage('DONOR_ACCEPTED', { ...args, language: 'en' });
    expect(m.notification.body).toBe('AB+ at Calmette Hospital — open LifeLink to see your request');
    expect(m.data.type).toBe('DONOR_ACCEPTED');
  });
});

describe('sendAll', () => {
  test('sorts delivered, dead and transient failures', async () => {
    const messaging = {
      sendEach: async () => ({
        responses: [
          { success: true },
          { success: false, error: { code: 'messaging/registration-token-not-registered' } },
          { success: false, error: { code: 'messaging/internal-error' } },
        ],
      }),
    };
    const out = await sendAll(messaging, [{ uid: 'ok' }, { uid: 'dead' }, { uid: 'flaky' }]);
    expect(out).toEqual({ sent: ['ok'], dead: ['dead'] });
  });

  test('nothing to send makes no call', async () => {
    const messaging = { sendEach: () => { throw new Error('called'); } };
    expect(await sendAll(messaging, [])).toEqual({ sent: [], dead: [] });
  });
});
