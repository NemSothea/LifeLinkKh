'use client';

import { useId, useRef, useState } from 'react';
import RelativeTime from '@/components/RelativeTime';
import type { PendingRequest } from '@/lib/api/portal';
import { IconAlertTriangle, IconBuilding, IconCheck, IconDroplet } from '@/components/icons';
import { reviewRequestAction } from './actions';
import { UrgencyBadge } from './request-list';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
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
import { Phone } from 'lucide-react';

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
                <span className="tabular-nums text-black/65 dark:text-white/65">
                    ({requests.length})
                </span>
            </h2>
            <p className="mb-4 text-sm text-black/70 dark:text-white/70">{copy.hint}</p>
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
    const reasonId = useId();

    return (
        <li
            data-testid={`portal-pending-${request.id}`}
            className="flex flex-col gap-4 rounded-2xl border border-amber-300 bg-warning-surface p-4 shadow-sm sm:flex-row sm:items-center sm:justify-between dark:border-amber-900"
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
                        <span className="text-foreground/75">{copy.unitsLabel[request.id]}</span>
                        <RelativeTime
                            iso={request.createdAt}
                            className="text-muted-foreground tabular-nums"
                        />
                    </div>
                    {request.hospital ? (
                        <p className="mt-1 flex items-center gap-1.5 font-medium">
                            <IconBuilding className="h-4 w-4 text-muted-foreground" />
                            {request.hospital.name}
                        </p>
                    ) : null}
                    {request.contactName || request.contactPhone ? (
                        <p className="mt-1 text-foreground/75">
                            {copy.contactLabel}: {request.contactName}
                        </p>
                    ) : null}
                    {/* Calling the family is how an admin checks a request is real, so the number
                        is a 44px call button rather than an 18px text link. */}
                    {request.contactPhone ? (
                        <Button asChild variant="outline" className="mt-2 rounded-full font-mono">
                            <a
                                href={`tel:${request.contactPhone}`}
                                data-testid={`call-${request.id}`}
                            >
                                <Phone className="size-4" aria-hidden="true" />
                                {request.contactPhone}
                            </a>
                        </Button>
                    ) : null}
                </div>
            </div>

            <div className="grid shrink-0 grid-cols-2 gap-2 sm:flex">
                <Button
                    type="button"
                    variant="outline"
                    onClick={() => setDialog('reject')}
                    data-testid={`reject-${request.id}`}
                >
                    {copy.rejectCta}
                </Button>
                <Button
                    type="button"
                    onClick={() => setDialog('approve')}
                    data-testid={`approve-${request.id}`}
                >
                    <IconCheck className="h-4 w-4" />
                    {copy.approveCta}
                </Button>
            </div>

            <form ref={approveRef} action={reviewRequestAction} className="hidden">
                <input type="hidden" name="requestId" value={request.id} />
                <input type="hidden" name="decision" value="APPROVE" />
                <input type="hidden" name="locale" value={locale} />
            </form>

            {/* Radix AlertDialog: focus is trapped inside, Escape and Cancel close it, the page
                behind stops scrolling, and a click outside never approves by accident. */}
            <AlertDialog open={dialog !== null} onOpenChange={(open) => !open && setDialog(null)}>
                <AlertDialogContent>
                    {dialog === 'approve' ? (
                        <>
                            <AlertDialogHeader>
                                <AlertDialogTitle>{copy.approveDialogTitle}</AlertDialogTitle>
                                <AlertDialogDescription>
                                    {copy.approveDialogBody}
                                </AlertDialogDescription>
                            </AlertDialogHeader>
                            <AlertDialogFooter>
                                <AlertDialogCancel autoFocus>{copy.cancelCta}</AlertDialogCancel>
                                <AlertDialogAction
                                    onClick={() => approveRef.current?.requestSubmit()}
                                    data-testid={`approve-confirm-${request.id}`}
                                >
                                    <IconCheck className="h-4 w-4" />
                                    {copy.approveDialogCta}
                                </AlertDialogAction>
                            </AlertDialogFooter>
                        </>
                    ) : (
                        <form action={reviewRequestAction} className="grid gap-4">
                            <input type="hidden" name="requestId" value={request.id} />
                            <input type="hidden" name="decision" value="REJECT" />
                            <input type="hidden" name="locale" value={locale} />
                            <AlertDialogHeader>
                                <AlertDialogTitle>{copy.rejectDialogTitle}</AlertDialogTitle>
                                <AlertDialogDescription>
                                    {copy.rejectDialogBody}
                                </AlertDialogDescription>
                            </AlertDialogHeader>
                            <label
                                htmlFor={reasonId}
                                className="flex flex-col gap-1.5 text-sm font-medium"
                            >
                                {copy.rejectReasonLabel}
                                <Textarea
                                    id={reasonId}
                                    name="reason"
                                    required
                                    maxLength={REASON_MAX}
                                    rows={3}
                                    value={reason}
                                    onChange={(e) => setReason(e.target.value)}
                                    placeholder={copy.rejectReasonPlaceholder}
                                    data-testid={`reject-reason-${request.id}`}
                                />
                                <span className="self-end text-xs font-normal text-muted-foreground tabular-nums">
                                    {reason.length}/{REASON_MAX}
                                </span>
                            </label>
                            <AlertDialogFooter>
                                <AlertDialogCancel autoFocus>{copy.cancelCta}</AlertDialogCancel>
                                <Button
                                    type="submit"
                                    variant="destructive"
                                    disabled={reason.trim() === ''}
                                    data-testid={`reject-confirm-${request.id}`}
                                >
                                    {copy.rejectDialogCta}
                                </Button>
                            </AlertDialogFooter>
                        </form>
                    )}
                </AlertDialogContent>
            </AlertDialog>
        </li>
    );
}
