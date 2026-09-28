import type { ReactNode } from 'react';
import { CircleAlert, CircleCheck, TriangleAlert } from 'lucide-react';
import { cn } from '@/lib/utils';

const STYLES = {
    error: {
        icon: CircleAlert,
        className:
            'border-red-300 bg-red-50 text-red-800 dark:border-red-900 dark:bg-red-950/50 dark:text-red-300',
    },
    success: {
        icon: CircleCheck,
        className:
            'border-emerald-300 bg-emerald-50 text-emerald-900 dark:border-emerald-900 dark:bg-emerald-950/50 dark:text-emerald-300',
    },
    warning: {
        icon: TriangleAlert,
        className: 'border-amber-300 bg-warning-surface text-warning dark:border-amber-900',
    },
} as const;

/**
 * Every error, success and warning message in the portal, one look: a tinted box with an icon
 * first, so the kind of message reads before the words do. `role="alert"` by default so a
 * screen reader announces it when it appears.
 */
export default function Notice({
    tone,
    children,
    testId,
    className,
    role = 'alert',
}: {
    tone: keyof typeof STYLES;
    children: ReactNode;
    testId?: string;
    className?: string;
    role?: 'alert' | 'status' | 'note';
}) {
    const { icon: Icon, className: toneClass } = STYLES[tone];
    return (
        <p
            role={role}
            data-testid={testId}
            className={cn(
                'flex items-start gap-3 rounded-xl border px-4 py-3 text-sm',
                toneClass,
                className,
            )}
        >
            <Icon className="mt-0.5 size-5 shrink-0" aria-hidden="true" />
            <span className="min-w-0 flex-1">{children}</span>
        </p>
    );
}
