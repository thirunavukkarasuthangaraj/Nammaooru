import { Injectable } from '@angular/core';
import * as QRCode from 'qrcode';
import JsBarcode from 'jsbarcode';
import {
  LabelDesign,
  LabelProductData,
  LabelTemplate,
  defaultLabelDesign,
  mergeLabelDesign
} from '../models/label-template.model';

/**
 * Renders product data into a saved label template and sends it to the printer.
 * Each label is sized exactly to the template's mm dimensions via an @page rule
 * so output matches physical label stock (e.g. 50 x 20 mm).
 */
@Injectable({ providedIn: 'root' })
export class LabelPrintService {

  /** Build a barcode/QR image data-URL for the given value. */
  private async barcodeDataUrl(value: string, design: LabelDesign): Promise<string> {
    if (!value || design.barcodeType === 'NONE') {
      return '';
    }
    if (design.barcodeType === 'QR') {
      return QRCode.toDataURL(value, { margin: 0, scale: 6 } as any);
    }
    // CODE128 linear barcode
    const canvas = document.createElement('canvas');
    JsBarcode(canvas, value, {
      format: 'CODE128',
      displayValue: design.showBarcodeText,
      height: 60,
      margin: 0,
      fontSize: 14
    });
    return canvas.toDataURL('image/png');
  }

  private parseDesign(template: LabelTemplate): LabelDesign {
    if (!template.design) {
      return defaultLabelDesign();
    }
    try {
      return mergeLabelDesign(JSON.parse(template.design));
    } catch {
      return defaultLabelDesign();
    }
  }

  /** Format a date value as DD/MM/YYYY; passes through non-date display strings. */
  private formatDate(value?: string): string {
    if (!value) {
      return '';
    }
    const str = String(value).trim();
    // ISO yyyy-mm-dd (optionally with time) -> DD/MM/YYYY
    const iso = str.match(/^(\d{4})-(\d{2})-(\d{2})/);
    if (iso) {
      return `${iso[3]}/${iso[2]}/${iso[1]}`;
    }
    return str;
  }

  /** Render the inner HTML for a single label (without page wrapper). */
  async renderLabelInner(template: LabelTemplate, product: LabelProductData): Promise<string> {
    const design = this.parseDesign(template);
    const f = design.fields;
    const horizontal = (design.layout || 'horizontal') === 'horizontal';

    // Text lines (name / price / shop / sku) grouped together
    const textRows: string[] = [];
    if (f.shopName?.show && product.shopName) {
      textRows.push(this.line(product.shopName, f.shopName));
    }
    if (f.tamilName?.show && product.tamilName) {
      textRows.push(this.line(product.tamilName, f.tamilName));
    }
    if (f.name?.show && product.name) {
      textRows.push(this.line(product.name, f.name));
    }
    // Net qty, price and MRP share one row; pack date and expiry date share one row.
    const hasNetQty = !!(f.netQty?.show && product.netQty);
    const hasPrice = f.price?.show && product.price !== undefined && product.price !== null && product.price !== '';
    const hasMrp = f.mrp?.show && product.mrp !== undefined && product.mrp !== null && product.mrp !== '';
    const priceMrpSpans: string[] = [];
    if (hasNetQty) {
      priceMrpSpans.push(this.span(`${f.netQty.prefix || ''}${product.netQty}`, f.netQty));
    }
    if (hasPrice) {
      priceMrpSpans.push(this.span(`${f.price.prefix || ''}${product.price}`, f.price));
    }
    if (hasMrp) {
      priceMrpSpans.push(this.span(`${f.mrp.prefix || ''}${product.mrp}`, f.mrp));
    }
    if (priceMrpSpans.length) {
      // Combined row: use the primary present field's gap (net qty, else price, else MRP).
      const gapMm = hasNetQty ? this.gap(f.netQty) : (hasPrice ? this.gap(f.price) : this.gap(f.mrp));
      textRows.push(this.row(priceMrpSpans, gapMm));
    }

    const dateSpans: string[] = [];
    if (f.packedDate?.show && product.packedDate) {
      dateSpans.push(this.span(`${f.packedDate.prefix || ''}${this.formatDate(product.packedDate)}`, f.packedDate));
    }
    if (f.expiryDate?.show && product.expiryDate) {
      dateSpans.push(this.span(`${f.expiryDate.prefix || ''}${this.formatDate(product.expiryDate)}`, f.expiryDate));
    }
    if (dateSpans.length) {
      // Combined row: use the primary present field's gap (pack date, else expiry).
      const gapMm = (f.packedDate?.show && product.packedDate) ? this.gap(f.packedDate) : this.gap(f.expiryDate);
      textRows.push(this.row(dateSpans, gapMm));
    }

    if (f.sku?.show && product.sku) {
      textRows.push(this.line(product.sku, f.sku));
    }

    // Barcode block
    let barcodeHtml = '';
    const barcodeValue = product.barcode || product.sku || '';
    if (design.barcodeType !== 'NONE' && barcodeValue) {
      const dataUrl = await this.barcodeDataUrl(barcodeValue, design);
      if (dataUrl) {
        // Width is optional: 0/missing keeps the old behavior (auto width from
        // height, aspect preserved). An explicit width stretches the code to
        // exactly width x height (fill), so what you set is what prints.
        const widthMm = Number(design.barcodeWidthMm) || 0;
        const sizeCss = widthMm > 0
          ? `width:${widthMm}mm;height:${design.barcodeHeightMm}mm;object-fit:fill;`
          : `height:${design.barcodeHeightMm}mm;object-fit:contain;`;
        barcodeHtml =
          `<img class="barcode" src="${dataUrl}" style="${sizeCss}max-width:100%;max-height:100%;" />`;
      }
    }

    const textBlock = textRows.length
      ? `<div class="info" style="display:flex;flex-direction:column;justify-content:center;${horizontal ? 'min-width:0;flex:1 1 auto;' : ''}">${textRows.join('')}</div>`
      : '';
    const codeBlock = barcodeHtml
      ? `<div class="code" style="display:flex;align-items:center;justify-content:center;${horizontal ? 'flex:0 0 auto;margin-left:1mm;' : ''}">${barcodeHtml}</div>`
      : '';

    // Horizontal: text beside barcode (row). Vertical: stacked (column).
    // The .label container's flex-direction (set in buildHtml) arranges these.
    return `${textBlock}${codeBlock}`;
  }

