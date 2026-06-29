/**
 * Barcode label template — physical size plus a design describing which product
 * fields are printed and how. `design` is stored as a JSON string on the backend.
 */
export type BarcodeType = 'CODE128' | 'QR' | 'NONE';

export interface LabelFieldConfig {
  show: boolean;
  fontSize: number; // pt
  bold: boolean;
  prefix?: string;  // e.g. "₹" for price
}

export interface LabelDesign {
  barcodeType: BarcodeType;
  barcodeHeightMm: number;
  showBarcodeText: boolean;
  paddingMm: number;
  align: 'left' | 'center' | 'right';
  /** horizontal = text beside barcode (default), vertical = stacked. */
  layout: 'horizontal' | 'vertical';
  fields: {
    name: LabelFieldConfig;
    price: LabelFieldConfig;
    sku: LabelFieldConfig;
    shopName: LabelFieldConfig;
  };
}

export interface LabelTemplate {
  id?: number;
  name: string;
  shopId?: number | null;
  labelWidthMm: number;
  labelHeightMm: number;
  isDefault?: boolean;
  design?: string;        // JSON-encoded LabelDesign
  createdBy?: string;
  updatedBy?: string;
  createdAt?: string;
  updatedAt?: string;
}

/** Product data rendered onto a label. */
export interface LabelProductData {
  name: string;
  sku?: string;
  barcode?: string;
  price?: number | string;
  shopName?: string;
}

export function defaultLabelDesign(): LabelDesign {
  return {
    barcodeType: 'CODE128',
    barcodeHeightMm: 8,
    showBarcodeText: true,
    paddingMm: 1.5,
    align: 'center',
    layout: 'horizontal',
    fields: {
      name: { show: true, fontSize: 9, bold: true },
      price: { show: true, fontSize: 11, bold: true, prefix: '₹' },
      sku: { show: false, fontSize: 6, bold: false },
      shopName: { show: false, fontSize: 6, bold: false }
    }
  };
}

export function defaultLabelTemplate(): LabelTemplate {
  return {
    name: 'Default Label',
    labelWidthMm: 50,
    labelHeightMm: 20,
    isDefault: true,
    design: JSON.stringify(defaultLabelDesign())
  };
}
