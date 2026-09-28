/**
 * A minimal .xlsx writer — no dependency. An .xlsx is a zip of a few XML files; this writes them
 * with inline strings (no shared-string table) into an uncompressed ("stored") zip. Enough for the
 * dashboard's export: several sheets of text and numbers, a bold header row, frozen under it.
 */

export type Sheet = { name: string; rows: (string | number | null)[][] };

const encoder = new TextEncoder();

function xml(value: string): string {
    return (
        value
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            // Control characters are not allowed in XML 1.0.
            .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, '')
    );
}

function columnName(index: number): string {
    let n = index + 1;
    let name = '';
    while (n > 0) {
        const r = (n - 1) % 26;
        name = String.fromCharCode(65 + r) + name;
        n = Math.floor((n - 1) / 26);
    }
    return name;
}

/** Excel's sheet-name rules: at most 31 characters, none of []:*?/\, unique. */
function sheetNames(names: string[]): string[] {
    const used = new Set<string>();
    return names.map((raw, i) => {
        let name =
            raw
                .replace(/[[\]:*?/\\]/g, ' ')
                .trim()
                .slice(0, 31) || `Sheet${i + 1}`;
        let n = 2;
        while (used.has(name.toLowerCase())) name = `${name.slice(0, 28)} ${n++}`;
        used.add(name.toLowerCase());
        return name;
    });
}

function sheetXml(sheet: Sheet): string {
    const widths = sheet.rows.reduce<number[]>((w, row) => {
        row.forEach((cell, c) => {
            w[c] = Math.max(w[c] ?? 8, Math.min(60, String(cell ?? '').length + 2));
        });
        return w;
    }, []);
    const cols = widths.length
        ? `<cols>${widths.map((w, i) => `<col min="${i + 1}" max="${i + 1}" width="${w}" customWidth="1"/>`).join('')}</cols>`
        : '';
    const rows = sheet.rows
        .map((row, r) => {
            const cells = row
                .map((cell, c) => {
                    const ref = `${columnName(c)}${r + 1}`;
                    const style = r === 0 ? ' s="1"' : '';
                    if (cell == null || cell === '') return `<c r="${ref}"${style}/>`;
                    if (typeof cell === 'number' && Number.isFinite(cell)) {
                        return `<c r="${ref}"${style}><v>${cell}</v></c>`;
                    }
                    return `<c r="${ref}"${style} t="inlineStr"><is><t xml:space="preserve">${xml(String(cell))}</t></is></c>`;
                })
                .join('');
            return `<row r="${r + 1}">${cells}</row>`;
        })
        .join('');
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
        '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>' +
        cols +
        `<sheetData>${rows}</sheetData></worksheet>`
    );
}

// ── Stored (uncompressed) zip ──────────────────────────────────────────────────────────────────

const CRC_TABLE = (() => {
    const table = new Uint32Array(256);
    for (let n = 0; n < 256; n++) {
        let c = n;
        for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
        table[n] = c >>> 0;
    }
    return table;
})();

function crc32(data: Uint8Array): number {
    let crc = 0xffffffff;
    for (let i = 0; i < data.length; i++) crc = CRC_TABLE[(crc ^ data[i]) & 0xff] ^ (crc >>> 8);
    return (crc ^ 0xffffffff) >>> 0;
}

function zip(files: { name: string; data: Uint8Array }[]): Uint8Array {
    const parts: Uint8Array[] = [];
    const central: Uint8Array[] = [];
    let offset = 0;
    for (const file of files) {
        const name = encoder.encode(file.name);
        const crc = crc32(file.data);
        const local = new DataView(new ArrayBuffer(30));
        local.setUint32(0, 0x04034b50, true);
        local.setUint16(4, 20, true);
        local.setUint16(6, 0x0800, true); // UTF-8 names
        local.setUint16(8, 0, true); // stored
        local.setUint32(14, crc, true);
        local.setUint32(18, file.data.length, true);
        local.setUint32(22, file.data.length, true);
        local.setUint16(26, name.length, true);
        parts.push(new Uint8Array(local.buffer), name, file.data);

        const entry = new DataView(new ArrayBuffer(46));
        entry.setUint32(0, 0x02014b50, true);
        entry.setUint16(4, 20, true);
        entry.setUint16(6, 20, true);
        entry.setUint16(8, 0x0800, true);
        entry.setUint16(10, 0, true);
        entry.setUint32(16, crc, true);
        entry.setUint32(20, file.data.length, true);
        entry.setUint32(24, file.data.length, true);
        entry.setUint16(28, name.length, true);
        entry.setUint32(42, offset, true);
        central.push(new Uint8Array(entry.buffer), name);
        offset += 30 + name.length + file.data.length;
    }
    const centralSize = central.reduce((n, p) => n + p.length, 0);
    const end = new DataView(new ArrayBuffer(22));
    end.setUint32(0, 0x06054b50, true);
    end.setUint16(8, files.length, true);
    end.setUint16(10, files.length, true);
    end.setUint32(12, centralSize, true);
    end.setUint32(16, offset, true);
    const all = [...parts, ...central, new Uint8Array(end.buffer)];
    const out = new Uint8Array(all.reduce((n, p) => n + p.length, 0));
    let at = 0;
    for (const p of all) {
        out.set(p, at);
        at += p.length;
    }
    return out;
}

/** The workbook as .xlsx bytes. */
export function buildXlsx(sheets: Sheet[]): Uint8Array {
    const names = sheetNames(sheets.map((s) => s.name));
    const files: { name: string; data: string }[] = [
        {
            name: '[Content_Types].xml',
            data:
                '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
                '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
                '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
                '<Default Extension="xml" ContentType="application/xml"/>' +
                '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' +
                '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' +
                sheets
                    .map(
                        (_, i) =>
                            `<Override PartName="/xl/worksheets/sheet${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>`,
                    )
                    .join('') +
                '</Types>',
        },
        {
            name: '_rels/.rels',
            data:
                '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
                '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
                '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>' +
                '</Relationships>',
        },
        {
            name: 'xl/workbook.xml',
            data:
                '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
                '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>' +
                names
                    .map(
                        (n, i) => `<sheet name="${xml(n)}" sheetId="${i + 1}" r:id="rId${i + 1}"/>`,
                    )
                    .join('') +
                '</sheets></workbook>',
        },
        {
            name: 'xl/_rels/workbook.xml.rels',
            data:
                '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
                '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
                sheets
                    .map(
                        (_, i) =>
                            `<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>`,
                    )
                    .join('') +
                `<Relationship Id="rId${sheets.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>` +
                '</Relationships>',
        },
        {
            name: 'xl/styles.xml',
            data:
                '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
                '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
                '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>' +
                '<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>' +
                '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>' +
                '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>' +
                '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs>' +
                '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>' +
                '</styleSheet>',
        },
        ...sheets.map((s, i) => ({ name: `xl/worksheets/sheet${i + 1}.xml`, data: sheetXml(s) })),
    ];
    return zip(files.map((f) => ({ name: f.name, data: encoder.encode(f.data) })));
}
