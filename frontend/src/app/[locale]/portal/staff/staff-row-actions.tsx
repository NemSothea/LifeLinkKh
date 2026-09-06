'use client';

import { useState } from 'react';
import SearchableSelect from './searchable-select';
import { demoteStaffAction, revokeStaffAction } from './actions';

type Copy = {
    revokeCta: string;
    demoteCta: string;
    revokeDialogTitle: string;
    revokeDialogBody: string;
    demoteDialogTitle: string;
    demoteDialogBody: string;
    confirmRevokeCta: string;
    confirmDemoteCta: string;
    cancelCta: string;
    hospitalLabel: string;
    hospitalHint: string;
    noMatches: string;
    selectRequired: string;
};

/**
 * Revoke and demote, on the row they act on.
 *
 * Both go through a confirmation step for the same reason confirming a donation does: neither has
 * an undo inside the product. Revoking a portal-only account deactivates it, and only an admin with
 * database access can switch it back on.
 *
 * Neither button renders on the signed-in admin's own row — the server refuses it anyway
 * (`CANNOT_TARGET_SELF`), but offering a button whose only outcome is an error is worse than not
 * offering it.
 */
export default function StaffRowActions({
    userId,
    displayName,
    role,
    locale,
    hospitals,
    copy,
}: {
    userId: string;
    displayName: string;
    role: string;
    locale: string;
    hospitals: { id: string; name: string }[];
    copy: Copy;
}) {
    const [dialog, setDialog] = useState<'revoke' | 'demote' | null>(null);

    return (
        <>
            <span className="flex items-center gap-1">
                {role === 'ADMIN' ? (
                    <button
                        type="button"
                        onClick={() => setDialog('demote')}
                        data-testid={`demote-${userId}`}
                        className="rounded-lg px-2 py-1 text-xs font-medium text-black/55 transition-colors hover:bg-black/[0.04] hover:text-black/80 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:text-white/55 dark:hover:bg-white/10 dark:hover:text-white/80"
                    >
                        {copy.demoteCta}
                    </button>
                ) : null}
                <button
                    type="button"
                    onClick={() => setDialog('revoke')}
                    data-testid={`revoke-${userId}`}
                    className="rounded-lg px-2 py-1 text-xs font-medium text-red-700/80 transition-colors hover:bg-red-500/10 hover:text-red-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:text-red-400/80 dark:hover:text-red-400"
                >
                    {copy.revokeCta}
                </button>
            </span>

            {dialog ? (
                <div
                    role="presentation"
                    className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
                    onClick={() => setDialog(null)}
                >
                    <div
                        role="dialog"
                        aria-modal="true"
                        onClick={(event) => event.stopPropagation()}
                        className="w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl dark:bg-neutral-900"
                    >
                        <h2 className="text-lg font-semibold">
                            {dialog === 'revoke' ? copy.revokeDialogTitle : copy.demoteDialogTitle}
                        </h2>
                        <p className="mt-2 text-sm text-black/70 dark:text-white/70">
                            {(dialog === 'revoke' ? copy.revokeDialogBody : copy.demoteDialogBody).replace(
                                '{name}',
                                displayName,
                            )}
                        </p>

                        <form
                            action={dialog === 'revoke' ? revokeStaffAction : demoteStaffAction}
                            className="mt-4 flex flex-col gap-4"
                        >
                            <input type="hidden" name="userId" value={userId} />
                            <input type="hidden" name="locale" value={locale} />

                            {dialog === 'demote' ? (
                                <label className="flex flex-col gap-1 text-sm">
                                    {copy.hospitalLabel}
                                    <SearchableSelect
                                        name="hospitalId"
                                        required
                                        testId={`demote-hospital-${userId}`}
                                        placeholder={copy.hospitalHint}
                                        noMatchesLabel={copy.noMatches}
                                        requiredMessage={copy.selectRequired}
                                        options={hospitals.map((hospital) => ({
                                            value: hospital.id,
                                            label: hospital.name,
                                            searchText: hospital.name,
                                        }))}
                                    />
                                </label>
                            ) : null}

                            <div className="flex justify-end gap-2">
                                <button
                                    type="button"
                                    autoFocus
                                    onClick={() => setDialog(null)}
                                    className="rounded-xl px-3 py-1.5 text-sm font-medium text-black/70 hover:bg-black/5 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:text-white/70 dark:hover:bg-white/10"
                                >
                                    {copy.cancelCta}
                                </button>
                                <button
                                    type="submit"
                                    data-testid={`confirm-${dialog}-${userId}`}
                                    className="rounded-xl bg-brand px-3 py-1.5 text-sm font-medium text-white hover:opacity-90 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand"
                                >
                                    {dialog === 'revoke' ? copy.confirmRevokeCta : copy.confirmDemoteCta}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            ) : null}
        </>
    );
}
