import { describe, expect, it } from 'vitest';
import { buildXlsx } from './xlsx';

describe('buildXlsx', () => {
    it('writes a zip with one worksheet per sheet, escaped text and numbers', () => {
        const bytes = buildXlsx([
            { name: 'Summary', rows: [['Metric', 'Value'], ['Donors <new> & "old"', 40]] },
            { name: 'សំណើ/Requests', rows: [['Day', 'Count'], ['2026-09-28', 3]] },
        ]);
        expect(String.fromCharCode(bytes[0], bytes[1])).toBe('PK');
        const text = new TextDecoder().decode(bytes);
        expect(text).toContain('xl/worksheets/sheet2.xml');
        expect(text).toContain('Donors &lt;new&gt; &amp; &quot;old&quot;');
        expect(text).toContain('<v>40</v>');
        // "/" is not allowed in a sheet name.
        expect(text).toContain('name="សំណើ Requests"');
    });
});
