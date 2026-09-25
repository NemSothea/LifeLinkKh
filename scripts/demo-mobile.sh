#!/usr/bin/env bash
# Put the Flutter app on a device for a demo, with the right API_BASE_URL for that device.
#
#   bash scripts/demo-mobile.sh                 # Android emulator (boots the donor AVD if none runs)
#   bash scripts/demo-mobile.sh emulator [avd]  # same, naming the AVD (default Medium_Phone_API_36.0)
#   bash scripts/demo-mobile.sh usb             # physical Android on a cable, via adb reverse
#   bash scripts/demo-mobile.sh ios             # booted iOS simulator (no push — never the donor)
#
# Picking the base URL by hand is the mistake this script exists to remove: 10.0.2.2 is the
# emulator's alias for the host, a cabled phone reaches the host only through `adb reverse`,
# and the simulator shares the Mac's loopback. A wrong one looks exactly like a dead backend.
#
# The last step is `flutter run`, which stays attached (r = hot reload, q = quit).
# The wireless demo is a different build entirely — scripts/build-demo-apk.sh (runbook §10).
set -euo pipefail
cd "$(dirname "$0")/.."

sdk="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
adb="$sdk/platform-tools/adb"
emulator="$sdk/emulator/emulator"
target="${1:-emulator}"

if ! curl -fsS --max-time 3 http://127.0.0.1:8080/api/health >/dev/null 2>&1; then
    echo "❌ backend not answering on :8080 — run: bash scripts/dev-up.sh"
    exit 1
fi

# A snapshot-restored AVD can hold a dead FCM socket: the backend logs `sent (…)` and nothing
# arrives (runbook §8.5). Cycling airplane mode forces a fresh connection before the first push.
refresh_fcm() {
    "$adb" -s "$1" shell cmd connectivity airplane-mode enable >/dev/null 2>&1 || true
    sleep 3
    "$adb" -s "$1" shell cmd connectivity airplane-mode disable >/dev/null 2>&1 || true
    echo "📶 airplane mode cycled on $1 (fresh FCM connection)"
}

case "$target" in
    emulator)
        avd="${2:-Medium_Phone_API_36.0}"
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
        base="http://10.0.2.2:8080/api"
        ;;
    usb)
        device=$("$adb" devices | awk '$2 == "device" && $1 !~ /^emulator-/ {print $1; exit}')
        if [ -z "$device" ]; then
            echo "❌ no physical Android device on adb. Cable in, USB debugging on, accept the prompt."
            exit 1
        fi
        # The phone's own 127.0.0.1:8080 now tunnels to this Mac's :8080 over the cable,
        # so the backend can stay bound to loopback — no --lan needed.
        "$adb" -s "$device" reverse tcp:8080 tcp:8080 >/dev/null
        echo "📱 phone: $device (adb reverse tcp:8080 → host)"
        base="http://127.0.0.1:8080/api"
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
        base="http://127.0.0.1:8080/api"
        ;;
    *)
        echo "usage: bash scripts/demo-mobile.sh [emulator [avd] | usb | ios]"
        exit 2
        ;;
esac

echo "🔗 API_BASE_URL=$base"
cd mobile
exec flutter run -d "$device" --dart-define=API_BASE_URL="$base"
