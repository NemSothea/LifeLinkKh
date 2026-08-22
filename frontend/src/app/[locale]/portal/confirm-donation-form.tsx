'use client';

import { useId, useRef, useState } from 'react';
import { confirmDonationAction } from './actions';
import { IconCheck } from './icons';

type Copy = {
    donatedOnLabel: string;
    confirmDonationCta: string;
    dialogTitle: string;
    dialogBody: string;
    cancelCta: string;
    dialogConfirmCta: string;
};

/**
 * The one write on the page — split into its own client component only because a
 * confirmation step needs open/close state. The write itself still goes through the
 * Server Action (`confirmDonationAction`); this component never calls the API
 * directly.
 *
 * A misclick here starts a donor's 56-day cooldown for a donation that may not have
 * happened. There is no undo (`FR-REQUEST-004`-style withdrawal doesn't exist for
 * donations either), so a second, explicit step before the write is worth the extra
 * click.
 */
export default function ConfirmDonationForm({
    requestId,
    matchId,
    donorName,
    locale,
    copy,
}: {
    requestId: string;
    matchId: string;
    donorName: string;
    locale: string;
    copy: Copy;
}) {
    const [open, setOpen] = useState(false);
    const [donatedOn, setDonatedOn] = useState(() => new Date().toISOString().slice(0, 10));
    const formRef = useRef<HTMLFormElement>(null);
    const titleId = useId();

    return (
        <>
            <form ref={formRef} action={confirmDonationAction} className="contents">
                <input type="hidden" name="requestId" value={requestId} />
                <input type="hidden" name="matchId" value={matchId} />
                <input type="hidden" name="locale" value={locale} />
                <input type="hidden" name="donorName" value={donorName} />
                <input type="hidden" name="donatedOn" value={donatedOn} />

                <label className="flex flex-col text-xs text-black/60 dark:text-white/60">
                    {copy.donatedOnLabel}
                    <input
                        type="date"
                        required
                        max={new Date().toISOString().slice(0, 10)}
                        value={donatedOn}
                        onChange={(e) => setDonatedOn(e.target.value)}
                        className="rounded-md border border-black/20 px-2 py-1 text-sm text-black focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600 dark:border-white/25 dark:bg-black/30 dark:text-white"
                    />
                </label>
                <button
                    type="button"
                    onClick={() => setOpen(true)}
                    data-testid={`confirm-donation-${matchId}`}
                    className="flex items-center gap-1.5 rounded-md bg-red-700 px-3 py-1.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-red-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"
                >
                    <IconCheck className="h-4 w-4" />
                    {copy.confirmDonationCta}
                </button>
            </form>

            {open ? (
                <div
                    role="presentation"
                    className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
                    onClick={() => setOpen(false)}
                    onKeyDown={(e) => {
                        if (e.key === 'Escape') setOpen(false);
                    }}
                >
                    <div
                        role="dialog"
                        aria-modal="true"
                        aria-labelledby={titleId}
                        onClick={(e) => e.stopPropagation()}
                        className="w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl dark:bg-neutral-900"
                    >
                        <h2 id={titleId} className="text-lg font-semibold">
                            {copy.dialogTitle}
                        </h2>
                        <p className="mt-2 text-sm text-black/70 dark:text-white/70">
                            {copy.dialogBody
                                .replace('{name}', donorName)
                                .replace(
                                    '{date}',
                                    new Date(donatedOn + 'T00:00:00').toLocaleDateString(locale),
                                )}
                        </p>
                        <div className="mt-6 flex justify-end gap-2">
                            <button
                                type="button"
                                autoFocus
                                onClick={() => setOpen(false)}
                                className="rounded-md px-3 py-1.5 text-sm font-medium text-black/70 hover:bg-black/5 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600 dark:text-white/70 dark:hover:bg-white/10"
                            >
                                {copy.cancelCta}
                            </button>
                            <button
                                type="button"
                                onClick={() => formRef.current?.requestSubmit()}
                                className="flex items-center gap-1.5 rounded-md bg-red-700 px-3 py-1.5 text-sm font-medium text-white hover:bg-red-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"
                            >
                                <IconCheck className="h-4 w-4" />
                                {copy.dialogConfirmCta}
                            </button>
                        </div>
                    </div>
                </div>
            ) : null}
        </>
    );
}
