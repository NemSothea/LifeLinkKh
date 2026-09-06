/**
 * A timestamp's *age*, in the pieces a message string needs.
 *
 * The portal fetches `createdAt` on every request and `respondedAt` on every accepted
 * donor, and rendered neither. For an emergency console those are the two numbers that
 * decide what staff do next: a CRITICAL request with nobody accepted is a different
 * problem at three minutes than at forty, and the row looks identical either way
 * without this.
 *
 * Deliberately not `Intl.RelativeTimeFormat`: its Khmer output is not something this
 * team can review, and the mobile client already answers the same question through its
 * own ARB strings. Same buckets on both clients, both translated by hand.
 */
export type RelativeAge =
    | { unit: 'now' }
    | { unit: 'minutes'; value: number }
    | { unit: 'hours'; value: number }
    | { unit: 'days'; value: number }
    | { unit: 'date'; value: string };

export function relativeAge(iso: string, now: Date = new Date()): RelativeAge {
    const then = new Date(iso);
    const minutes = Math.floor((now.getTime() - then.getTime()) / 60_000);

    // A clock a few seconds ahead of the server would otherwise render a negative age.
    if (minutes < 1) return { unit: 'now' };
    if (minutes < 60) return { unit: 'minutes', value: minutes };
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return { unit: 'hours', value: hours };
    const days = Math.floor(hours / 24);
    if (days < 7) return { unit: 'days', value: days };
    return { unit: 'date', value: iso };
}

/** Minutes old, for the triage rules that need a raw number rather than a label. */
export function minutesOld(iso: string, now: Date = new Date()): number {
    return Math.max(0, Math.floor((now.getTime() - new Date(iso).getTime()) / 60_000));
}

/** Whether a timestamp falls on the viewer's own current calendar day. */
export function isToday(iso: string, now: Date = new Date()): boolean {
    const then = new Date(iso);
    return (
        then.getFullYear() === now.getFullYear() &&
        then.getMonth() === now.getMonth() &&
        then.getDate() === now.getDate()
    );
}
