/**
 * `PORTAL_PASSWORD_SIGN_IN=off` leaves Google as the only way in to the portal (DEC-017): the
 * sign-in page drops the password form and `signInAction` refuses a hand-made POST. Unset, the
 * form stays — the emulators have no Google sign-in.
 */
export function passwordSignInEnabled(): boolean {
    return process.env.PORTAL_PASSWORD_SIGN_IN !== 'off';
}
