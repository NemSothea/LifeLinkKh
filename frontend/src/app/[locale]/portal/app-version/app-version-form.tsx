'use client';

import { useActionState, useId, useRef, useState } from 'react';
import { useFormStatus } from 'react-dom';
import { Save } from 'lucide-react';
import Notice from '@/components/Notice';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import type { AppConfig } from '@/lib/api/app-config';
import { NOTES_MAX, VERSION_NAME_MAX } from '@/lib/api/app-config';
import { saveAppVersionAction, type AppVersionResult } from './actions';

type Copy = {
    versionNameLabel: string;
    versionNameHint: string;
    versionCodeLabel: string;
    versionCodeHint: string;
    minCodeLabel: string;
    minCodeHint: string;
    minToLatestCta: string;
    downloadUrlLabel: string;
    downloadUrlHint: string;
    privacyUrlLabel: string;
    notesEnLabel: string;
    notesKmLabel: string;
    notesHint: string;
    submitCta: string;
    submitting: string;
    confirmTitle: string;
    confirmBody: string;
    confirmCta: string;
    cancelCta: string;
    results: Record<AppVersionResult, string>;
};

/**
 * One form for the whole `config/app` document. Raising the minimum locks every phone below it out
 * of the app until they install the new APK — so that one change, and only that one, asks first.
 */
export default function AppVersionForm({ current, copy }: { current: AppConfig; copy: Copy }) {
    const [result, formAction] = useActionState(saveAppVersionAction, null);
    const formRef = useRef<HTMLFormElement>(null);
    const [latest, setLatest] = useState(current.latestVersionCode?.toString() ?? '');
    const [min, setMin] = useState(current.minVersionCode?.toString() ?? '1');
    const [confirming, setConfirming] = useState(false);
    const confirmed = useRef(false);

    const raisesMinimum = Number(min) > (current.minVersionCode ?? 1);

    return (
        <form
            ref={formRef}
            action={formAction}
            onSubmit={(e) => {
                if (raisesMinimum && !confirmed.current) {
                    e.preventDefault();
                    setConfirming(true);
                }
                confirmed.current = false;
            }}
            className="flex flex-col gap-5"
        >
            {result ? (
                <Notice
                    tone={result === 'saved' ? 'success' : 'error'}
                    testId={result === 'saved' ? 'app-version-saved' : 'app-version-error'}
                >
                    {copy.results[result]}
                </Notice>
            ) : null}

            <div className="grid gap-5 sm:grid-cols-3">
                <Field
                    name="latestVersionName"
                    label={copy.versionNameLabel}
                    hint={copy.versionNameHint}
                    defaultValue={current.latestVersionName}
                    placeholder="1.0.2"
                    maxLength={VERSION_NAME_MAX}
                />
                <Field
                    name="latestVersionCode"
                    label={copy.versionCodeLabel}
                    hint={copy.versionCodeHint}
                    value={latest}
                    onChange={setLatest}
                    inputMode="numeric"
                    pattern="[0-9]+"
                    placeholder="3"
                />
                <Field
                    name="minVersionCode"
                    label={copy.minCodeLabel}
                    hint={copy.minCodeHint}
                    value={min}
                    onChange={setMin}
                    inputMode="numeric"
                    pattern="[0-9]+"
                    placeholder="1"
                >
                    <button
                        type="button"
                        onClick={() => latest && setMin(latest)}
                        disabled={!latest || latest === min}
                        data-testid="app-version-min-to-latest"
                        className="self-start text-xs font-medium text-brand underline-offset-2 hover:underline disabled:pointer-events-none disabled:opacity-50"
                    >
                        {copy.minToLatestCta}
                    </button>
                </Field>
            </div>

            <Field
                name="downloadUrl"
                label={copy.downloadUrlLabel}
                hint={copy.downloadUrlHint}
                defaultValue={current.downloadUrl}
                type="url"
                placeholder="https://lifelinkkh.vercel.app/km/download"
            />
            <Field
                name="privacyUrl"
                label={copy.privacyUrlLabel}
                defaultValue={current.privacyUrl}
                type="url"
                required={false}
                placeholder="https://lifelinkkh.vercel.app/km/privacy"
            />

            <div className="grid gap-5 sm:grid-cols-2">
                <Notes
                    name="releaseNotesEn"
                    label={copy.notesEnLabel}
                    hint={copy.notesHint}
                    defaultValue={current.releaseNotesEn}
                />
                <Notes
                    name="releaseNotesKm"
                    label={copy.notesKmLabel}
                    hint={copy.notesHint}
                    defaultValue={current.releaseNotesKm}
                />
            </div>

            <Submit idle={copy.submitCta} busy={copy.submitting} />

            <AlertDialog open={confirming} onOpenChange={setConfirming}>
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>{copy.confirmTitle}</AlertDialogTitle>
                        <AlertDialogDescription>
                            {copy.confirmBody.replace('{min}', min)}
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogCancel autoFocus>{copy.cancelCta}</AlertDialogCancel>
                        <AlertDialogAction
                            onClick={() => {
                                confirmed.current = true;
                                formRef.current?.requestSubmit();
                            }}
                            data-testid="app-version-confirm"
                        >
                            {copy.confirmCta}
                        </AlertDialogAction>
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>
        </form>
    );
}

function Field({
    name,
    label,
    hint,
    defaultValue,
    value,
    onChange,
    type = 'text',
    required = true,
    children,
    ...rest
}: {
    name: string;
    label: string;
    hint?: string;
    defaultValue?: string;
    value?: string;
    onChange?: (value: string) => void;
    type?: string;
    required?: boolean;
    children?: React.ReactNode;
    placeholder?: string;
    maxLength?: number;
    inputMode?: 'numeric';
    pattern?: string;
}) {
    const id = useId();
    return (
        <div className="flex flex-col gap-1.5 text-sm">
            <label htmlFor={id} className="font-medium">
                {label}
            </label>
            <Input
                id={id}
                name={name}
                type={type}
                required={required}
                {...(onChange
                    ? { value, onChange: (e) => onChange(e.target.value) }
                    : { defaultValue })}
                data-testid={`app-version-${name}`}
                {...rest}
            />
            {hint ? <span className="text-xs text-muted-foreground">{hint}</span> : null}
            {children}
        </div>
    );
}

function Notes({
    name,
    label,
    hint,
    defaultValue,
}: {
    name: string;
    label: string;
    hint: string;
    defaultValue: string;
}) {
    const id = useId();
    const [value, setValue] = useState(defaultValue);
    return (
        <div className="flex flex-col gap-1.5 text-sm">
            <label htmlFor={id} className="font-medium">
                {label}
            </label>
            <Textarea
                id={id}
                name={name}
                rows={4}
                maxLength={NOTES_MAX}
                value={value}
                onChange={(e) => setValue(e.target.value)}
                data-testid={`app-version-${name}`}
            />
            <span className="flex justify-between gap-2 text-xs text-muted-foreground">
                <span>{hint}</span>
                <span className="tabular-nums">
                    {value.length}/{NOTES_MAX}
                </span>
            </span>
        </div>
    );
}

function Submit({ idle, busy }: { idle: string; busy: string }) {
    const { pending } = useFormStatus();
    return (
        <Button
            type="submit"
            disabled={pending}
            className="self-start"
            data-testid="app-version-submit"
        >
            <Save className="size-4" aria-hidden="true" />
            {pending ? busy : idle}
        </Button>
    );
}
