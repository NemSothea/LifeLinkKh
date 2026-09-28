'use client';

import Script from 'next/script';
import { useCallback, useEffect, useRef, useState, useTransition } from 'react';
import { googleSignInAction, type SignInError } from './actions';

type Copy = {
    or: string;
    failed: string;
    failedRateLimited: string;
    failedUnreachable: string;
    submitting: string;
};

type GoogleId = {
    initialize(options: {
        client_id: string;
        callback: (response: { credential?: string }) => void;
        ux_mode?: 'popup';
    }): void;
    renderButton(
        parent: HTMLElement,
        options: {
            theme?: string;
            size?: string;
            text?: string;
            shape?: string;
            width?: number;
            locale?: string;
        },
    ): void;
};

declare global {
    interface Window {
        google?: { accounts?: { id?: GoogleId } };
    }
}

/**
 * "Sign in with Google" for admins, drawn by Google Identity Services.
 *
 * Google hands this page a Google ID token (a one-use proof of who picked the account). It goes
 * straight to a Server Action, which trades it for the Firebase session and sets the httpOnly
 * cookie — the Firebase token itself never exists in page script. Whether the account may enter
 * is decided there, by the ADMIN claim, not here.
 */
export default function GoogleSignIn({
    clientId,
    locale,
    copy,
    divider = true,
}: {
    clientId: string;
    locale: string;
    /** The "or" rule above the button — only when the password form is on the page too. */
    divider?: boolean;
    copy: Copy;
}) {
    const buttonRef = useRef<HTMLDivElement>(null);
    const [error, setError] = useState<SignInError | null>(null);
    const [pending, startTransition] = useTransition();
    const [loaded, setLoaded] = useState(false);

    const errorMessage: Record<SignInError, string> = {
        invalid: copy.failed,
        rateLimited: copy.failedRateLimited,
        unreachable: copy.failedUnreachable,
    };

    const render = useCallback(() => {
        const id = window.google?.accounts?.id;
        if (!id || !buttonRef.current) return;
        id.initialize({
            client_id: clientId,
            ux_mode: 'popup',
            callback: ({ credential }) => {
                startTransition(async () => {
                    // Resolves only on failure: success redirects to the portal.
                    setError(await googleSignInAction(credential, locale));
                });
            },
        });
        id.renderButton(buttonRef.current, {
            theme: 'outline',
            size: 'large',
            shape: 'pill',
            text: 'signin_with',
            width: buttonRef.current.clientWidth || 320,
            locale,
        });
    }, [clientId, locale]);

    // The script may already be on the page after a client-side navigation back here.
    useEffect(() => {
        if (loaded || window.google?.accounts?.id) render();
    }, [loaded, render]);

    return (
        <div className="flex flex-col gap-4" data-testid="google-sign-in">
            <Script
                src="https://accounts.google.com/gsi/client"
                strategy="afterInteractive"
                onLoad={() => setLoaded(true)}
            />
            {divider ? (
                <div className="flex items-center gap-3 text-xs text-black/60 dark:text-white/60">
                    <span className="h-px flex-1 bg-black/10 dark:bg-white/15" />
                    {copy.or}
                    <span className="h-px flex-1 bg-black/10 dark:bg-white/15" />
                </div>
            ) : null}
            {error ? (
                <p
                    role="alert"
                    data-testid="google-sign-in-error"
                    className="rounded-xl border border-red-300 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-800 dark:bg-red-950/60 dark:text-red-400"
                >
                    {errorMessage[error]}
                </p>
            ) : null}
            <div
                ref={buttonRef}
                className="flex min-h-11 w-full justify-center"
                aria-busy={pending}
            />
            {pending ? (
                <p className="text-center text-sm text-black/70 dark:text-white/70">
                    {copy.submitting}
                </p>
            ) : null}
        </div>
    );
}
