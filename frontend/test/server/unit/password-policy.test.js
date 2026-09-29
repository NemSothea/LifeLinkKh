import { describe, expect, test } from 'vitest';
import { isCommonPassword, MIN_PASSWORD_LENGTH } from '../../../src/server/password-policy.ts';
import COMMON from '../../../src/server/common-passwords.json';

// SEC-REVIEW-003 F-14 / ASVS 6.2.4: the top 3000 passwords that meet the length policy.
describe('password policy', () => {
    test('the list is 3000 passwords, every one long enough to pass the length rule', () => {
        expect(COMMON).toHaveLength(3000);
        expect(COMMON.every((p) => p.length >= MIN_PASSWORD_LENGTH)).toBe(true);
    });

    test('a common one is refused whatever its case; an uncommon one is not', () => {
        expect(isCommonPassword('1qaz2wsx3edc')).toBe(true);
        expect(isCommonPassword('1QAZ2WSX3EDC')).toBe(true);
        expect(isCommonPassword('blood-donor-kh-portal-73')).toBe(false);
    });
});
