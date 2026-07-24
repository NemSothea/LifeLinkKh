#!/usr/bin/env bash
# Capybara validator — checks conventions. Lists violations, exits non-zero. No auto-fix.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
fail=0
note(){ echo "VIOLATION: $*"; fail=1; }

# 1. setup.md present
[ -f .capybara/setup.md ] || note ".capybara/setup.md missing"

# 2. registries have a 'next:' counter
for idx in docs/po/features/index.md docs/qa/bugs/index.md docs/tech-lead/adr/index.md; do
  [ -f "$idx" ] && ! grep -q '^next:' "$idx" && note "$idx missing 'next:' counter"
done

# 3. each FR referenced needs a changelog entry
if [ -d docs/po/features ]; then
  for fr in docs/po/features/FR-*.md; do
    [ -e "$fr" ] || continue
    id="$(basename "$fr" .md)"
    grep -rq "$id" docs/po/changelog.md || note "$id has no changelog entry"
  done
fi

# 4. R5 source paths in staged diff need a security review note
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  changed="$(git diff --cached --name-only 2>/dev/null || true)"
  if echo "$changed" | grep -Eiq 'auth|token|login|secret|\.env'; then
    ls docs/security/reviews/SEC-REVIEW-*.md >/dev/null 2>&1 || \
      note "security-sensitive files changed but no docs/security/reviews/ note found"
  fi
fi

[ "$fail" -eq 0 ] && echo "capybara validate: OK"
exit "$fail"
