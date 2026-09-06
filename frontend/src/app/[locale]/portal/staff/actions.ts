'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { assignStaffRole } from '@/lib/api/admin';

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

    revalidatePath(`/${locale}/portal/admin`);
    redirect(
        result.ok
            ? // The name comes back from the API response, not the form — a hidden field
              // fed from the currently-selected <option> would need client-side JS to stay
              // in sync with the dropdown, for a label the server already knows.
              `/${locale}/portal/admin?promoted=${encodeURIComponent(result.data.displayName ?? '')}`
            : `/${locale}/portal/admin?promoteError=1`,
    );
}
