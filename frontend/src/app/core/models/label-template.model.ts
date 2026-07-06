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
  gapMm?: number;   // vertical space below this field/row, in mm (0 = tight)
}

export interface LabelDesign {
  barcodeType: BarcodeType;
  /** Printed barcode/QR box width in mm. 0 (or missing) = auto from height. */
  barcodeWidthMm: number;
  barcodeHeightMm: number;
  showBarcodeText: boolean;
  paddingMm: number;
  align: 'left' | 'center' | 'right';
  /** horizontal = text beside barcode (default), vertical = stacked. */
  layout: 'horizontal' | 'vertical';
  fields: {
    name: LabelFieldConfig;
    tamilName: LabelFieldConfig;
    price: LabelFieldConfig;
    sku: LabelFieldConfig;
    shopName: LabelFieldConfig;
    netQty: LabelFieldConfig;
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
  /** Tamil product name, printed as its own line when enabled. */
  tamilName?: string;
  sku?: string;
  barcode?: string;
  price?: number | string;
  shopName?: string;
  /** Net quantity text, e.g. "250g" or "1kg". */
  netQty?: string;
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
    barcodeWidthMm: 0,
    barcodeHeightMm: 8,
    showBarcodeText: true,
    paddingMm: 1.5,
    align: 'center',
    // Vertical (text stacked above the barcode) matches the classic POS label.
    layout: 'vertical',
    fields: {
      shopName: { show: true, fontSize: 7, bold: true },
      tamilName: { show: true, fontSize: 6, bold: false },
      name: { show: true, fontSize: 6, bold: true },
      netQty: { show: true, fontSize: 6, bold: true, prefix: 'NET QTY: ' },
      price: { show: true, fontSize: 7, bold: true, prefix: '₹' },
      sku: { show: false, fontSize: 6, bold: false },
      mrp: { show: true, fontSize: 6, bold: false, prefix: 'MRP ₹' },
      packedDate: { show: true, fontSize: 5.5, bold: false, prefix: 'PKD: ' },
      expiryDate: { show: true, fontSize: 5.5, bold: false, prefix: 'EXP: ' }
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

/**
 * Return a copy of the template with the given fields forced visible.
 * Used when the user just typed a value (e.g. an expiry date) at print time:
 * it must print even if the saved template still hides that field.
 */
export function templateWithFieldsShown(
  tpl: LabelTemplate,
  keys: (keyof LabelDesign['fields'])[]
): LabelTemplate {
  if (!keys.length) {
    return tpl;
  }
  let design: LabelDesign;
  try {
    design = mergeLabelDesign(tpl.design ? JSON.parse(tpl.design) : null);
  } catch {
    design = mergeLabelDesign(null);
  }
  keys.forEach((k) => { design.fields[k].show = true; });
  return { ...tpl, design: JSON.stringify(design) };
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
