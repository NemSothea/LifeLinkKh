import Link from 'next/link';
import type { StaffMember } from '@/lib/api/admin';

/**
 * Filters the staff list by role and by hospital.
 *
 * Links rather than a client component with state, for two reasons. The page around it is
 * a Server Component and the filtering happens server-side, so a filtered view costs one
 * navigation and no JavaScript at all. And the result is a URL: an admin can send
 * `?hospital=<id>` to a colleague, or bookmark the one hospital they actually run.
 *
 * Hospital chips are built from the staff themselves, not from the hospital list — an
 * option that matches nobody is a dead control, and the seeded hospital table is longer
 * than the list of hospitals that actually have staff.
 */
export default function StaffFilter({
    staff,
    locale,
    role,
    hospital,
    copy,
}: {
    staff: StaffMember[];
    locale: string;
    role?: string;
    hospital?: string;
    copy: { all: string; admins: string; hospitalStaff: string };
}) {
    const hospitals = [
        ...new Map(
            staff
                .filter((m) => m.hospitalId && m.hospitalName)
                .map((m) => [m.hospitalId!, m.hospitalName!] as const),
        ),
    ].sort((a, b) => a[1].localeCompare(b[1]));

    // Every chip keeps the other dimension, so picking a hospital does not silently drop
    // a role already chosen.
    const href = (next: { role?: string; hospital?: string }) => {
        const params = new URLSearchParams();
        const nextRole = 'role' in next ? next.role : role;
        const nextHospital = 'hospital' in next ? next.hospital : hospital;
        if (nextRole) params.set('role', nextRole);
        if (nextHospital) params.set('hospital', nextHospital);
        const query = params.toString();
        return `/${locale}/portal/staff${query ? `?${query}` : ''}`;
    };

    return (
        <div data-testid="staff-filter" className="mb-3 flex flex-wrap items-center gap-2">
            <Chip href={href({ role: undefined })} active={!role} label={copy.all} />
            <Chip href={href({ role: 'ADMIN' })} active={role === 'ADMIN'} label={copy.admins} />
            <Chip
                href={href({ role: 'HOSPITAL' })}
                active={role === 'HOSPITAL'}
                label={copy.hospitalStaff}
            />
            {hospitals.length > 1
                ? hospitals.map(([id, name]) => (
                      <Chip
                          key={id}
                          href={href({ hospital: hospital === id ? undefined : id })}
                          active={hospital === id}
                          label={name}
                      />
                  ))
                : null}
        </div>
    );
}

function Chip({ href, active, label }: { href: string; active: boolean; label: string }) {
    return (
        <Link
            href={href}
            aria-current={active ? 'true' : undefined}
            className={
                active
                    ? 'rounded-full bg-brand px-3 py-1 text-sm font-semibold text-white'
                    : 'rounded-full border border-black/10 px-3 py-1 text-sm text-black/70 hover:border-black/25 dark:border-white/15 dark:text-white/70 dark:hover:border-white/30'
            }
        >
            {label}
        </Link>
    );
}
