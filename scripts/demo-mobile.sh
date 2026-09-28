#!/usr/bin/env bash
# Put the Flutter app on a device for a demo (ADR 0009: the app talks to Firebase, no backend).
#
#   bash scripts/demo-mobile.sh                 # Android emulator (boots the donor AVD if none runs)
#   bash scripts/demo-mobile.sh emulator [avd]  # same, naming the AVD (default Medium_Phone_API_36.0)
#   bash scripts/demo-mobile.sh usb             # physical Android on a cable
#   bash scripts/demo-mobile.sh ios             # booted iOS simulator (no push — never the donor)
#
# Add --firestore-emulator (anywhere) to read and write the local Firestore emulator started by
# `npm run emulators:app` in firebase/, instead of the real lifelinkkh project. The emulator's
# address differs per device — 10.0.2.2 is the Android emulator's alias for this Mac, a cabled
# phone reaches it only through `adb reverse`, the simulator shares the Mac's loopback — and a
# wrong one looks exactly like an empty database. Picking it is what this script is for.

set -euo pipefail
cd "$(dirname "$0")/.."

sdk="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
adb="$sdk/platform-tools/adb"
emulator="$sdk/emulator/emulator"
use_emulator=false
args=()
for arg in "$@"; do
    if [ "$arg" = "--firestore-emulator" ]; then use_emulator=true; else args+=("$arg"); fi
done
target="${args[0]:-emulator}"

if $use_emulator && ! curl -fsS --max-time 3 http://127.0.0.1:8081/ >/dev/null 2>&1; then
    echo "❌ Firestore emulator not answering on :8081 — in firebase/: npm run emulators:app"
    exit 1
fi

# A snapshot-restored AVD can hold a dead FCM socket: the Function logs a send and nothing
# arrives (runbook). Cycling airplane mode forces a fresh connection before the first push.
refresh_fcm() {
    "$adb" -s "$1" shell cmd connectivity airplane-mode enable >/dev/null 2>&1 || true
    sleep 3
    "$adb" -s "$1" shell cmd connectivity airplane-mode disable >/dev/null 2>&1 || true
    echo "📶 airplane mode cycled on $1 (fresh FCM connection)"
}

case "$target" in
    emulator)
        avd="${args[1]:-Medium_Phone_API_36.0}"
        device=$("$adb" devices | awk '/^emulator-[0-9]+\tdevice$/ {print $1; exit}')
        if [ -z "$device" ]; then
            echo "🚀 booting AVD $avd"
            nohup "$emulator" -avd "$avd" >/dev/null 2>&1 &
            "$adb" wait-for-device
            until [ "$("$adb" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
                sleep 2
            done
            device=$("$adb" devices | awk '/^emulator-[0-9]+\tdevice$/ {print $1; exit}')
        fi
        echo "📱 emulator: $device"
        refresh_fcm "$device"
        firestore="10.0.2.2:8081"
        portal="http://10.0.2.2:3000"
        ;;
    usb)
        device=$("$adb" devices | awk '$2 == "device" && $1 !~ /^emulator-/ {print $1; exit}')
        if [ -z "$device" ]; then
            echo "❌ no physical Android device on adb. Cable in, USB debugging on, accept the prompt."
            exit 1
        fi
        # With the emulator, the phone's own 127.0.0.1:8081 tunnels to this Mac's :8081, and
        # :3000 to the local portal, whose functions the app calls (ADR 0010).
        if $use_emulator; then
            "$adb" -s "$device" reverse tcp:8081 tcp:8081 >/dev/null
            "$adb" -s "$device" reverse tcp:3000 tcp:3000 >/dev/null
            echo "📱 phone: $device (adb reverse tcp:8081, tcp:3000 → host)"
        else
            echo "📱 phone: $device"
        fi
        firestore="127.0.0.1:8081"
        portal="http://127.0.0.1:3000"
        ;;
    ios)
        device=$(xcrun simctl list devices booted | awk -F'[()]' '/Booted/ {print $2; exit}')
        if [ -z "$device" ]; then
            echo "❌ no booted iOS simulator. Boot one: xcrun simctl boot \"iPhone 18 Pro\""
            exit 1
        fi
        echo "📱 simulator: $device"
        echo "⚠️  the simulator has no APNs — this account never receives a push."
        echo "   Fine for browsing; never the donor, and not the requester if the acceptance alert is shown."
        firestore="127.0.0.1:8081"
        portal="http://127.0.0.1:3000"
        ;;
    *)
        echo "usage: bash scripts/demo-mobile.sh [emulator [avd] | usb | ios] [--firestore-emulator]"
        exit 2
        ;;
esac

cd mobile
if $use_emulator; then
    echo "🔗 FIRESTORE_EMULATOR=$firestore  PORTAL_URL=$portal  (the portal must be running: npm run dev)"
    exec flutter run -d "$device" \
        --dart-define=FIRESTORE_EMULATOR="$firestore" \
        --dart-define=PORTAL_URL="$portal"
fi
echo "🔗 real Firebase project lifelinkkh"
exec flutter run -d "$device"
