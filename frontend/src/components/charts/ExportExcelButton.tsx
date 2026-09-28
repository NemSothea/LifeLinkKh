'use client';

import { FileSpreadsheet } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { buildXlsx, type Sheet } from '@/lib/xlsx';

/** Builds the workbook in the browser from the numbers already on the page, and saves it. */
export default function ExportExcelButton({
    sheets,
    fileName,
    label,
}: {
    sheets: Sheet[];
    fileName: string;
    label: string;
}) {
    function download() {
        const bytes = buildXlsx(sheets);
        const blob = new Blob([bytes.slice().buffer], {
            type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        });
        const a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = `${fileName}.xlsx`;
        a.click();
        setTimeout(() => URL.revokeObjectURL(a.href), 1000);
    }
    return (
        <Button type="button" variant="outline" onClick={download} data-testid="export-excel">
            <FileSpreadsheet className="size-4" aria-hidden="true" />
            {label}
        </Button>
    );
}
