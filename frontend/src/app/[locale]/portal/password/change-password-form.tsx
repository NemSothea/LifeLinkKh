'use client';

import { useActionState } from 'react';
import Notice from '@/components/Notice';
import { useFormStatus } from 'react-dom';
import { changePasswordAction, type ChangePasswordResult } from './actions';
import { Input } from '@/components/ui/input';

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
    failedCommon: string;
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
        common: copy.failedCommon,
        mismatch: copy.failedMismatch,
        unchanged: copy.failedUnchanged,
        failed: copy.failed,
    };
    const succeeded = result === 'changed';

    return (
        <form action={formAction} className="flex flex-col gap-4">
            {result ? (
                <Notice
                    tone={succeeded ? 'success' : 'error'}
                    testId={succeeded ? 'password-changed' : 'password-error'}
                >
                    {message[result]}
                </Notice>
            ) : null}

            <Field
                name="currentPassword"
                label={copy.currentLabel}
                autoComplete="current-password"
            />
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
            <Input
                type="password"
                name={name}
                required
                minLength={12}
                autoComplete={autoComplete}
                data-testid={`password-${name}`}
            />
            {hint ? <span className="text-xs text-black/65 dark:text-white/65">{hint}</span> : null}
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
