import { vi } from 'vitest';

/**
 * A `fetch` that answers Firestore `runQuery` calls from an in-memory table, keyed by
 * `parent/collection` ('requests', 'requests/r1/acceptedDonors'), and callable Functions from a
 * map of results. Every call is recorded so a test can assert what was asked, and as whom.
 */
type Row = { id: string; fields: Record<string, unknown> };

function encode(value: unknown): unknown {
    if (value === null || value === undefined) return { nullValue: null };
    if (typeof value === 'string') return { stringValue: value };
    if (typeof value === 'boolean') return { booleanValue: value };
    if (typeof value === 'number') return { integerValue: String(value) };
    if (typeof value === 'object') {
        return {
            mapValue: {
                fields: Object.fromEntries(Object.entries(value).map(([k, v]) => [k, encode(v)])),
            },
        };
    }
    throw new Error(`cannot encode ${String(value)}`);
}

type Filter = { fieldFilter: { field: { fieldPath: string }; value: Record<string, unknown> } };
// eslint-disable-next-line @typescript-eslint/no-explicit-any -- a test double's view of a JSON body
export type Call = { url: string; token: string | null; body: any };

export function fakeFirebase(
    tables: Record<string, Row[]>,
    functions: Record<string, { status?: number; body: unknown }> = {},
) {
    const calls: Call[] = [];
    const fetchMock = vi.fn(
        async (url: string, init: { headers: Record<string, string>; body?: string }) => {
            const body = init.body ? JSON.parse(init.body) : null;
            const token = init.headers.Authorization?.replace('Bearer ', '') ?? null;
            calls.push({ url, token, body });

            const fn = url.match(/cloudfunctions\.net\/(\w+)$/)?.[1];
            if (fn) {
                const answer = functions[fn] ?? {
                    status: 500,
                    body: { error: { status: 'INTERNAL' } },
                };
                const status = answer.status ?? 200;
                return { ok: status < 300, status, json: async () => answer.body };
            }

            const parent = url.match(/documents\/?(.*):runQuery$/)?.[1] ?? '';
            const collection = body.structuredQuery.from[0].collectionId;
            const key = parent ? `${parent}/${collection}` : collection;
            const where = body.structuredQuery.where;
            const filters = where?.compositeFilter?.filters ?? (where ? [where] : []);
            const rows = (tables[key] ?? []).filter((row) =>
                filters.every(
                    (f: Filter) =>
                        row.fields[f.fieldFilter.field.fieldPath] ===
                        Object.values(f.fieldFilter.value)[0],
                ),
            );
            return {
                ok: true,
                status: 200,
                json: async () =>
                    rows.map((row) => ({
                        document: {
                            name: `projects/lifelinkkh/databases/(default)/documents/${key}/${row.id}`,
                            fields: (encode(row.fields) as { mapValue: { fields: unknown } })
                                .mapValue.fields,
                        },
                    })),
            };
        },
    );
    vi.stubGlobal('fetch', fetchMock);
    return calls;
}

/** An unsigned JWT with these claims — what `session.ts` reads, unverified. */
export function fakeJwt(claims: Record<string, unknown>): string {
    return `header.${Buffer.from(JSON.stringify(claims)).toString('base64url')}.signature`;
}
