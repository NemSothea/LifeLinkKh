#!/usr/bin/env python3
"""Dev-only: mint a portal session JWT without building a Maven classpath first.

Same output as scripts/mint-portal-jwt.java — an HS256 token in JwtService.issue()'s
shape, one hour long. That file stays the reference implementation (it signs with the
same library the server verifies with); this one exists because minting a token is
something you do before every demo and every portal test, and

    ./mvnw -q dependency:build-classpath && java -cp ... MintPortalJwt

is a Maven resolve and a JVM start for sixty bytes of base64. Standard library only.

Usage:
    python3 scripts/mint-portal-jwt.py HOSPITAL          # seeded hospital staff account
    python3 scripts/mint-portal-jwt.py ADMIN             # seeded admin account
    python3 scripts/mint-portal-jwt.py DONOR <user-uuid> # any account, by id

With no user id it asks the running database for the seeded account of that role, which
is why the container has to be up.

NOT for the portal any more. Since 2026-09-06 staff sign in at /<locale>/sign-in with a
username and password (docs/demo-runbook.md section 4) and PORTAL_DEV_JWT no longer
exists. What is left for this script is poking the API directly with curl — a DONOR or
REQUESTER token to exercise the mobile endpoints without running the app, or a staff
token to check a role boundary without clicking through the UI.

Never use this against anything but a local stack: it signs with JWT_SECRET out of .env,
and a token minted here is indistinguishable from one the server issued.
"""

import base64
import hashlib
import hmac
import json
import pathlib
import subprocess
import sys
import time

ROLES = ("DONOR", "REQUESTER", "HOSPITAL", "ADMIN")
LIFETIME_SECONDS = 3600  # matches JwtService — expiry is not negotiable per environment
REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent


def read_secret() -> str:
    env = REPO_ROOT / ".env"
    if not env.is_file():
        sys.exit("❌ .env missing. Copy .env.example to .env and fill it in.")
    for line in env.read_text(encoding="utf-8").splitlines():
        if line.startswith("JWT_SECRET="):
            # split on the FIRST '=' only: JWT_SECRET is base64 and ends in '=', and
            # dropping that pads the key differently from the server's, producing a
            # token that verifies nowhere and 401s as INVALID_TOKEN.
            return line.split("=", 1)[1].strip()
    sys.exit("❌ JWT_SECRET is not set in .env.")


def seeded_user_id(role: str) -> str:
    query = f"SELECT id FROM users WHERE role = '{role}' ORDER BY created_at LIMIT 1;"
    try:
        result = subprocess.run(
            ["docker", "exec", "-i", "lifelinkkh-postgres-1",
             "psql", "-U", "lifelink", "-d", "lifelink", "-tAc", query],
            capture_output=True, text=True, timeout=20, check=True,
        )
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, FileNotFoundError):
        sys.exit(f"❌ Could not reach the database. Is the stack up? (bash scripts/dev-up.sh)")
    user_id = result.stdout.strip()
    if not user_id:
        sys.exit(f"❌ No {role} account exists yet. See docs/demo-runbook.md section 5.")
    return user_id


def b64(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def main() -> None:
    if len(sys.argv) < 2 or sys.argv[1].upper() not in ROLES:
        sys.exit(f"usage: {sys.argv[0]} <{'|'.join(ROLES)}> [user-uuid]")

    role = sys.argv[1].upper()
    user_id = sys.argv[2] if len(sys.argv) > 2 else seeded_user_id(role)
    issued_at = int(time.time())

    header = b64(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
    payload = b64(json.dumps(
        {"sub": user_id, "role": role, "iat": issued_at, "exp": issued_at + LIFETIME_SECONDS},
        separators=(",", ":"),
    ).encode())
    signature = b64(hmac.new(
        read_secret().encode(), f"{header}.{payload}".encode(), hashlib.sha256
    ).digest())

    print(f"{header}.{payload}.{signature}")
    print(f"# {role} {user_id} — expires in {LIFETIME_SECONDS // 60} minutes", file=sys.stderr)


if __name__ == "__main__":
    main()
