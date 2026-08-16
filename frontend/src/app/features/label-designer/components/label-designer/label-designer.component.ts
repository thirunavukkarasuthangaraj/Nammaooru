import { Component, ElementRef, OnInit } from '@angular/core';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import { SwalService } from '../../../../core/services/swal.service';
import { LabelTemplateService } from '../../../../core/services/label-template.service';
import { LabelPrintService } from '../../../../core/services/label-print.service';
import {
  BarcodeType,
  LabelDesign,
  LabelProductData,
  LabelTemplate,
  defaultLabelDesign,
  mergeLabelDesign
} from '../../../../core/models/label-template.model';

@Component({
  selector: 'app-label-designer',
  templateUrl: './label-designer.component.html',
  styleUrls: ['./label-designer.component.scss']
})
export class LabelDesignerComponent implements OnInit {

  templateId?: number;
  templateName = 'Default Label';
  widthMm = 50;
  heightMm = 25;
  design: LabelDesign = defaultLabelDesign();

  fieldKeys: (keyof LabelDesign['fields'])[] =
    ['shopName', 'tamilName', 'name', 'netQty', 'price', 'mrp', 'packedDate', 'expiryDate', 'sku'];
  fieldLabels: Record<keyof LabelDesign['fields'], string> = {
    name: 'Product Name',
    tamilName: 'Tamil Name',
    price: 'Price',
    sku: 'SKU',
    shopName: 'Shop Name',
    netQty: 'Net Qty',
    mrp: 'MRP',
    packedDate: 'Pack Date',
    expiryDate: 'Expiry Date'
  };

  /** Fields whose prefix text is editable in the designer. */
  prefixFields: (keyof LabelDesign['fields'])[] = ['netQty', 'price', 'mrp', 'packedDate', 'expiryDate'];

  barcodeTypes: { value: BarcodeType; label: string }[] = [
    { value: 'CODE128', label: 'Barcode (CODE128)' },
    { value: 'QR', label: 'QR Code' },
    { value: 'NONE', label: 'No barcode' }
  ];

  // Sample product for live preview
  sample: LabelProductData = {
    name: 'Black Gram',
    tamilName: 'உளுத்தம் பருப்பு',
    sku: '8906006720077',
    barcode: '8906006720077',
    price: 95,
    mrp: 110,
    netQty: '250g',
    packedDate: LabelDesignerComponent.isoToday(0),
    expiryDate: LabelDesignerComponent.isoToday(30),
    // Use the real shop name so the preview matches the actual printed label
    shopName: localStorage.getItem('shop_name') || localStorage.getItem('current_shop_name') || 'Your Shop Name'
  };

  /** ISO yyyy-mm-dd for today + offsetDays (used for preview sample dates). */
  private static isoToday(offsetDays: number): string {
    const d = new Date();
    d.setDate(d.getDate() + offsetDays);
    return d.toISOString().slice(0, 10);
  }

  previewHtml: SafeHtml = '';
  isSaving = false;
  loading = true;

  constructor(
    private labelTemplateService: LabelTemplateService,
    private printService: LabelPrintService,
    private sanitizer: DomSanitizer,
    private swal: SwalService,
    private host: ElementRef<HTMLElement>
  ) {}

  ngOnInit(): void {
    this.labelTemplateService.getDefault().subscribe({
      next: (tpl) => {
        if (tpl) {
          this.applyTemplate(tpl);
        }
        this.loading = false;
        this.updatePreview();
      },
      error: () => {
        this.loading = false;
        this.updatePreview();
      }
    });
  }

  private applyTemplate(tpl: LabelTemplate): void {
    this.templateId = tpl.id;
    this.templateName = tpl.name || 'Default Label';
    this.widthMm = tpl.labelWidthMm || 50;
    this.heightMm = tpl.labelHeightMm || 25;
    if (tpl.design) {
      try {
        this.design = mergeLabelDesign(JSON.parse(tpl.design));
      } catch {
        this.design = defaultLabelDesign();
      }
    }
  }

  private buildTemplate(): LabelTemplate {
    return {
      id: this.templateId,
      name: this.templateName?.trim() || 'Default Label',
      labelWidthMm: Number(this.widthMm) || 50,
      labelHeightMm: Number(this.heightMm) || 25,
      isDefault: true,
      design: JSON.stringify(this.design)
    };
  }

  /** Re-render the live preview whenever a control changes. */
  async updatePreview(): Promise<void> {
    const tpl = this.buildTemplate();
    const inner = await this.printService.renderLabelInner(tpl, this.sample);
    const horizontal = (this.design.layout || 'horizontal') === 'horizontal';
    const w = tpl.labelWidthMm;
    const h = tpl.labelHeightMm;
    const pad = this.design.paddingMm;
    const align = this.design.align || 'center';
    // Mirror the print structure: a fixed .preview-label box that clips, holding
    // a .preview-fit content block that we scale down to fit (same as printing).
    const fit =
      `<div class="preview-fit" style="display:flex;flex-direction:${horizontal ? 'row' : 'column'};` +
      `align-items:center;justify-content:${horizontal ? 'space-between' : 'center'};` +
      `text-align:${align};transform-origin:center center;">${inner}</div>`;
    const wrapper =
      `<div class="preview-label" style="width:${w}mm;height:${h}mm;padding:${pad}mm;` +
      `display:flex;align-items:center;justify-content:center;overflow:hidden;` +
      `font-family:Arial,'Noto Sans Tamil',sans-serif;background:#fff;` +
      `border:1px solid #bbb;box-shadow:0 1px 4px rgba(0,0,0,0.15);">${fit}</div>`;
    this.previewHtml = this.sanitizer.bypassSecurityTrustHtml(wrapper);
    // Scale after the DOM updates so the preview matches the printed (scaled) label.
    // Run twice: immediately, then again after the barcode image has decoded.
    setTimeout(() => this.scalePreview(), 0);
    setTimeout(() => this.scalePreview(), 150);
  }

  /** Shrink the preview content to fit its label box, mirroring the print-time fit. */
  private scalePreview(): void {
    const el = this.host.nativeElement;
    const label = el.querySelector('.preview-label') as HTMLElement | null;
    const fit = el.querySelector('.preview-fit') as HTMLElement | null;
    if (!label || !fit) {
      return;
    }
    fit.style.transform = '';
    const cs = getComputedStyle(label);
    const availW = label.clientWidth - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight);
    const availH = label.clientHeight - parseFloat(cs.paddingTop) - parseFloat(cs.paddingBottom);
    const cw = fit.offsetWidth, ch = fit.offsetHeight;
    if (cw > 0 && ch > 0) {
      const s = Math.min(1, availW / cw, availH / ch);
      if (s < 1) {
        fit.style.transform = `scale(${s})`;
      }
    }
  }

  applyPreset(w: number, h: number): void {
    this.widthMm = w;
    this.heightMm = h;
    this.updatePreview();
  }

  save(): void {
    if (this.isSaving) {
      return;
    }
    this.isSaving = true;
    this.labelTemplateService.saveDefault(this.buildTemplate()).subscribe({
      next: (saved) => {
        this.templateId = saved.id;
        this.isSaving = false;
        this.swal.toast('Label template saved', 'success');
      },
      error: (err) => {
        this.isSaving = false;
        this.swal.toast(err?.error?.message || 'Failed to save template', 'error');
      }
    });
  }

  printTest(): void {
    this.printService.print(this.buildTemplate(), [this.sample])
      .catch((err) => this.swal.toast(err?.message || 'Print failed', 'error'));
  }
}
