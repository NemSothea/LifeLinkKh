'use client';

import { useActionState } from 'react';
import { useFormStatus } from 'react-dom';
import { changePasswordAction, type ChangePasswordResult } from './actions';

type Copy = {
    currentLabel: string;
    newLabel: string;
    confirmLabel: string;
    passwordHint: string;
    submitCta: string;
    submitting: string;
    changed: string;
    failedWrongCurrent: string;
    failedTooShort: string;
    failedMismatch: string;
    failedUnchanged: string;
    failed: string;
};

export default function ChangePasswordForm({ copy }: { copy: Copy }) {
    const [result, formAction] = useActionState(changePasswordAction, null);

    const message: Record<ChangePasswordResult, string> = {
        changed: copy.changed,
        wrongCurrent: copy.failedWrongCurrent,
        tooShort: copy.failedTooShort,
        mismatch: copy.failedMismatch,
        unchanged: copy.failedUnchanged,
        failed: copy.failed,
    };
    const succeeded = result === 'changed';

    return (
        <form action={formAction} className="flex flex-col gap-4">
            {result ? (
                <p
                    role="alert"
                    data-testid={succeeded ? 'password-changed' : 'password-error'}
                    className={`rounded-xl border px-4 py-3 text-sm ${
                        succeeded
                            ? 'border-emerald-300 bg-emerald-50 text-emerald-800 dark:border-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300'
                            : 'border-red-300 bg-red-50 text-red-700 dark:border-red-800 dark:bg-red-950/60 dark:text-red-400'
                    }`}
                >
                    {message[result]}
                </p>
            ) : null}

            <Field name="currentPassword" label={copy.currentLabel} autoComplete="current-password" />
            <Field
                name="newPassword"
                label={copy.newLabel}
                autoComplete="new-password"
                hint={copy.passwordHint}
            />
            <Field name="confirmPassword" label={copy.confirmLabel} autoComplete="new-password" />

            <Submit idle={copy.submitCta} busy={copy.submitting} />
        </form>
    );
}

function Field({
    name,
    label,
    autoComplete,
    hint,
}: {
    name: string;
    label: string;
    autoComplete: string;
    hint?: string;
}) {
    return (
        <label className="flex flex-col gap-1 text-sm">
            {label}
            <input
                type="password"
                name={name}
                required
                minLength={8}
                autoComplete={autoComplete}
                data-testid={`password-${name}`}
                className="rounded-xl border border-black/20 px-3 py-2 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:border-white/25 dark:bg-black/30"
            />
            {hint ? <span className="text-xs text-black/50 dark:text-white/50">{hint}</span> : null}
        </label>
    );
}

function Submit({ idle, busy }: { idle: string; busy: string }) {
    const { pending } = useFormStatus();
    return (
        <button
            type="submit"
            disabled={pending}
            data-testid="password-submit"
            className="mt-2 self-start rounded-xl bg-brand px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-opacity hover:opacity-90 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand disabled:opacity-60"
        >
            {pending ? busy : idle}
        </button>
    );
}
