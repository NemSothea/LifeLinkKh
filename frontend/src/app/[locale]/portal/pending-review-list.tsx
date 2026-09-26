'use client';

import { useId, useRef, useState } from 'react';
import RelativeTime from '@/components/RelativeTime';
import type { PendingRequest } from '@/lib/api/portal';
import { IconAlertTriangle, IconBuilding, IconCheck, IconDroplet } from '@/components/icons';
import { reviewRequestAction } from './actions';
import { UrgencyBadge } from './request-list';

type Copy = {
    heading: string;
    hint: string;
    contactLabel: string;
    approveCta: string;
    rejectCta: string;
    approveDialogTitle: string;
    approveDialogBody: string;
    approveDialogCta: string;
    rejectDialogTitle: string;
    rejectDialogBody: string;
    rejectReasonLabel: string;
    rejectReasonPlaceholder: string;
    rejectDialogCta: string;
    cancelCta: string;
    urgency: Record<string, string>;
    unitsLabel: Record<string, string>;
};

/** The same limit `reviewRequest` enforces — kept here so the form stops at it, not the server. */
const REASON_MAX = 200;

/**
 * DEC-015's queue: requests nobody has been alerted about yet. Shown above the open list and only
 * when it has something in it, because an empty review queue is the normal state and should not
 * push the live requests down the page.
 */
export default function PendingReviewList({
    requests,
    locale,
    copy,
}: {
    requests: PendingRequest[];
    locale: string;
    copy: Copy;
}) {
    return (
        <section data-testid="portal-pending" className="mb-10">
            <h2 className="flex items-center gap-2 text-lg font-semibold">
                <IconAlertTriangle className="h-5 w-5 text-amber-600 dark:text-amber-400" />
                {copy.heading}
                <span className="tabular-nums text-black/50 dark:text-white/50">
                    ({requests.length})
                </span>
            </h2>
            <p className="mb-4 text-sm text-black/60 dark:text-white/60">{copy.hint}</p>
            <ul className="flex flex-col gap-3">
                {requests.map((request) => (
                    <PendingRow key={request.id} request={request} locale={locale} copy={copy} />
                ))}
            </ul>
        </section>
    );
}

