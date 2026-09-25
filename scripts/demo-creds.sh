#!/usr/bin/env bash
# The portal sign-ins for a demo, read from the local .env — never from the repository.
#
#   bash scripts/demo-creds.sh            # print usernames and passwords
#   bash scripts/demo-creds.sh staff      # copy the hospital-staff password to the clipboard
#   bash scripts/demo-creds.sh admin      # copy the admin password to the clipboard
#
# The repository is public. Passwords live in .env (gitignored) and nowhere else (DEC-013);
# this script is the fast way to get them onto the screen or the clipboard at demo time
# without ever writing one into a tracked file.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
    echo "❌ .env missing — copy .env.example to .env and set the portal passwords."
    exit 1
fi

# Grepped out rather than sourced: sourcing would run anything else in .env as shell.
value() { sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" .env | tail -n1; }

admin=$(value PORTAL_ADMIN_PASSWORD)
staff=$(value PORTAL_STAFF_PASSWORD)

case "${1:-}" in
    staff) printf '%s' "$staff" | pbcopy; echo "📋 staff password copied (calmette / tepi / july)" ;;
    admin) printf '%s' "$admin" | pbcopy; echo "📋 admin password copied (soborey)" ;;
    "")
        echo "Portal — http://localhost:3000/en/sign-in"
        echo
        printf '  %-10s %-9s %s\n' "calmette" "HOSPITAL" "${staff:-<PORTAL_STAFF_PASSWORD not set>}"
        printf '  %-10s %-9s %s\n' "tepi"     "HOSPITAL" "${staff:-<PORTAL_STAFF_PASSWORD not set>}"
        printf '  %-10s %-9s %s\n' "july"     "HOSPITAL" "${staff:-<PORTAL_STAFF_PASSWORD not set>}"
        printf '  %-10s %-9s %s\n' "soborey"  "ADMIN"    "${admin:-<PORTAL_ADMIN_PASSWORD not set>}"
        echo
        echo "Demo with calmette. Copy instead of showing: bash scripts/demo-creds.sh staff"
        ;;
    *) echo "usage: bash scripts/demo-creds.sh [staff|admin]"; exit 2 ;;
esac
