/**
 * Both labels for one district, as every LifeLink API sends them.
 *
 * A leaf value, deliberately shared by `board.ts` and `portal.ts` even though those two keep
 * their response shapes apart on purpose: this is not a response shape, and two copies of it
 * drifting is how `BUG-API-004` looked from the client side — the hospital's district localized,
 * the donor's not, on the same card.
 *
 * The API never picks a language. The portal switches locale in the browser with no re-fetch, so
 * a server-chosen label would be the wrong one for half the readers (`CR-MAPI-001`).
 */
export type DistrictName = {
    km: string;
    en: string;
};

/** The label for the locale being rendered. Falls back to English for any unknown locale. */
export function districtLabel(district: DistrictName | null | undefined, locale: string): string | null {
    if (!district) return null;
    return locale === 'km' ? district.km : district.en;
}
