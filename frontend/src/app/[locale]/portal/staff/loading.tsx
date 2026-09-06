/**
 * Same reason as `../loading.tsx`: this page awaits three calls in parallel
 * (`listStaff`, `listCandidates`, `listHospitals`) before it can render anything, and a
 * blank tab for the length of the slowest one reads as broken.
 */
export default function StaffLoading() {
    return (
        <main className="mx-auto max-w-2xl p-6 sm:p-10" aria-busy="true" aria-live="polite">
            <header className="mb-8 flex flex-col gap-2">
                <Bar className="h-3 w-24" />
                <Bar className="h-8 w-52" />
            </header>

            <section className="mb-10 flex flex-col gap-3">
                <Bar className="h-5 w-32" />
                {[0, 1].map((row) => (
                    <div
                        key={row}
                        className="flex items-center justify-between gap-3 rounded-xl border border-black/10 bg-white p-3 dark:border-white/10 dark:bg-white/[0.03]"
                    >
                        <Bar className="h-4 w-40" />
                        <Bar className="h-4 w-48" />
                    </div>
                ))}
            </section>

            <section className="flex flex-col gap-4 rounded-2xl border border-black/10 bg-white p-5 dark:border-white/15 dark:bg-white/[0.03]">
                <Bar className="h-4 w-16" />
                <Bar className="h-9 w-full rounded-xl" />
                <Bar className="h-4 w-24" />
                <Bar className="h-9 w-full rounded-xl" />
                <Bar className="h-9 w-32 rounded-xl" />
            </section>
        </main>
    );
}

function Bar({ className }: { className: string }) {
    return (
        <div
            aria-hidden="true"
            className={`motion-safe:animate-pulse rounded-lg bg-black/[0.07] dark:bg-white/[0.07] ${className}`}
        />
    );
}
