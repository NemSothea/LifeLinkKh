'use client';

import { useState } from 'react';
import SearchableSelect from './searchable-select';

type Copy = {
    roleLabel: string;
    staffRoleHospital: string;
    staffRoleAdmin: string;
    hospitalLabel: string;
    hospitalHint: string;
    adminNoHospital: string;
    noMatches: string;
    selectRequired: string;
};

/**
 * The access level and the hospital, as one control rather than two independent ones.
 *
 * They were independent, and the two defaults contradicted each other: access level
 * started on *Hospital staff* while the hospital picker started on "— none, this is an
 * admin —". `AdminService.assignStaffRole` refuses exactly that pair with
 * `HOSPITAL_ID_REQUIRED`, so submitting the form untouched was guaranteed to fail — and
 * the page renders one generic "could not grant access" for every backend error, so the
 * admin was told nothing about which field to change.
 *
 * The backend's two rules are symmetric — HOSPITAL requires a hospital, ADMIN forbids
 * one — so the honest UI is one field that appears and disappears, not two fields that
 * can be combined wrongly. The impossible combination is now unreachable rather than
 * merely rejected.
 */
export default function StaffRoleFields({
    hospitals,
    copy,
}: {
    hospitals: { id: string; name: string }[];
    copy: Copy;
}) {
    const [role, setRole] = useState<'HOSPITAL' | 'ADMIN'>('HOSPITAL');

    return (
        <>
            <label className="flex flex-col gap-1 text-sm">
                {copy.roleLabel}
                <select
                    name="role"
                    required
                    value={role}
                    onChange={(event) => setRole(event.target.value as 'HOSPITAL' | 'ADMIN')}
                    data-testid="admin-role-select"
                    className="rounded-xl border border-black/20 px-2 py-1.5 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:border-white/25 dark:bg-black/30"
                >
                    <option value="HOSPITAL">{copy.staffRoleHospital}</option>
                    <option value="ADMIN">{copy.staffRoleAdmin}</option>
                </select>
            </label>

            {role === 'HOSPITAL' ? (
                <label className="flex flex-col gap-1 text-sm">
                    {copy.hospitalLabel}
                    <SearchableSelect
                        name="hospitalId"
                        required
                        testId="admin-hospital-select"
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
            ) : (
                <>
                    {/* The Server Action reads `hospitalId` off the form and turns '' into
                        null. Keeping the field present and empty means the ADMIN branch
                        needs no special case there. */}
                    <input type="hidden" name="hospitalId" value="" />
                    <p
                        data-testid="admin-no-hospital-note"
                        className="text-sm text-black/60 dark:text-white/60"
                    >
                        {copy.adminNoHospital}
                    </p>
                </>
            )}
        </>
    );
}
