import { Fragment } from 'react';

/**
 * Renders a message string with its key phrases picked out, so a reader skimming a long page
 * (privacy, getting blood) lands on the parts that matter: what is never done, what is free,
 * the numbers to remember. A phrase is marked in `messages/{en,km}.json` as `**like this**`;
 * everything else is plain text. Mark both languages alike, and sparingly — a page where
 * everything is highlighted has nothing highlighted.
 *
 * The colour is the accent pair (#9f1d1d on light, #f3b4b4 on dark), both well over 4.5:1, not
 * the brand red, which in this portal means "critical".
 */
export default function Highlight({ text }: { text: string }) {
    const parts = text.split('**');
    return (
        <>
            {parts.map((part, i) =>
                i % 2 === 1 ? (
                    <strong key={i} className="font-semibold text-accent-foreground">
                        {part}
                    </strong>
                ) : (
                    <Fragment key={i}>{part}</Fragment>
                ),
            )}
        </>
    );
}
