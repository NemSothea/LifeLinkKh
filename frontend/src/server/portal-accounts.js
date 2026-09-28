// Portal accounts (ADR 0009). v1 has one portal role, ADMIN: a custom claim plus an admins/{uid}
// record, both written by firebase/seed/admin.mjs. There are no hospital staff and no callable
// that grants access — an admin is made by whoever can run the seed against the project.

/**
 * Firebase Auth signs in with an email, and a portal account has a username. This is the one
 * mapping between them, and the portal's sign-in (`frontend/src/lib/api/portal-auth.ts`) has the
 * same function — change both or neither. `.invalid` is reserved (RFC 2606): no mail can ever be
 * delivered to it, so nothing here pretends an admin has an inbox.
 */
export function portalEmail(username) {
    return `${username}@portal.lifelink.invalid`;
}

/** The rules' isAdmin(), server-side: the claim and the record must both be there. */
export async function isAdmin(db, caller) {
    if (!caller?.uid || caller.token?.role !== 'ADMIN') return false;
    return (await db.doc(`admins/${caller.uid}`).get()).exists;
}