function PendingRow({
    request,
    locale,
    copy,
}: {
    request: PendingRequest;
    locale: string;
    copy: Copy;
}) {
    const [dialog, setDialog] = useState<'approve' | 'reject' | null>(null);
    const [reason, setReason] = useState('');
    const approveRef = useRef<HTMLFormElement>(null);
    const titleId = useId();
    const reasonId = useId();

    return (
        <li
            data-testid={`portal-pending-${request.id}`}
            className="flex flex-col gap-3 rounded-2xl border border-amber-300 bg-amber-50/60 p-4 sm:flex-row sm:items-center sm:justify-between dark:border-amber-800 dark:bg-amber-950/30"
        >
            <div className="flex items-center gap-3">
                <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-brand text-sm font-bold text-white">
                    <IconDroplet className="mr-0.5 -ml-1 h-3.5 w-3.5 opacity-70" />
                    {request.patientBloodType}
                </span>
                <div className="min-w-0 text-sm">
                    <div className="flex flex-wrap items-center gap-2">
                        <UrgencyBadge
                            urgency={request.urgency}
                            label={copy.urgency[request.urgency] ?? request.urgency}
                        />
                        <span className="text-black/60 dark:text-white/60">
                            {copy.unitsLabel[request.id]}
                        </span>
                        <RelativeTime
                            iso={request.createdAt}
                            className="text-black/50 tabular-nums dark:text-white/50"
                        />
                    </div>
                    {request.hospital ? (
                        <p className="mt-1 flex items-center gap-1.5 font-medium">
                            <IconBuilding className="h-4 w-4 text-black/40 dark:text-white/40" />
                            {request.hospital.name}
                        </p>
                    ) : null}
                    {request.contactName || request.contactPhone ? (
                        <p className="mt-1 text-black/70 dark:text-white/70">
                            {copy.contactLabel}: {request.contactName}
                            {request.contactPhone ? (
                                <>
                                    {' · '}
                                    <a
                                        href={`tel:${request.contactPhone}`}
                                        className="font-mono underline-offset-4 hover:underline"
                                    >
                                        {request.contactPhone}
                                    </a>
                                </>
                            ) : null}
                        </p>
                    ) : null}
                </div>
            </div>

            <div className="flex shrink-0 gap-2">
                <button
                    type="button"
                    onClick={() => setDialog('reject')}
                    data-testid={`reject-${request.id}`}
                    className="rounded-xl border border-black/15 px-3 py-1.5 text-sm font-medium text-black/70 hover:bg-black/5 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:border-white/20 dark:text-white/70 dark:hover:bg-white/10"
                >
                    {copy.rejectCta}
                </button>
                <button
                    type="button"
                    onClick={() => setDialog('approve')}
                    data-testid={`approve-${request.id}`}
                    className="flex items-center gap-1.5 rounded-xl bg-brand px-3 py-1.5 text-sm font-medium text-white shadow-sm hover:opacity-90 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand"
                >
                    <IconCheck className="h-4 w-4" />
                    {copy.approveCta}
                </button>
            </div>

            <form ref={approveRef} action={reviewRequestAction} className="hidden">
                <input type="hidden" name="requestId" value={request.id} />
                <input type="hidden" name="decision" value="APPROVE" />
                <input type="hidden" name="locale" value={locale} />
            </form>

            {dialog ? (
                <div
                    role="presentation"
                    className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
                    onClick={() => setDialog(null)}
                    onKeyDown={(e) => {
                        if (e.key === 'Escape') setDialog(null);
                    }}
                >
                    <div
                        role="dialog"
                        aria-modal="true"
                        aria-labelledby={titleId}
                        onClick={(e) => e.stopPropagation()}
                        className="w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl dark:bg-neutral-900"
                    >
                        {dialog === 'approve' ? (
                            <>
                                <h2 id={titleId} className="text-lg font-semibold">
                                    {copy.approveDialogTitle}
                                </h2>
                                <p className="mt-2 text-sm text-black/70 dark:text-white/70">
                                    {copy.approveDialogBody}
                                </p>
                                <div className="mt-6 flex justify-end gap-2">
                                    <CancelButton
                                        label={copy.cancelCta}
                                        onClick={() => setDialog(null)}
                                    />
                                    <button
                                        type="button"
                                        onClick={() => approveRef.current?.requestSubmit()}
                                        data-testid={`approve-confirm-${request.id}`}
                                        className="flex items-center gap-1.5 rounded-xl bg-brand px-3 py-1.5 text-sm font-medium text-white hover:opacity-90 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand"
                                    >
                                        <IconCheck className="h-4 w-4" />
                                        {copy.approveDialogCta}
                                    </button>
                                </div>
                            </>
                        ) : (
                            <form action={reviewRequestAction}>
                                <input type="hidden" name="requestId" value={request.id} />
                                <input type="hidden" name="decision" value="REJECT" />
                                <input type="hidden" name="locale" value={locale} />
                                <h2 id={titleId} className="text-lg font-semibold">
                                    {copy.rejectDialogTitle}
                                </h2>
                                <p className="mt-2 text-sm text-black/70 dark:text-white/70">
                                    {copy.rejectDialogBody}
                                </p>
                                <label
                                    htmlFor={reasonId}
                                    className="mt-4 flex flex-col gap-1 text-sm"
                                >
                                    {copy.rejectReasonLabel}
                                    <textarea
                                        id={reasonId}
                                        name="reason"
                                        required
                                        maxLength={REASON_MAX}
                                        rows={3}
                                        value={reason}
                                        onChange={(e) => setReason(e.target.value)}
                                        placeholder={copy.rejectReasonPlaceholder}
                                        data-testid={`reject-reason-${request.id}`}
                                        className="rounded-xl border border-black/20 px-3 py-2 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:border-white/25 dark:bg-black/30"
                                    />
                                    <span className="self-end text-xs text-black/45 tabular-nums dark:text-white/45">
                                        {reason.length}/{REASON_MAX}
                                    </span>
                                </label>
                                <div className="mt-4 flex justify-end gap-2">
                                    <CancelButton
                                        label={copy.cancelCta}
                                        onClick={() => setDialog(null)}
                                    />
                                    <button
                                        type="submit"
                                        disabled={reason.trim() === ''}
                                        data-testid={`reject-confirm-${request.id}`}
                                        className="rounded-xl bg-red-600 px-3 py-1.5 text-sm font-medium text-white hover:opacity-90 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand disabled:opacity-50"
                                    >
                                        {copy.rejectDialogCta}
                                    </button>
                                </div>
                            </form>
                        )}
                    </div>
                </div>
            ) : null}
        </li>
    );
}

function CancelButton({ label, onClick }: { label: string; onClick: () => void }) {
    return (
        <button
            type="button"
            autoFocus
            onClick={onClick}
            className="rounded-xl px-3 py-1.5 text-sm font-medium text-black/70 hover:bg-black/5 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:text-white/70 dark:hover:bg-white/10"
        >
            {label}
        </button>
    );
}
