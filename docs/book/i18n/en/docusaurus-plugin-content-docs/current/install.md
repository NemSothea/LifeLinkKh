---
title: Install the app
sidebar_position: 2
description: How to download and install the LifeLink KH Android app outside the Play Store, check the file, and update it.
---

# Install the app (Android)

LifeLink KH is free, and it is **not on the Play Store yet**. You download the APK file from the
website and install it yourself. It takes about a minute.

**You need:** an Android phone with Android 7.0 or newer.

## 1. Download

On your phone, open [lifelinkkh.vercel.app/en/download](https://lifelinkkh.vercel.app/en/download)
and tap **Download for Android (APK)**.

On a computer? The download page shows a QR code. Scan it with your phone's camera to open the
page on the phone.

:::warning Download it only from the LifeLink website
Don't install a LifeLink APK that someone sends you on Telegram or Facebook. It may not be ours.
:::

## 2. Allow the install

Open the downloaded file. If Android says installing from this source is not allowed, tap
**Settings**, turn on **Allow from this source** for your browser, then go back.

## 3. Install

Tap **Install**. Android or Google Play Protect may say **"This app may be unsafe"**. It says this
about every app that doesn't come from the Play Store; it doesn't mean something was found in
LifeLink. Choose **Install anyway**.

## 4. Open and sign in

Open LifeLink and sign in with Google (or Facebook under **More ways to sign in**). Then follow
the [donor guide](./donor-guide.md) or the [requester guide](./requester-guide.md).

## Updates

The app tells you when a new version is out. Go back to the download page, download it again and
install it **over** the old one. You stay signed in and keep your history. You don't need to
uninstall first.

## Check the file (optional)

Each release on [GitHub Releases](https://github.com/NemSothea/LifeLinkKh/releases/latest) has two
files: `lifelink-kh.apk` and `lifelink-kh.apk.sha256`, its fingerprint. On a computer, put both in
one folder and run:

```bash
shasum -a 256 -c lifelink-kh.apk.sha256      # macOS / Linux: prints "lifelink-kh.apk: OK"
```

The release notes also show the **signing certificate** fingerprint. It is the same for every
release. If it ever changes, don't install, and tell us.

## Uninstall

Settings → Apps → LifeLink → Uninstall. Uninstalling does **not** delete your account. To delete
your data, use **Me → Delete account** in the app first, or the
[account deletion page](https://lifelinkkh.vercel.app/en/delete-account).

## iPhone

Not available yet. The iOS app builds, but it is not on the App Store.
