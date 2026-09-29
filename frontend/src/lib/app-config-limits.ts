/**
 * The caps `setAppConfig` enforces, kept here so the form stops at them instead of the server.
 * A module of its own because the App version form is a client component: importing these from
 * `lib/api/app-config.ts` would pull its server-only session code into the browser bundle.
 */
export const VERSION_NAME_MAX = 32;
export const NOTES_MAX = 500;
