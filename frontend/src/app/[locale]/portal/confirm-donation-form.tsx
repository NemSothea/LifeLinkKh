'use client';

import { useRef, useState } from 'react';
import { confirmDonationAction } from './actions';
import { IconCheck } from '@/components/icons';
import { Input } from '@/components/ui/input';
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

    return (
        <>
            <form ref={formRef} action={confirmDonationAction} className="contents">
                <input type="hidden" name="requestId" value={requestId} />
                <input type="hidden" name="matchId" value={matchId} />
                <input type="hidden" name="locale" value={locale} />
                <input type="hidden" name="donorName" value={donorName} />
                <input type="hidden" name="donatedOn" value={donatedOn} />

                <label className="flex flex-col gap-1 text-sm text-muted-foreground">
                    {copy.donatedOnLabel}
                    <Input
                        type="date"
                        required
                        max={new Date().toISOString().slice(0, 10)}
                        value={donatedOn}
                        onChange={(e) => setDonatedOn(e.target.value)}
                        className="text-foreground"
                    />
                </label>
                <Button
                    type="button"
                    onClick={() => setOpen(true)}
                    data-testid={`confirm-donation-${matchId}`}
                    className="w-full sm:w-auto"
                >
                    <IconCheck className="h-4 w-4" />
                    {copy.confirmDonationCta}
                </Button>
            </form>

            {/* Radix AlertDialog: focus moves in and stays in, Escape and Cancel close it, the page
                behind stops scrolling, and a click outside does NOT confirm by accident. */}
            <AlertDialog open={open} onOpenChange={setOpen}>
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>{copy.dialogTitle}</AlertDialogTitle>
                        <AlertDialogDescription>
                            {copy.dialogBody
                                .replace('{name}', donorName)
                                .replace(
                                    '{date}',
                                    new Date(donatedOn + 'T00:00:00').toLocaleDateString(locale),
                                )}
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogCancel autoFocus>{copy.cancelCta}</AlertDialogCancel>
                        <AlertDialogAction onClick={() => formRef.current?.requestSubmit()}>
                            <IconCheck className="h-4 w-4" />
                            {copy.dialogConfirmCta}
                        </AlertDialogAction>
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>
        </>
    );
}
