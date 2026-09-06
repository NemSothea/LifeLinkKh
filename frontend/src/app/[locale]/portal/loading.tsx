/**
 * What the browser shows while `page.tsx`'s two `fetch` calls are in flight.
 *
 * Both portal pages are async Server Components: Next streams nothing until the server
 * has its data, so without this file the tab sits blank — indistinguishable from a
 * hung page on the hospital wi-fi this is actually used on. A skeleton shaped like the
 * real list also stops the layout jumping when the rows arrive.
 *
 * Deliberately not translated: there is no text here. A spinner captioned "Loading…" in
 * the wrong language is worse than a shape that needs no language at all.
 */
export default function PortalLoading() {
    return (
        <main className="mx-auto max-w-4xl p-6 sm:p-10" aria-busy="true" aria-live="polite">
            <header className="mb-8 flex flex-wrap items-end justify-between gap-3">
                <div className="flex flex-col gap-2">
                    <Bar className="h-3 w-24" />
                    <Bar className="h-8 w-56" />
                </div>
                <Bar className="h-10 w-44 rounded-full" />
            </header>

            <div className="mb-6 flex flex-wrap items-center gap-3">
                <Bar className="h-9 min-w-[220px] flex-1 rounded-full" />
                <Bar className="h-9 w-64 rounded-full" />
            </div>

            <ul className="flex flex-col gap-4">
                {[0, 1, 2, 3, 4].map((row) => (
                    <li
                        key={row}
                        className="flex items-center gap-4 rounded-2xl border border-black/10 bg-white p-5 dark:border-white/15 dark:bg-white/[0.03]"
                    >
                        <Bar className="h-11 w-11 shrink-0 rounded-full" />
                        <div className="flex min-w-0 flex-1 flex-col gap-2">
                            <Bar className="h-4 w-48" />
                            <Bar className="h-3 w-64" />
                        </div>
                        <Bar className="hidden h-7 w-32 rounded-full sm:block" />
                    </li>
                ))}
            </ul>
        </main>
    );
}

/** One grey block. `motion-safe:` so a reduce-motion setting gets a still skeleton. */
function Bar({ className }: { className: string }) {
    return (
        <div
            aria-hidden="true"
            className={`motion-safe:animate-pulse rounded-lg bg-black/[0.07] dark:bg-white/[0.07] ${className}`}
        />
    );
}
