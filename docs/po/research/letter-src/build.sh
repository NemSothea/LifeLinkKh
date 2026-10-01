#!/bin/sh
# Rebuild nbtc-letter-km.pdf and nbtc-letter-en.pdf from the HTML here (headless Chrome, A4, one page each).
# The HTML is the send version of ../nbtc-letter.md: it leaves out the lines marked planned, not built.
set -e
cd "$(dirname "$0")"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
for l in km en; do
  "$CHROME" --headless --disable-gpu --no-pdf-header-footer --virtual-time-budget=15000 \
    --print-to-pdf="../nbtc-letter-$l.pdf" "file://$PWD/letter-$l.html"
done
