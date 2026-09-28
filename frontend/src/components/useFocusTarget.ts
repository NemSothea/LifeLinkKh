'use client';

import { useEffect } from 'react';

/** Fired by the notification bell when it links to a card on the page already open. */
export const FOCUS_EVENT = 'lifelink:focus';

/**
 * Brings `#<prefix><id>` into view on a paginated list: turns to the page that holds it, scrolls to
 * it, opens it if it is a <details>, and flashes a ring. Runs for the URL hash on load and for the
 * bell's event when the list is already on screen.
 */
export function useFocusTarget(
    prefix: string,
    ids: string[],
    pageSize: number,
    setPage: (page: number) => void,
) {
    useEffect(() => {
        function focus(hash: string) {
            if (!hash.startsWith(`#${prefix}`)) return;
            const id = hash.slice(prefix.length + 1);
            const index = ids.indexOf(id);
            if (index < 0) return;
            setPage(Math.floor(index / pageSize) + 1);
            requestAnimationFrame(() =>
                requestAnimationFrame(() => {
                    const el = document.getElementById(`${prefix}${id}`);
                    if (!el) return;
                    el.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    el.querySelector('details')?.setAttribute('open', '');
                    el.classList.add('ring-2', 'ring-ring');
                    window.setTimeout(() => el.classList.remove('ring-2', 'ring-ring'), 1800);
                }),
            );
        }
        focus(window.location.hash);
        const onEvent = (e: Event) => focus((e as CustomEvent<string>).detail);
        window.addEventListener(FOCUS_EVENT, onEvent);
        return () => window.removeEventListener(FOCUS_EVENT, onEvent);
        // ids change on every refresh; the listener only needs the latest list.
    }, [prefix, ids.join(','), pageSize, setPage]); // eslint-disable-line react-hooks/exhaustive-deps
}
