'use client';

import { useRef } from 'react';
import { ImageDown } from 'lucide-react';

const STYLE_PROPS = [
    'fill',
    'stroke',
    'stroke-width',
    'opacity',
    'font-size',
    'font-weight',
    'font-family',
];

type LegendItem = { label: string; color: string; value?: string };

/**
 * Downloads the chart in this card as a PNG: the card's title, the chart, and its legend, on the
 * card's own background. The chart SVG is cloned with every colour resolved (CSS variables mean
 * nothing once the SVG leaves the page), drawn to a 2× canvas, and saved.
 */
export default function ExportImageButton({
    title,
    fileName,
    label,
    legend = [],
}: {
    title: string;
    fileName: string;
    label: string;
    legend?: LegendItem[];
}) {
    const ref = useRef<HTMLButtonElement>(null);

    async function download() {
        const card = ref.current?.closest('[data-chart-card]');
        const svg = card?.querySelector<SVGSVGElement>('svg[data-chart]');
        if (!card || !svg) return;
        const css = getComputedStyle(card);
        const resolve = (color: string) => {
            const probe = document.createElement('span');
            probe.style.color = color;
            card.appendChild(probe);
            const out = getComputedStyle(probe).color;
            probe.remove();
            return out;
        };

        // Clone, and copy the computed presentation of each element onto the clone.
        const clone = svg.cloneNode(true) as SVGSVGElement;
        const src = svg.querySelectorAll('*');
        const dst = clone.querySelectorAll('*');
        src.forEach((el, i) => {
            const cs = getComputedStyle(el);
            const target = dst[i] as SVGElement;
            STYLE_PROPS.forEach((p) => target.style.setProperty(p, cs.getPropertyValue(p)));
            target.style.setProperty('animation', 'none');
            target.style.setProperty('transform', cs.transform === 'none' ? '' : cs.transform);
        });
        const w = svg.width.baseVal.value || svg.getBoundingClientRect().width;
        const h = svg.height.baseVal.value || svg.getBoundingClientRect().height;
        clone.setAttribute('width', String(w));
        clone.setAttribute('height', String(h));
        clone.setAttribute('xmlns', 'http://www.w3.org/2000/svg');

        const pad = 24;
        const titleH = 36;
        const legendW = legend.length ? 260 : 0;
        const legendH = legend.length * 24;
        const width = pad * 2 + w + (legendW ? pad + legendW : 0);
        const height = pad * 2 + titleH + Math.max(h, legendH);
        const scale = 2;
        const canvas = document.createElement('canvas');
        canvas.width = width * scale;
        canvas.height = height * scale;
        const ctx = canvas.getContext('2d');
        if (!ctx) return;
        ctx.scale(scale, scale);
        ctx.fillStyle = css.backgroundColor;
        ctx.fillRect(0, 0, width, height);
        const font = getComputedStyle(document.body).fontFamily;
        ctx.fillStyle = css.color;
        ctx.font = `600 16px ${font}`;
        ctx.fillText(title, pad, pad + 16);

        const image = new Image();
        const blob = new Blob([new XMLSerializer().serializeToString(clone)], {
            type: 'image/svg+xml',
        });
        const url = URL.createObjectURL(blob);
        await new Promise<void>((resolveLoad, reject) => {
            image.onload = () => resolveLoad();
            image.onerror = reject;
            image.src = url;
        });
        ctx.drawImage(image, pad, pad + titleH, w, h);
        URL.revokeObjectURL(url);

        const lx = pad + w + pad;
        legend.forEach((item, i) => {
            const y = pad + titleH + 8 + i * 24;
            ctx.fillStyle = resolve(item.color);
            ctx.fillRect(lx, y - 10, 12, 12);
            ctx.fillStyle = css.color;
            ctx.font = `13px ${font}`;
            ctx.fillText(item.label, lx + 20, y);
            if (item.value) {
                ctx.textAlign = 'right';
                ctx.fillText(item.value, lx + legendW, y);
                ctx.textAlign = 'left';
            }
        });

        canvas.toBlob((png) => {
            if (!png) return;
            const a = document.createElement('a');
            a.href = URL.createObjectURL(png);
            a.download = `${fileName}.png`;
            a.click();
            setTimeout(() => URL.revokeObjectURL(a.href), 1000);
        }, 'image/png');
    }

    return (
        <button
            ref={ref}
            type="button"
            onClick={download}
            aria-label={`${label}: ${title}`}
            title={label}
            data-testid={`export-image-${fileName}`}
            className="flex size-11 shrink-0 items-center justify-center rounded-full text-muted-foreground transition-colors hover:bg-secondary hover:text-foreground focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-none"
        >
            <ImageDown className="size-5" aria-hidden="true" />
        </button>
    );
}
