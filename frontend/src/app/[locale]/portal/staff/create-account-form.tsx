'use client';

import { useState } from 'react';
import SearchableSelect from './searchable-select';
import { createStaffAccountAction } from './actions';

type Copy = {
    usernameLabel: string;
    usernameHint: string;
    passwordLabel: string;
    passwordHint: string;
    nameLabel: string;
    nameHint: string;
    roleLabel: string;
    staffRoleHospital: string;
    staffRoleAdmin: string;
    hospitalLabel: string;
    hospitalHint: string;
    adminNoHospital: string;
    noMatches: string;
    selectRequired: string;
    createCta: string;
};

/**
 * Creating a portal account, rather than promoting an existing one.
 *
 * The hospital field follows the access level for the same reason it does on the promote form: the
 * backend refuses HOSPITAL without a hospital and ADMIN with one, so the impossible combination is
 * made unreachable instead of merely rejected.
 */
export default function CreateAccountForm({
    locale,
    hospitals,
    copy,
}: {
    locale: string;
    hospitals: { id: string; name: string }[];
    copy: Copy;
}) {
    const [role, setRole] = useState<'HOSPITAL' | 'ADMIN'>('HOSPITAL');

    return (
        <form
            action={createStaffAccountAction}
            className="flex flex-col gap-4 rounded-2xl border border-black/10 bg-white p-5 dark:border-white/15 dark:bg-white/[0.03]"
        >
            <input type="hidden" name="locale" value={locale} />

            <Text
                name="displayName"
                label={copy.nameLabel}
                hint={copy.nameHint}
                placeholder="Chan Dara"
                autoComplete="off"
            />
            <Text
                name="username"
                label={copy.usernameLabel}
                hint={copy.usernameHint}
                placeholder="chandara"
                autoComplete="off"
                // Same reason as the sign-in field: 'ChanDara' does not match 'chandara', and iOS
                // capitalises the first letter of a text input by default.
                pattern="[a-z0-9._\-]+"
                minLength={3}
            />
            <label className="flex flex-col gap-1 text-sm">
                {copy.passwordLabel}
                <input
                    type="password"
                    name="password"
                    required
                    minLength={8}
                    // new-password, not current-password: this tells a password manager to offer a
                    // generated one rather than autofilling the admin's own.
                    autoComplete="new-password"
                    placeholder="••••••••"
                    data-testid="create-password"
                    className="rounded-xl border border-black/20 px-3 py-2 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:border-white/25 dark:bg-black/30"
                />
                <span className="text-xs text-black/50 dark:text-white/50">{copy.passwordHint}</span>
            </label>

            <label className="flex flex-col gap-1 text-sm">
                {copy.roleLabel}
                <select
                    name="role"
                    required
                    value={role}
                    onChange={(event) => setRole(event.target.value as 'HOSPITAL' | 'ADMIN')}
                    data-testid="create-role-select"
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
                        testId="create-hospital-select"
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
                    <input type="hidden" name="hospitalId" value="" />
                    <p className="text-sm text-black/60 dark:text-white/60">{copy.adminNoHospital}</p>
                </>
            )}

            <button
                type="submit"
                data-testid="create-submit"
                className="self-start rounded-xl bg-brand px-4 py-2 text-sm font-medium text-white shadow-sm transition-opacity hover:opacity-90 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand"
            >
                {copy.createCta}
            </button>
        </form>
    );
}

function Text({
    name,
    label,
    hint,
    placeholder,
    autoComplete,
    pattern,
    minLength,
}: {
    name: string;
    label: string;
    hint: string;
    placeholder: string;
    autoComplete: string;
    pattern?: string;
    minLength?: number;
}) {
    return (
        <label className="flex flex-col gap-1 text-sm">
            {label}
            <input
                type="text"
                name={name}
                required
                placeholder={placeholder}
                autoComplete={autoComplete}
                autoCapitalize="none"
                autoCorrect="off"
                spellCheck={false}
                pattern={pattern}
                minLength={minLength}
                data-testid={`create-${name}`}
                className="rounded-xl border border-black/20 px-3 py-2 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:border-white/25 dark:bg-black/30"
            />
            <span className="text-xs text-black/50 dark:text-white/50">{hint}</span>
        </label>
    );
}
