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
    mrp: LabelFieldConfig;
    packedDate: LabelFieldConfig;
    expiryDate: LabelFieldConfig;
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
  /** Maximum retail price (typically the product's original/strike-through price). */
  mrp?: number | string;
  /** Packed/manufacture date. Accepts ISO (yyyy-mm-dd), Date, or display string. */
  packedDate?: string;
  /** Expiry/best-before date. Accepts ISO (yyyy-mm-dd), Date, or display string. */
  expiryDate?: string;
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
      shopName: { show: false, fontSize: 6, bold: false },
      mrp: { show: false, fontSize: 7, bold: false, prefix: 'MRP ₹' },
      packedDate: { show: false, fontSize: 6, bold: false, prefix: 'Pkd: ' },
      expiryDate: { show: false, fontSize: 6, bold: false, prefix: 'Exp: ' }
    }
  };
}

/**
 * Merge a parsed/partial design over the defaults, deep-merging `fields` per key
 * so templates saved before new fields existed still get full field configs
 * (a shallow spread would drop the new keys and crash the designer).
 */
export function mergeLabelDesign(parsed: Partial<LabelDesign> | null | undefined): LabelDesign {
  const base = defaultLabelDesign();
  if (!parsed) {
    return base;
  }
  const merged: LabelDesign = { ...base, ...parsed, fields: { ...base.fields } };
  const parsedFields = (parsed.fields || {}) as Partial<LabelDesign['fields']>;
  (Object.keys(base.fields) as (keyof LabelDesign['fields'])[]).forEach((key) => {
    merged.fields[key] = { ...base.fields[key], ...(parsedFields[key] || {}) };
  });
  return merged;
}

export function defaultLabelTemplate(): LabelTemplate {
  return {
    name: 'Default Label',
    labelWidthMm: 50,
    labelHeightMm: 25,
    isDefault: true,
    design: JSON.stringify(defaultLabelDesign())
  };
}
