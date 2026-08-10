import { getTranslations } from 'next-intl/server';
import HealthStatus from '@/components/HealthStatus';
import { getHealth } from '@/lib/api/health';

/**
 * M2 page: proves the whole chain — browser to Next server to the backend container to
 * PostgreSQL. Nothing here is mocked; stopping the backend renders the handled error
 * state rather than throwing.
 */
export default async function HomePage() {
    const t = await getTranslations('app');
    const health = await getHealth();

    return (
        <main className="mx-auto max-w-2xl p-8">
            <h1 className="mb-6 text-2xl font-semibold">{t('title')}</h1>
            <HealthStatus
                reachable={health.ok}
                status={health.ok ? health.data.status : undefined}
            />
        </main>
    );
}