  /** Bottom spacing for a field/row, in mm. Negative values pull the next row up. Defaults to 0. */
  private gap(cfg?: { gapMm?: number }): number {
    const g = cfg?.gapMm;
    return (typeof g === 'number' && Number.isFinite(g)) ? g : 0;
  }

  private line(text: string, cfg: { fontSize: number; bold: boolean; gapMm?: number }, strike = false): string {
    const decoration = strike ? 'text-decoration:line-through;' : '';
    return `<div style="font-size:${cfg.fontSize}pt;font-weight:${cfg.bold ? 700 : 400};line-height:1.05;margin-bottom:${this.gap(cfg)}mm;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:100%;${decoration}">${this.escape(text)}</div>`;
  }

  /** An inline text item (used to place two fields side by side on one row). */
  private span(text: string, cfg: { fontSize: number; bold: boolean; prefix?: string }, strike = false): string {
    const decoration = strike ? 'text-decoration:line-through;' : '';
    return `<span style="font-size:${cfg.fontSize}pt;font-weight:${cfg.bold ? 700 : 400};${decoration}">${this.escape(text)}</span>`;
  }

  /** A single row holding one or more inline spans, spaced apart and centered by the parent's text-align. */
  private row(spans: string[], gapMm = 0): string {
    const sep = '<span style="display:inline-block;width:2.5mm;"></span>';
    return `<div style="line-height:1.05;margin-bottom:${gapMm}mm;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:100%;">${spans.join(sep)}</div>`;
  }

  private escape(s: string): string {
    return String(s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  }

  /** Build a full printable HTML document for one or more product labels. */
  async buildHtml(template: LabelTemplate, products: LabelProductData[]): Promise<string> {
    const design = this.parseDesign(template);
    const w = template.labelWidthMm;
    const h = template.labelHeightMm;
    const pad = design.paddingMm;
    const align = design.align || 'center';
    const horizontal = (design.layout || 'horizontal') === 'horizontal';

    const labels = await Promise.all(
      products.map(async p => `<div class="label"><div class="fit">${await this.renderLabelInner(template, p)}</div></div>`)
    );

    return `<!doctype html><html><head><meta charset="utf-8"><title>Label</title>
<style>
  @page { size: ${w}mm ${h}mm; margin: 0; }
  * { box-sizing: border-box; }
  /* Stop Chrome's text-autosizing from inflating the fonts in this bare print
     window (the app itself is reset, this popup is not). */
  html, body { -webkit-text-size-adjust: 100%; text-size-adjust: 100%; }
  html, body { margin: 0; padding: 0; }
  body { font-family: Arial, "Noto Sans Tamil", sans-serif; }
  /* .label is the fixed physical box (clips); .fit holds the content and is
     scaled down to fit so nothing is ever clipped and print matches preview. */
  .label {
    width: ${w}mm; height: ${h}mm; padding: ${pad}mm;
    display: flex; align-items: center; justify-content: center;
    overflow: hidden; page-break-after: always;
  }
  .label:last-child { page-break-after: auto; }
  .fit {
    display: flex;
    flex-direction: ${horizontal ? 'row' : 'column'};
    align-items: center;
    justify-content: ${horizontal ? 'space-between' : 'center'};
    text-align: ${align};
    transform-origin: center center;
  }
  .barcode { display: block; }
</style></head>
<body>
${labels.join('\n')}
<script>
  function fitLabels() {
    var labels = document.querySelectorAll('.label');
    for (var i = 0; i < labels.length; i++) {
      var label = labels[i];
      var fit = label.querySelector('.fit');
      if (!fit) continue;
      fit.style.transform = '';
      var cs = getComputedStyle(label);
      var availW = label.clientWidth - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight);
      var availH = label.clientHeight - parseFloat(cs.paddingTop) - parseFloat(cs.paddingBottom);
      var cw = fit.offsetWidth, ch = fit.offsetHeight;
      if (cw > 0 && ch > 0) {
        var s = Math.min(1, availW / cw, availH / ch);
        if (s < 1) { fit.style.transform = 'scale(' + s + ')'; }
      }
    }
  }
  window.addEventListener('load', function () {
    fitLabels();
    window.focus();
    window.print();
  });
</script>
</body></html>`;
  }

  /** Open a print window for the given products using the template. */
  async print(template: LabelTemplate, products: LabelProductData[]): Promise<void> {
    const html = await this.buildHtml(template, products);
    const win = window.open('', '_blank', 'width=420,height=320');
    if (!win) {
      throw new Error('Popup blocked. Please allow popups to print labels.');
    }
    win.document.open();
    win.document.write(html);
    win.document.close();
  }
}
