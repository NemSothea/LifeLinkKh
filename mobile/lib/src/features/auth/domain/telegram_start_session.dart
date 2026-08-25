/// The result of `POST /auth/telegram/start` — an invitation to open a session, not one
/// itself. The app still has no account and no JWT at this point.
class TelegramStartSession {
    const TelegramStartSession({required this.sessionToken, required this.deepLink});

    /// Opaque, passed back unchanged to `POST /auth/telegram/verify`.
    final String sessionToken;

    /// `https://t.me/<bot>?start=<sessionToken>` — opening it hands the donor to the
    /// Telegram app, which sends `/start <sessionToken>` to the bot on their behalf.
    final String deepLink;
}
