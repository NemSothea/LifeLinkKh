#!/usr/bin/env bash
# Build the Android app for the wireless demo: a release APK that talks to this Mac's
# backend over the network instead of through a USB cable.
#
#   bash scripts/build-demo-apk.sh 172.20.10.5     # the Mac's fixed IP on the iPhone hotspot
#
# The address is compiled in (API_BASE_URL is a --dart-define), so the APK only works on the
# network it was built for. That is why the runbook gives the Mac a FIXED IP on the hotspot
# (docs/demo-runbook.md §10): the same APK then works at every rehearsal and on the day.
#
# Release, not debug: about twice as fast to launch, and with no key.properties it is
# signed with this machine's debug key — the one whose SHA-1 Firebase knows — so Google
# Sign-In still works. An APK built on any other machine will fail sign-in.
set -euo pipefail
cd "$(dirname "$0")/.."

ip="${1:-}"
if [ -z "$ip" ]; then
    echo "usage: bash scripts/build-demo-apk.sh <mac-ip-on-the-demo-network>"
    echo "       this Mac's current en0 address: $(ipconfig getifaddr en0 2>/dev/null || echo none)"
    exit 2
fi

base="http://$ip:8080/api"

# A warning, not a failure: building at home for the hotspot address is the normal case,
# and the backend is not reachable at that address until the Mac is on the hotspot.
if curl -fsS --max-time 3 "$base/health" >/dev/null 2>&1; then
    echo "✅ backend answers at $base/health"
else
    echo "⚠️  nothing answers at $base/health right now."
    echo "   Fine if you are building ahead of time for another network. On the demo"
    echo "   network, run: bash scripts/dev-up.sh --lan"
fi

(cd mobile && flutter build apk --release --dart-define=API_BASE_URL="$base")

out="mobile/build/app/outputs/flutter-apk/lifelink-demo-$ip.apk"
cp mobile/build/app/outputs/flutter-apk/app-release.apk "$out"
echo
echo "📦 $out"
echo "   API_BASE_URL=$base"
echo "   Install: send it to the phone (Drive, Telegram) and open it, or once over USB:"
echo "   adb install -r $out"
