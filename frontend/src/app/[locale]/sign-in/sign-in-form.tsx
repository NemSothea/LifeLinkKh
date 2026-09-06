'use client';

import { useActionState, useEffect, useId, useRef, useState } from 'react';
import { useFormStatus } from 'react-dom';
import { IconEye, IconEyeOff } from '@/components/icons';
import { signInAction, type SignInError } from './actions';

type Copy = {
    usernameLabel: string;
    passwordLabel: string;
    submitCta: string;
    submitting: string;
    failed: string;
    failedRateLimited: string;
    failedUnreachable: string;
    showPassword: string;
    hidePassword: string;
    rememberUsername: string;
    rememberHint: string;
    usernamePlaceholder: string;
    passwordPlaceholder: string;
};

/**
 * Where the remembered username lives. A username is not a secret — it is printed on the
 * staff list any admin can open — so `localStorage` is the right size of storage for it.
 *
 * The **password is deliberately not stored here, or anywhere this page can read.** It is
 * the credential itself: reusable, with no expiry and no revocation (ADR 0007), so anything
 * that can read it is that staff account until someone changes the password by hand. The
 * browser's own password manager keeps it in the OS keychain instead, bound to this origin,
 * and the `autoComplete` attributes below are what invite it to.
 */
const REMEMBERED_USERNAME_KEY = 'lifelink.portal.username';

/**
 * The one form in this product that takes a password.
 *
 * `useActionState` rather than a redirect with an error in the query string: a failed
 * sign-in must not put anything about the attempt in the URL, where it lands in browser
 * history and in any proxy's access log.
 */
