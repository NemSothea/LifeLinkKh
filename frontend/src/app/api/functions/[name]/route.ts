import { NextResponse } from 'next/server';
import { invoke } from '@/server/invoke';

/**
 * `POST /api/functions/{name}` — the app's way to the portal's functions (ADR 0010). Speaks the
 * callable protocol the Cloud Functions spoke, so the app's `cloud_functions` plugin needs only
 * a URL: `{"data": …}` in with the Firebase ID token as the bearer, `{"result": …}` out, and a
 * refusal as `{"error": {"status", "message", "details"}}` with the matching HTTP status.
 *
 * Node, not the Edge runtime: firebase-admin needs it. Never cached: every call is a write.
 * 30 s, not Vercel Hobby's 10 s default: a cold start plus an approval that matches and pushes
 * 25 donors is measured in low seconds, and the default would cut the slowest of those off.
 */
export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const maxDuration = 30;

/**
 * The largest call there is — a request with an 80-character contact name — is well under 1 KB.
 * 16 KB leaves room for every future field and refuses a body sent only to be parsed
 * (SEC-REVIEW-003 F-21).
 */
const MAX_BODY_BYTES = 16 * 1024;

/** Every answer names its charset (ASVS 4.1.1), not only the JSON default. */
function reply(body: unknown, status = 200) {
    return NextResponse.json(body, {
        status,
        headers: { 'content-type': 'application/json; charset=utf-8' },
    });
}

/**
 * GET is not a call, but it answers in the protocol's own shape instead of Next's HTML 405, so
 * whether a deployment carries this route can be checked from a browser: a JSON body with
 * `METHOD_NOT_ALLOWED` and the function's name means it does.
 */
export async function GET(_request: Request, { params }: { params: Promise<{ name: string }> }) {
    const { name } = await params;
    return reply(
        { error: { status: 'METHOD_NOT_ALLOWED', message: `POST to call ${name}.` } },
        405,
    );
}

// The other methods answer the same way instead of Next's bodiless 405.
export const PUT = GET;
export const PATCH = GET;
export const DELETE = GET;

export async function POST(request: Request, { params }: { params: Promise<{ name: string }> }) {
    const { name } = await params;
    const authorization = request.headers.get('authorization') ?? '';
    const token = authorization.startsWith('Bearer ') ? authorization.slice(7).trim() : null;

    // Content-Length first, so an honest oversized body is refused unread; the text length
    // after, for a chunked one that sent no length.
    const tooLarge = () =>
        reply({ error: { status: 'INVALID_ARGUMENT', message: 'Request body too large.' } }, 413);
    if (Number(request.headers.get('content-length') ?? 0) > MAX_BODY_BYTES) return tooLarge();

    let data: unknown;
    try {
        const text = await request.text();
        if (Buffer.byteLength(text) > MAX_BODY_BYTES) return tooLarge();
        const body = JSON.parse(text) as { data?: unknown } | null;
        data = body?.data;
    } catch {
        return reply({ error: { status: 'INVALID_ARGUMENT', message: 'Bad request body.' } }, 400);
    }

    const outcome = await invoke(name, data, token);
    if (outcome.ok) return reply({ result: outcome.result ?? null });
    return reply(outcome.error.toBody(), outcome.error.httpStatus);
}
