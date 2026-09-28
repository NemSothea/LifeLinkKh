#!/usr/bin/env bash
# Run every client's checks in one command. Exit non-zero if any client fails.
# Owner: Tech Lead. Referenced by .github/workflows/ci.yml so local and CI agree.
set -uo pipefail
cd "$(dirname "$0")/.."

# The Firebase emulators need Java 21+. Pinned here when a 21 install can be located, so a
# machine whose default JDK is something else still runs them the same way CI does.
if [ -z "${JAVA_HOME:-}" ]; then
    for candidate in \
        /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home \
        "$(/usr/libexec/java_home -v 21 2>/dev/null || true)"; do
        if [ -n "$candidate" ] && [ -x "$candidate/bin/java" ]; then
            export JAVA_HOME="$candidate"
            break
        fi
    done
fi

failed=()

run_step() {
    local name="$1"
    shift
    echo "── $name ─────────────────────────────────────────"
    if "$@"; then
        echo "✅ $name"
    else
        echo "❌ $name"
        failed+=("$name")
    fi
}

# Firebase (ADR 0009): the Security Rules and the Functions, each against the emulator. The
# emulator is a Java program, which is why JAVA_HOME is still pinned above.
run_step "firestore rules" bash -c 'cd firebase && npm run test:rules'
run_step "functions unit" bash -c 'cd firebase/functions && npm test'
run_step "functions emulator" bash -c 'cd firebase/functions && npm run test:emulator'

if [ -f frontend/package.json ]; then
    run_step "web lint" bash -c 'cd frontend && npm run lint'
    run_step "web types" bash -c 'cd frontend && npx tsc --noEmit'
    run_step "web test" bash -c 'cd frontend && npm test -- --run'
else
    echo "⏭  web — not scaffolded"
fi

# mobile
if [ -f mobile/pubspec.yaml ]; then
    run_step "flutter analyze" bash -c 'cd mobile && flutter analyze'
    run_step "flutter test" bash -c 'cd mobile && flutter test'
else
    echo "⏭  mobile — not scaffolded"
fi

echo
if [ ${#failed[@]} -eq 0 ]; then
    echo "All checks passed. Note: a SKIPPED test is not a pass — check the report."
    exit 0
fi
echo "FAILED: ${failed[*]}"
exit 1
