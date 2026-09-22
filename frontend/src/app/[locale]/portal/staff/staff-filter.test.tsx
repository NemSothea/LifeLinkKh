import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import type { StaffMember } from '@/lib/api/admin';
import StaffFilter from './staff-filter';

const copy = { all: 'All', admins: 'Admins', hospitalStaff: 'Hospital staff' };

function member(over: Partial<StaffMember> & { id: string }): StaffMember {
    return {
        displayName: over.id,
        role: 'HOSPITAL',
        hospitalId: null,
        hospitalName: null,
        ...over,
    } as StaffMember;
}

const staff = [
    member({ id: 'a', role: 'ADMIN' }),
    member({ id: 'b', hospitalId: 'h1', hospitalName: 'Calmette Hospital' }),
    member({ id: 'c', hospitalId: 'h1', hospitalName: 'Calmette Hospital' }),
    member({ id: 'd', hospitalId: 'h2', hospitalName: 'Preah Kossamak Hospital' }),
];

describe('StaffFilter', () => {
    it('offers one chip per hospital that actually has staff, not per hospital that exists', () => {
        render(<StaffFilter staff={staff} locale="en" copy={copy} />);

        expect(screen.getByRole('link', { name: 'Calmette Hospital' })).toBeInTheDocument();
        expect(screen.getByRole('link', { name: 'Preah Kossamak Hospital' })).toBeInTheDocument();
        // Duplicated hospital, one chip.
        expect(screen.getAllByRole('link', { name: 'Calmette Hospital' })).toHaveLength(1);
    });

    /// Picking a hospital must not silently discard a role the admin already chose, or the
    /// two filters fight each other and neither is trustworthy.
    it('keeps the role when a hospital chip is followed, and vice versa', () => {
        render(<StaffFilter staff={staff} locale="km" role="ADMIN" copy={copy} />);

        expect(screen.getByRole('link', { name: 'Calmette Hospital' })).toHaveAttribute(
            'href',
            '/km/portal/staff?role=ADMIN&hospital=h1',
        );
    });

    it('marks the active chip and lets it clear itself', () => {
        render(<StaffFilter staff={staff} locale="en" hospital="h1" copy={copy} />);

        const active = screen.getByRole('link', { name: 'Calmette Hospital' });
        expect(active).toHaveAttribute('aria-current', 'true');
        // Tapping the active chip removes the filter rather than reapplying it — a filter
        // you cannot undo without hunting for "All" is a trap.
        expect(active).toHaveAttribute('href', '/en/portal/staff');
    });

    it('hides hospital chips when every staff member is at the same hospital', () => {
        const oneHospital = staff.filter((m) => m.hospitalId !== 'h2');

        render(<StaffFilter staff={oneHospital} locale="en" copy={copy} />);

        expect(screen.queryByRole('link', { name: 'Calmette Hospital' })).toBeNull();
        // The role chips stay: ADMIN vs HOSPITAL is still a real distinction there.
        expect(screen.getByRole('link', { name: 'Admins' })).toBeInTheDocument();
    });
});
