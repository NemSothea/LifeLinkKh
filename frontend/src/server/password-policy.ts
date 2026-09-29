import 'server-only';
import COMMON from './common-passwords.json';

/**
 * The portal's password policy (SEC-REVIEW-003 F-14, ASVS 6.2.1 / 6.2.4): at least 12
 * characters — what `firebase/seed/admin.mjs` already required — no composition rules, and
 * not one of the 3000 most common passwords that are that long.
 *
 * `common-passwords.json` is the first 3000 distinct (lower-cased) entries of 12 or more
 * characters in SecLists' `xato-net-10-million-passwords-1000000.txt`. Filtered to the policy
 * on purpose: a shorter common password is already refused by length.
 */
export const MIN_PASSWORD_LENGTH = 12;

const common = new Set<string>(COMMON as string[]);

export function isCommonPassword(password: string): boolean {
    return common.has(password.toLowerCase());
}
