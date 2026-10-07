import type { ReactNode } from 'react';
import PublicHeader from './PublicHeader';
import styles from './public-site.module.css';

export default function PublicPage({
    locale,
    children,
    title,
    subtitle,
    eyebrow,
    testId,
}: {
    locale: string;
    children: ReactNode;
    title?: string;
    subtitle?: string;
    eyebrow?: string;
    testId?: string;
}) {
    return (
        <div className={styles.page}>
            <div className={styles.container}>
                <PublicHeader locale={locale} />
                <main className={styles.content} data-testid={testId}>
                    {title && (
                        <header className={styles.documentHeading}>
                            {eyebrow && <p className={styles.eyebrow}>{eyebrow}</p>}
                            <h1>{title}</h1>
                            {subtitle && <p>{subtitle}</p>}
                        </header>
                    )}
                    {children}
                </main>
            </div>
        </div>
    );
}
