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
    if (f.name?.show && product.name) {
      textRows.push(this.line(product.name, f.name));
    }
    if (f.price?.show && (product.price !== undefined && product.price !== null && product.price !== '')) {
      textRows.push(this.line(`${f.price.prefix || ''}${product.price}`, f.price));
    }
    if (f.mrp?.show && (product.mrp !== undefined && product.mrp !== null && product.mrp !== '')) {
      // Strike through the MRP only when an actual lower selling price exists;
      // otherwise show the MRP on its own.
      const mrpNum = Number(product.mrp);
      const priceNum = Number(product.price);
      const strike = Number.isFinite(mrpNum) && Number.isFinite(priceNum)
        && product.price !== '' && product.price !== undefined && product.price !== null
        && priceNum < mrpNum;
      textRows.push(this.line(`${f.mrp.prefix || ''}${product.mrp}`, f.mrp, strike));
    }
    if (f.packedDate?.show && product.packedDate) {
      textRows.push(this.line(`${f.packedDate.prefix || ''}${this.formatDate(product.packedDate)}`, f.packedDate));
    }
    if (f.expiryDate?.show && product.expiryDate) {
      textRows.push(this.line(`${f.expiryDate.prefix || ''}${this.formatDate(product.expiryDate)}`, f.expiryDate));
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
        barcodeHtml =
          `<img class="barcode" src="${dataUrl}" style="height:${design.barcodeHeightMm}mm;max-width:100%;max-height:100%;object-fit:contain;" />`;
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

  private line(text: string, cfg: { fontSize: number; bold: boolean }, strike = false): string {
    const decoration = strike ? 'text-decoration:line-through;' : '';
    return `<div style="font-size:${cfg.fontSize}pt;font-weight:${cfg.bold ? 700 : 400};line-height:1.15;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:100%;${decoration}">${this.escape(text)}</div>`;
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
      products.map(async p => `<div class="label">${await this.renderLabelInner(template, p)}</div>`)
    );

    return `<!doctype html><html><head><meta charset="utf-8"><title>Label</title>
<style>
  @page { size: ${w}mm ${h}mm; margin: 0; }
  * { box-sizing: border-box; }
  html, body { margin: 0; padding: 0; }
  body { font-family: Arial, "Noto Sans Tamil", sans-serif; }
  .label {
    width: ${w}mm; height: ${h}mm; padding: ${pad}mm;
    display: flex;
    flex-direction: ${horizontal ? 'row' : 'column'};
    align-items: center;
    justify-content: ${horizontal ? 'space-between' : 'center'};
    text-align: ${align};
    overflow: hidden; page-break-after: always;
  }
  .label:last-child { page-break-after: auto; }
  .barcode { display: block; }
</style></head>
<body onload="window.focus(); window.print();">
${labels.join('\n')}
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
