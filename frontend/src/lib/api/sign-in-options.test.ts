import { afterEach, describe, expect, it, vi } from 'vitest';
import { passwordSignInEnabled } from './sign-in-options';

afterEach(() => vi.unstubAllEnvs());

describe('passwordSignInEnabled', () => {
    it('is on unless PORTAL_PASSWORD_SIGN_IN is "off"', () => {
        vi.stubEnv('PORTAL_PASSWORD_SIGN_IN', '');
        expect(passwordSignInEnabled()).toBe(true);
        vi.stubEnv('PORTAL_PASSWORD_SIGN_IN', 'off');
        expect(passwordSignInEnabled()).toBe(false);
    });
});
