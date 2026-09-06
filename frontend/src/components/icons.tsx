/**
 * Small inline icon set shared by the landing page and the portal. Hand-drawn paths,
 * not a library — a handful of SVGs is not worth an icon package as a dependency.
 */

type IconProps = { className?: string };

export function IconDroplet({ className }: IconProps) {
    return (
        <svg viewBox="0 0 24 24" fill="currentColor" className={className} aria-hidden="true">
            <path d="M12 2.5c-.3 0-.6.14-.79.38C9.7 5 6 10.2 6 14a6 6 0 1 0 12 0c0-3.8-3.7-9-5.21-11.12a1 1 0 0 0-.79-.38z" />
        </svg>
    );
}

export function IconBuilding({ className }: IconProps) {
    return (
        <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
            strokeLinejoin="round"
            className={className}
            aria-hidden="true"
        >
            <path d="M4 21V5a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v16" />
            <path d="M15 21V10a1 1 0 0 1 1-1h3a1 1 0 0 1 1 1v11" />
            <path d="M4 21h16" />
            <path d="M7.5 8h1M7.5 12h1M7.5 16h1" />
        </svg>
    );
}

export function IconBell({ className }: IconProps) {
    return (
        <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
            strokeLinejoin="round"
            className={className}
            aria-hidden="true"
        >
            <path d="M18 8a6 6 0 1 0-12 0c0 3.5-1 5.5-1.5 6.5A1 1 0 0 0 5.4 16h13.2a1 1 0 0 0 .9-1.5C19 13.5 18 11.5 18 8z" />
            <path d="M10 19a2 2 0 0 0 4 0" />
        </svg>
    );
}

export function IconCheck({ className }: IconProps) {
    return (
        <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            className={className}
            aria-hidden="true"
        >
            <circle cx="12" cy="12" r="9" />
            <path d="M8.5 12.5l2.3 2.3 4.7-5.1" />
        </svg>
    );
}

export function IconChevron({ className }: IconProps) {
    return (
        <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            className={className}
            aria-hidden="true"
        >
            <path d="M6 9l6 6 6-6" />
        </svg>
    );
}

export function IconAlertTriangle({ className }: IconProps) {
    return (
        <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            className={className}
            aria-hidden="true"
        >
            <path d="M12 3.5 21.5 20h-19L12 3.5z" />
            <path d="M12 9.5v4M12 17h.01" />
        </svg>
    );
}

export function IconSearch({ className }: IconProps) {
    return (
        <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            className={className}
            aria-hidden="true"
        >
            <circle cx="11" cy="11" r="7" />
            <path d="m21 21-4.35-4.35" />
        </svg>
    );
}

export function IconInbox({ className }: IconProps) {
    return (
        <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.6"
            strokeLinecap="round"
            strokeLinejoin="round"
            className={className}
            aria-hidden="true"
        >
            <path d="M4 12h4l2 3h4l2-3h4" />
            <path d="M5.5 5h13l2.5 7v7a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-7l2.5-7z" />
        </svg>
    );
}

export function IconArrowRight({ className }: IconProps) {
    return (
        <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
            strokeLinejoin="round"
            className={className}
            aria-hidden="true"
        >
            <path d="M5 12h14" />
            <path d="m13 6 6 6-6 6" />
        </svg>
    );
}

export function IconUsers({ className }: IconProps) {
    return (
        <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
            strokeLinejoin="round"
            className={className}
            aria-hidden="true"
        >
            <path d="M16 20v-1.5a3.5 3.5 0 0 0-3.5-3.5h-5A3.5 3.5 0 0 0 4 18.5V20" />
            <circle cx="10" cy="8" r="3.2" />
            <path d="M20 20v-1.5a3.5 3.5 0 0 0-2.6-3.38" />
            <path d="M15.5 5.2a3.2 3.2 0 0 1 0 5.6" />
        </svg>
    );
}

export function IconEye({ className }: IconProps) {
    return (
        <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
            strokeLinejoin="round"
            className={className}
            aria-hidden="true"
        >
            <path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z" />
            <circle cx="12" cy="12" r="3" />
        </svg>
    );
}

export function IconEyeOff({ className }: IconProps) {
    return (
        <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
            strokeLinejoin="round"
            className={className}
            aria-hidden="true"
        >
            <path d="M9.9 5.8A9.6 9.6 0 0 1 12 5.5c6 0 9.5 6.5 9.5 6.5a16 16 0 0 1-2.9 3.7" />
            <path d="M6.3 7.9A16 16 0 0 0 2.5 12S6 18.5 12 18.5a9.3 9.3 0 0 0 3.6-.7" />
            <path d="M10 10a2.8 2.8 0 0 0 4 4" />
            <path d="m3.5 3.5 17 17" />
        </svg>
    );
}