export default function SignInForm({ locale, copy }: { locale: string; copy: Copy }) {
    const [error, formAction] = useActionState(signInAction, null);

    const errorMessage: Record<SignInError, string> = {
        invalid: copy.failed,
        rateLimited: copy.failedRateLimited,
        unreachable: copy.failedUnreachable,
    };
    const [passwordVisible, setPasswordVisible] = useState(false);
    const [remember, setRemember] = useState(false);
    // Uncontrolled, read through a ref. A controlled value discards anything typed before
    // React hydrates — on a slow connection someone starts typing into a rendered field and
    // watches it empty itself, which is worse than the state this ref costs.
    const usernameRef = useRef<HTMLInputElement>(null);
    const usernameId = useId();
    const passwordId = useId();
    const rememberId = useId();

    // In an effect, not during render: the server has no localStorage, so reading it while
    // rendering would produce different markup on the two sides and a hydration mismatch.
    useEffect(() => {
        try {
            const saved = window.localStorage.getItem(REMEMBERED_USERNAME_KEY);
            if (saved) {
                setRemember(true);
                // Only into an empty field: if someone typed while the page was hydrating,
                // what they typed wins over what was remembered.
                if (usernameRef.current && usernameRef.current.value === '') {
                    usernameRef.current.value = saved;
                }
            }
        } catch {
            // Private windows and "block site data" both throw on access rather than
            // returning null. Not remembering a username is a fine outcome; a sign-in page
            // that will not render is not.
        }
    }, []);

    function persistUsername(shouldRemember: boolean, value: string) {
        try {
            if (shouldRemember && value.trim() !== '') {
                window.localStorage.setItem(REMEMBERED_USERNAME_KEY, value.trim());
            } else {
                window.localStorage.removeItem(REMEMBERED_USERNAME_KEY);
            }
        } catch {
            // Same as above — a storage failure must not stop anyone signing in.
        }
    }

    return (
        <form
            action={formAction}
            // On submit rather than on every keystroke: a half-typed username written to
            // storage would come back as the prefill next time.
            onSubmit={() => persistUsername(remember, usernameRef.current?.value ?? '')}
            className="flex flex-col gap-4"
        >
            <input type="hidden" name="locale" value={locale} />

            {error ? (
                <p
                    data-testid="sign-in-error"
                    role="alert"
                    className="rounded-xl border border-red-300 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-800 dark:bg-red-950/60 dark:text-red-400"
                >
                    {errorMessage[error]}
                </p>
            ) : null}

            <label htmlFor={usernameId} className="flex flex-col gap-1 text-sm">
                {copy.usernameLabel}
                <input
                    ref={usernameRef}
                    id={usernameId}
                    type="text"
                    name="username"
                    required
                    autoComplete="username"
                    autoFocus
                    placeholder={copy.usernamePlaceholder}
                    // A username is not a sentence: iOS capitalises the first letter and
                    // Chrome red-underlines it otherwise, and 'Soborey' does not match
                    // 'soborey'.
                    autoCapitalize="none"
                    autoCorrect="off"
                    spellCheck={false}
                    data-testid="sign-in-username"
                    className="rounded-xl border border-black/20 px-3 py-2 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:border-white/25 dark:bg-black/30"
                />
            </label>

            <label htmlFor={passwordId} className="flex flex-col gap-1 text-sm">
                {copy.passwordLabel}
                <span className="relative flex items-center">
                    <input
                        id={passwordId}
                        // Toggled, not two inputs: swapping between a password and a text
                        // field would drop what has been typed and, worse, let a browser
                        // password manager save the wrong one.
                        type={passwordVisible ? 'text' : 'password'}
                        name="password"
                        required
                        placeholder={copy.passwordPlaceholder}
                        autoComplete="current-password"
                        data-testid="sign-in-password"
                        className="w-full rounded-xl border border-black/20 py-2 pr-11 pl-3 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:border-white/25 dark:bg-black/30"
                    />
                    <button
                        // type="button" matters: inside a form, a button with no type is a
                        // submit button, so revealing the password would post the form.
                        type="button"
                        onClick={() => setPasswordVisible((visible) => !visible)}
                        // The label changes with the state, so a screen reader announces what
                        // the button will do next rather than what it did last.
                        aria-label={passwordVisible ? copy.hidePassword : copy.showPassword}
                        aria-pressed={passwordVisible}
                        aria-controls={passwordId}
                        data-testid="sign-in-toggle-password"
                        className="absolute right-2 rounded-lg p-1.5 text-black/45 transition-colors hover:text-black/70 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:text-white/45 dark:hover:text-white/70"
                    >
                        {passwordVisible ? (
                            <IconEyeOff className="h-4.5 w-4.5" />
                        ) : (
                            <IconEye className="h-4.5 w-4.5" />
                        )}
                    </button>
                </span>
            </label>

            <div className="flex flex-col gap-1">
                <label htmlFor={rememberId} className="flex items-center gap-2 text-sm">
                    <input
                        id={rememberId}
                        type="checkbox"
                        checked={remember}
                        // Unticking clears it immediately rather than at the next submit —
                        // someone who unticks this on a shared machine means "forget it now",
                        // and may well close the tab without signing in.
                        onChange={(event) => {
                            setRemember(event.target.checked);
                            persistUsername(event.target.checked, usernameRef.current?.value ?? '');
                        }}
                        data-testid="sign-in-remember"
                        className="h-4 w-4 rounded border-black/25 accent-brand dark:border-white/25"
                    />
                    {copy.rememberUsername}
                </label>
                <p className="pl-6 text-xs text-black/50 dark:text-white/50">{copy.rememberHint}</p>
            </div>

            <SubmitButton idle={copy.submitCta} busy={copy.submitting} />
        </form>
    );
}

/**
 * Split out because `useFormStatus` reports on the nearest enclosing form and only from a
 * child of it — read in the parent it is always idle.
 */
function SubmitButton({ idle, busy }: { idle: string; busy: string }) {
    const { pending } = useFormStatus();
    return (
        <button
            type="submit"
            disabled={pending}
            data-testid="sign-in-submit"
            className="mt-2 rounded-xl bg-brand px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-opacity hover:opacity-90 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand disabled:opacity-60"
        >
            {pending ? busy : idle}
        </button>
    );
}
