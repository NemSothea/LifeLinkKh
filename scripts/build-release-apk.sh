#!/usr/bin/env bash
# Build the APK that real users install — LifeLink is sideloaded, not on the Play Store, until it
# has 500 users (docs/tech-lead/deploy-runbook.md, "Path A").
#
#   bash scripts/build-release-apk.sh
#
# Produces dist/lifelink-kh.apk and prints what to publish. It publishes nothing itself: uploading
# to GitHub Releases and `npm run release` are yours to run, in that order, once you have tried
# the APK on a phone.
#
# Refuses to build without mobile/android/key.properties. Without it Gradle signs the release with
# this machine's DEBUG key (build.gradle.kts falls back so `flutter run --release` works), and an
# APK signed with a debug key can never be updated by one signed with the real key: every user
# would have to uninstall, and lose their sign-in, the day you switched. Same key, forever.
set -euo pipefail
cd "$(dirname "$0")/.."

props=mobile/android/key.properties
if [ ! -f "$props" ]; then
    echo "❌ $props is missing — this would be signed with the debug key."
    echo "   Create the upload keystore and key.properties first: docs/tech-lead/deploy-runbook.md Steps 1–2."
    exit 1
fi
store=$(sed -n 's/^storeFile=//p' "$props")
case "$store" in
    /*) store_path="$store" ;;
    *) store_path="mobile/android/app/$store" ;;
esac
if [ ! -f "$store_path" ]; then
    echo "❌ key.properties points at $store_path, which does not exist."
    exit 1
fi

version=$(sed -n 's/^version: *//p' mobile/pubspec.yaml)
name=${version%%+*}
code=${version##*+}
echo "── building LifeLink $name (versionCode $code) ─────────────────────"

# No --dart-define: a release must talk to the real project. FIRESTORE_EMULATOR or
# FUNCTIONS_EMULATOR compiled in would point every user at this laptop.
(cd mobile && flutter build apk --release)

mkdir -p dist
cp mobile/build/app/outputs/flutter-apk/app-release.apk dist/lifelink-kh.apk
echo
echo "✅ dist/lifelink-kh.apk ($(du -h dist/lifelink-kh.apk | cut -f1))"
echo "   file SHA-256: $(shasum -a 256 dist/lifelink-kh.apk | cut -d' ' -f1)"
cert=$(keytool -printcert -jarfile dist/lifelink-kh.apk 2>/dev/null | sed -n 's/^[[:space:]]*SHA256: //p' | head -1)
echo "   signing certificate SHA-256: ${cert:-<keytool could not read it>}"
if keytool -printcert -jarfile dist/lifelink-kh.apk 2>/dev/null | grep -q "CN=Android Debug"; then
    echo "❌ This APK is signed with the DEBUG key. Do not publish it — check key.properties."
    exit 1
fi

cat <<NEXT

Next, in this order:
  1. Install dist/lifelink-kh.apk on a real phone and sign in with Google.
     (Sign-in fails → the release SHA-1 is not in Firebase: deploy-runbook Step 4.)
  2. Upload it where users download it — one of:
       • the K.O.S.I.G.N store: https://kosignstore.wecambodia.com/ (upload dist/lifelink-kh.apk
         as LifeLink $name). Set APK_DOWNLOAD_URL on Vercel to LifeLink's page there, once.
       • GitHub Releases, the fallback the download page uses when APK_DOWNLOAD_URL is unset —
         the asset name must stay lifelink-kh.apk:
           gh release create v$name dist/lifelink-kh.apk --title "LifeLink $name" --notes "…"
  3. Tell installed apps about it (after the upload, never before):
       cd firebase && npm run release -- --version-code $code --version-name $name \
           --download-url https://<portal>/km/download --project lifelinkkh
     (add --min $code only if older builds must stop working)
  4. Optional: set APK_CERT_SHA256 on Vercel to the certificate SHA-256 above, so the
     download page shows it.
NEXT
