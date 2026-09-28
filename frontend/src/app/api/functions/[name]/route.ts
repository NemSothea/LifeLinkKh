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
 * GET is not a call, but it answers in the protocol's own shape instead of Next's HTML 405, so
 * whether a deployment carries this route can be checked from a browser: a JSON body with
 * `METHOD_NOT_ALLOWED` and the function's name means it does.
 */
export async function GET(_request: Request, { params }: { params: Promise<{ name: string }> }) {
    const { name } = await params;
    return NextResponse.json(
        { error: { status: 'METHOD_NOT_ALLOWED', message: `POST to call ${name}.` } },
        { status: 405 },
    );
}

export async function POST(request: Request, { params }: { params: Promise<{ name: string }> }) {
    const { name } = await params;
    const authorization = request.headers.get('authorization') ?? '';
    const token = authorization.startsWith('Bearer ') ? authorization.slice(7).trim() : null;

    let data: unknown;
    try {
        const body = (await request.json()) as { data?: unknown } | null;
        data = body?.data;
    } catch {
        return NextResponse.json(
            { error: { status: 'INVALID_ARGUMENT', message: 'Bad request body.' } },
            { status: 400 },
        );
    }

    const outcome = await invoke(name, data, token);
    if (outcome.ok) return NextResponse.json({ result: outcome.result ?? null });
    return NextResponse.json(outcome.error.toBody(), { status: outcome.error.httpStatus });
}
