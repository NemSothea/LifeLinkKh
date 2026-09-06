'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { assignStaffRole, createStaffAccount, demoteStaff, revokeStaff } from '@/lib/api/admin';

/**
 * TM-AUTH-001 E1's grant, as a form submission. `hospitalId` arrives as `''` for the
 * "no hospital — ADMIN" choice; the backend distinguishes "absent" from "wrong" itself,
 * so this only has to turn the empty string into `null`.
 */
export async function assignStaffRoleAction(formData: FormData) {
    const userId = formData.get('userId');
    const role = formData.get('role');
    const hospitalId = formData.get('hospitalId');
    const locale = formData.get('locale');

    if (
        typeof userId !== 'string' ||
        typeof role !== 'string' ||
        typeof hospitalId !== 'string' ||
        typeof locale !== 'string'
    ) {
        throw new Error('assign-staff-role form is missing a required field');
    }

    const result = await assignStaffRole(userId, role, hospitalId === '' ? null : hospitalId);

    revalidatePath(`/${locale}/portal/staff`);
    redirect(
        result.ok
            ? // The name comes back from the API response, not the form — a hidden field
              // fed from the currently-selected <option> would need client-side JS to stay
              // in sync with the dropdown, for a label the server already knows.
              `/${locale}/portal/staff?promoted=${encodeURIComponent(result.data.displayName ?? '')}`
            : `/${locale}/portal/staff?promoteError=1`,
    );
}

/**
 * Creates a portal account from scratch. The sibling of the promote action above, for staff with
 * no mobile account — before this the only way to add one was writing a Flyway migration.
 *
 * The password is read from the form on the server and forwarded from the server. It never appears
 * in a prop, a URL, a redirect or a log — same handling as sign-in.
 */
export async function createStaffAccountAction(formData: FormData) {
    const username = formData.get('username');
    const password = formData.get('password');
    const displayName = formData.get('displayName');
    const role = formData.get('role');
    const hospitalId = formData.get('hospitalId');
    const locale = formData.get('locale');

    if (
        typeof username !== 'string' ||
        typeof password !== 'string' ||
        typeof displayName !== 'string' ||
        typeof role !== 'string' ||
        typeof hospitalId !== 'string' ||
        typeof locale !== 'string'
    ) {
        throw new Error('create-staff-account form is missing a required field');
    }

    const result = await createStaffAccount({
        username: username.trim().toLowerCase(),
        password,
        displayName: displayName.trim(),
        role,
        hospitalId: hospitalId === '' ? null : hospitalId,
    });

    revalidatePath(`/${locale}/portal/staff`);
    redirect(
        result.ok
            ? `/${locale}/portal/staff?created=${encodeURIComponent(result.data.displayName ?? username)}`
            // 422 covers the one failure worth naming separately: the username is taken. An admin
            // is allowed to know that — unlike sign-in, there is nothing to enumerate here.
            : `/${locale}/portal/staff?createError=${result.error === 'HTTP 422' ? 'taken' : '1'}`,
    );
}

/** Maps the backend's business codes onto the query flag the page renders a message from. */
function actionErrorFlag(error: string): string {
    // 422 covers CANNOT_TARGET_SELF and LAST_ADMIN — both are refusals the admin can act on, and
    // both deserve their own sentence rather than "could not complete that".
    if (error === 'HTTP 422') return 'rule';
    return '1';
}

export async function revokeStaffAction(formData: FormData) {
    const userId = formData.get('userId');
    const locale = formData.get('locale');
    if (typeof userId !== 'string' || typeof locale !== 'string') {
        throw new Error('revoke form is missing a required field');
    }

    const result = await revokeStaff(userId);
    revalidatePath(`/${locale}/portal/staff`);
    redirect(
        result.ok
            ? `/${locale}/portal/staff?revoked=1`
            : `/${locale}/portal/staff?actionError=${actionErrorFlag(result.error)}`,
    );
}

export async function demoteStaffAction(formData: FormData) {
    const userId = formData.get('userId');
    const hospitalId = formData.get('hospitalId');
    const locale = formData.get('locale');
    if (
        typeof userId !== 'string' ||
        typeof hospitalId !== 'string' ||
        typeof locale !== 'string'
    ) {
        throw new Error('demote form is missing a required field');
    }

    const result = await demoteStaff(userId, hospitalId);
    revalidatePath(`/${locale}/portal/staff`);
    redirect(
        result.ok
            ? `/${locale}/portal/staff?demoted=${encodeURIComponent(result.data.displayName ?? '')}`
            : `/${locale}/portal/staff?actionError=${actionErrorFlag(result.error)}`,
    );
}
