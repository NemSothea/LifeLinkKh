package kh.lifelink.api.request.dto;

/**
 * The requester's contact details.
 *
 * <p>Returned <strong>only</strong> to a donor whose own match response is ACCEPTED (TM-AUTH-001
 * I1). Never present before acceptance, on any endpoint, to any caller — including the endpoints
 * that return the request itself.
 *
 * @param phoneVerified always {@code false} in this build. Phone numbers stopped being verified
 *     when auth moved to Google Sign-In (ADR 0002), and the field exists so the client is forced to
 *     show that caveat rather than presenting an unverified number as a checked one.
 */
public record RequesterContact(String displayName, String phone, boolean phoneVerified) {

    public static RequesterContact of(String name, String phone) {
        return new RequesterContact(name, phone, false);
    }
}
