import { useTranslations } from 'next-intl';

type Props = { reachable: boolean; status?: string };

/**
 * Presentational only, so the reachable and unreachable states are both testable
 * without a running backend.
 *
 * Deliberately quiet since the landing page stopped being the M2 health page: it still
 * proves the whole chain (browser → Next server → backend → PostgreSQL, nothing mocked),
 * which is worth keeping on screen, but a bordered card gave a diagnostic the same
 * visual weight as the portal itself. A dot and a line of small text says the same
 * thing without competing.
 */
export default function HealthStatus({ reachable, status }: Props) {
    const t = useTranslations('app');

    return (
        <section className="flex items-center gap-2 text-xs text-black/50 dark:text-white/50">
            <span
                className={`h-1.5 w-1.5 shrink-0 rounded-full ${
                    reachable ? 'bg-emerald-500' : 'bg-red-500'
                }`}
                aria-hidden="true"
            />
            <span className="font-medium">{t('healthHeading')}</span>
            {reachable ? (
                <span data-testid="health-up">
                    {t('healthUp')}
                    {status ? ` (${status})` : null}
                </span>
            ) : (
                <span data-testid="health-down" className="text-red-600 dark:text-red-400">
                    {t('healthUnreachable')}
                </span>
            )}
        </section>
    );
}
