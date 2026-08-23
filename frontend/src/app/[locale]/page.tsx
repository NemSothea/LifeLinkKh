import { getTranslations } from 'next-intl/server';
import HealthStatus from '@/components/HealthStatus';
import LanguageSwitcher from '@/components/LanguageSwitcher';
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
            <div className="mb-6 flex items-center justify-between gap-3">
                <h1 className="text-2xl font-semibold">{t('title')}</h1>
                <LanguageSwitcher />
            </div>
            <HealthStatus
                reachable={health.ok}
                status={health.ok ? health.data.status : undefined}
            />
        </main>
    );
}
