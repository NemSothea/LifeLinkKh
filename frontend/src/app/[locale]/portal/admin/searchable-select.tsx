'use client';

import { useEffect, useId, useRef, useState } from 'react';

export type SearchableOption = {
    value: string;
    label: string;
    sublabel?: string;
    searchText: string;
};

/**
 * A text input + filtered listbox standing in for a plain `<select>`, for a list that
 * needs custom option rendering (a candidate's role as subtext, here) that a native
 * `<select>` cannot do and would only grow further past — not a combobox package,
 * since the whole list is already fetched and in memory (`portal/icons.tsx`'s "small
 * enough to hand-roll" precedent, same reasoning applied to a form control).
 *
 * Still submits through the same `<form action={...}>` Server Action as a real
 * `<select>` would: this renders a hidden `name`-bearing input alongside the visible
 * combobox, so the page/action that uses it needs no changes beyond swapping the tag.
 */
export default function SearchableSelect({
    name,
    options,
    placeholder,
    required,
    testId,
    defaultValue,
    noMatchesLabel,
}: {
    name: string;
    options: SearchableOption[];
    placeholder: string;
    required?: boolean;
    testId: string;
    defaultValue?: string;
    noMatchesLabel: string;
}) {
    const [query, setQuery] = useState('');
    const [open, setOpen] = useState(false);
    const [highlighted, setHighlighted] = useState(0);
    const [selected, setSelected] = useState<SearchableOption | null>(
        () => options.find((option) => option.value === defaultValue) ?? null,
    );
    const containerRef = useRef<HTMLDivElement>(null);
    const listboxId = useId();

    const filtered =
        query.trim() === ''
            ? options
            : options.filter((option) =>
                  option.searchText.toLowerCase().includes(query.toLowerCase()),
              );

    useEffect(() => {
        if (!open) return;
        function onPointerDown(event: MouseEvent) {
            if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
                setOpen(false);
            }
        }
        document.addEventListener('mousedown', onPointerDown);
        return () => document.removeEventListener('mousedown', onPointerDown);
    }, [open]);

    function commit(option: SearchableOption) {
        setSelected(option);
        setQuery('');
        setOpen(false);
    }

    function onKeyDown(event: React.KeyboardEvent<HTMLInputElement>) {
        if (event.key === 'ArrowDown') {
            event.preventDefault();
            setOpen(true);
            setHighlighted((h) => Math.min(h + 1, filtered.length - 1));
        } else if (event.key === 'ArrowUp') {
            event.preventDefault();
            setHighlighted((h) => Math.max(h - 1, 0));
        } else if (event.key === 'Enter') {
            const option = filtered[highlighted];
            if (open && option) {
                event.preventDefault();
                commit(option);
            }
        } else if (event.key === 'Escape') {
            setOpen(false);
        }
    }

    return (
        <div ref={containerRef} className="relative">
            <input type="hidden" name={name} value={selected?.value ?? ''} required={required} />
            <input
                type="text"
                role="combobox"
                aria-expanded={open}
                aria-controls={listboxId}
                aria-autocomplete="list"
                aria-activedescendant={open && filtered[highlighted] ? `${listboxId}-${highlighted}` : undefined}
                data-testid={testId}
                className="w-full rounded-xl border border-black/20 px-2 py-1.5 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand dark:border-white/25 dark:bg-black/30"
                placeholder={placeholder}
                value={open ? query : (selected?.label ?? '')}
                onFocus={() => {
                    setOpen(true);
                    setQuery('');
                    setHighlighted(0);
                }}
                onChange={(event) => {
                    setQuery(event.target.value);
                    setOpen(true);
                    setHighlighted(0);
                }}
                onKeyDown={onKeyDown}
            />
            {open ? (
                <ul
                    id={listboxId}
                    role="listbox"
                    className="absolute z-10 mt-1 max-h-56 w-full overflow-auto rounded-xl border border-black/10 bg-white py-1 shadow-lg dark:border-white/15 dark:bg-neutral-900"
                >
                    {filtered.length === 0 ? (
                        <li className="px-3 py-2 text-sm text-black/50 dark:text-white/50">
                            {noMatchesLabel}
                        </li>
                    ) : (
                        filtered.map((option, index) => (
                            <li
                                key={option.value}
                                id={`${listboxId}-${index}`}
                                role="option"
                                aria-selected={index === highlighted}
                                data-testid={`${testId}-option-${option.value}`}
                                className={`cursor-pointer px-3 py-2 text-sm ${
                                    index === highlighted ? 'bg-brand/10' : ''
                                }`}
                                // mousedown, not click/onClick: click fires after the input's
                                // own blur, which would already have closed the list.
                                onMouseDown={(event) => {
                                    event.preventDefault();
                                    commit(option);
                                }}
                                onMouseEnter={() => setHighlighted(index)}
                            >
                                <div>{option.label}</div>
                                {option.sublabel ? (
                                    <div className="text-xs text-black/50 dark:text-white/50">
                                        {option.sublabel}
                                    </div>
                                ) : null}
                            </li>
                        ))
                    )}
                </ul>
            ) : null}
        </div>
    );
}
