import Link from 'next/link';
import type { ReactNode } from 'react';
import { Button } from '@/components/ui/button';

/**
 * A navigation link people should notice — back, privacy, deletion, sign-in: the shadcn outline
 * Button rendered as a link, with an icon first. An icon says what it does before the words
 * are read, which matters most in Khmer at small sizes.
 */
export default function PillLink({
    href,
    icon,
    children,
    testId,
}: {
    href: string;
    icon: ReactNode;
    children: ReactNode;
    testId?: string;
}) {
    return (
        <Button asChild variant="outline" className="rounded-full">
            <Link href={href} data-testid={testId}>
                {icon}
                {children}
            </Link>
        </Button>
    );
}
