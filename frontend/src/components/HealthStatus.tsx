import { useTranslations } from 'next-intl';

type Props = { reachable: boolean; status?: string };

/**
 * Presentational only, so the reachable and unreachable states are both testable
 * without a running backend.
 */
export default function HealthStatus({ reachable, status }: Props) {
    const t = useTranslations('app');

    return (
        <section className="rounded-lg border border-black/10 p-4 dark:border-white/20">
            <h2 className="mb-2 text-lg font-medium">{t('healthHeading')}</h2>
            {reachable ? (
                <p data-testid="health-up" className="text-green-700 dark:text-green-400">
                    {t('healthUp')}
                    {status ? ` (${status})` : null}
                </p>
            ) : (
                <p data-testid="health-down" className="text-red-700 dark:text-red-400">
                    {t('healthUnreachable')}
                </p>
            )}
        </section>
    );
}
