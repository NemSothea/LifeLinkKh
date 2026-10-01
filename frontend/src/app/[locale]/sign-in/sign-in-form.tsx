'use client';

import { useActionState, useEffect, useId, useRef, useState } from 'react';
import Notice from '@/components/Notice';
import { useFormStatus } from 'react-dom';
import { IconEye, IconEyeOff } from '@/components/icons';
import { signInAction, type SignInError } from './actions';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';

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
    // The username's *default*, not its value. React 19 resets a form once its action
    // settles, putting every field back to its default — after a wrong password the username
    // emptied and "Remember" unticked, which read as the remembering being broken. Tracking
    // the remembered or last-submitted username here makes the reset put it back.
    const [usernameDefault, setUsernameDefault] = useState('');
    const rememberRef = useRef<HTMLInputElement>(null);
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
                // Ticked by hand as well: React sets `checked` itself on hydration, and after
                // that a browser ignores a changed default.
                if (rememberRef.current) rememberRef.current.checked = true;
                // A new default only shows in a field nobody has typed into: if someone typed
                // while the page was hydrating, what they typed wins over what was remembered.
                setUsernameDefault(saved);
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
            onSubmit={() => {
                const typed = usernameRef.current?.value ?? '';
                persistUsername(remember, typed);
                // Kept for the reset after a failed attempt whether or not it is remembered:
                // retyping the username to fix a password is no part of remembering.
                setUsernameDefault(typed);
            }}
            className="flex flex-col gap-4"
        >
            <input type="hidden" name="locale" value={locale} />

            {error ? (
                <Notice tone="error" testId="sign-in-error">
                    {errorMessage[error]}
                </Notice>
            ) : null}

            <label htmlFor={usernameId} className="flex flex-col gap-1.5 text-sm font-medium">
                {copy.usernameLabel}
                <Input
                    ref={usernameRef}
                    id={usernameId}
                    type="text"
                    name="username"
                    defaultValue={usernameDefault}
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
                />
            </label>

            <label htmlFor={passwordId} className="flex flex-col gap-1.5 text-sm font-medium">
                {copy.passwordLabel}
                <span className="relative flex items-center">
                    <Input
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
                        className="pr-12"
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
                        className="absolute right-0 flex size-11 items-center justify-center rounded-xl text-muted-foreground transition-colors hover:text-foreground focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-none"
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
                <label
                    htmlFor={rememberId}
                    className="flex min-h-11 cursor-pointer items-center gap-3 text-sm"
                >
                    <input
                        ref={rememberRef}
                        id={rememberId}
                        type="checkbox"
                        // Uncontrolled for the same reset: a `checked` prop leaves the box
                        // unticked after it while the state still says remember.
                        defaultChecked={remember}
                        // Unticking clears it immediately rather than at the next submit —
                        // someone who unticks this on a shared machine means "forget it now",
                        // and may well close the tab without signing in.
                        onChange={(event) => {
                            setRemember(event.target.checked);
                            persistUsername(event.target.checked, usernameRef.current?.value ?? '');
                        }}
                        data-testid="sign-in-remember"
                        className="size-5 shrink-0 cursor-pointer rounded accent-brand"
                    />
                    {copy.rememberUsername}
                </label>
                <p className="pl-8 text-xs text-muted-foreground">{copy.rememberHint}</p>
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
        <Button
            type="submit"
            size="lg"
            disabled={pending}
            data-testid="sign-in-submit"
            className="mt-2"
        >
            {pending ? busy : idle}
        </Button>
    );
}
