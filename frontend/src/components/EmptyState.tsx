/**
 * Shared by the portal's server-rendered "unreachable"/"no open requests at all" states
 * (`portal/page.tsx`) and the client-rendered "nothing matches your filter" state
 * (`portal/request-list.tsx`) — same visual treatment for "there is nothing here right
 * now," whichever reason produced it.
 */
export default function EmptyState({
    icon,
    children,
    testId,
}: {
    icon: React.ReactNode;
    children: React.ReactNode;
    testId: string;
}) {
    return (
        <div
            data-testid={testId}
            className="flex flex-col items-center gap-3 rounded-2xl border border-dashed border-black/15 py-16 text-center text-black/50 dark:border-white/15 dark:text-white/50"
        >
            {icon}
            <p>{children}</p>
        </div>
    );
}
