import { Injectable } from '@angular/core';

export interface ReceiptItem {
  name: string;
  nameTamil?: string;
  mrp: number;
  rate: number;
  quantity: number;
  total: number;
}

export interface ReceiptData {
  orderRef: string;
  items: ReceiptItem[];
  subtotal: number;
  totalMrp: number;
  totalDiscount: number;
  billDiscount: number;
  totalAmount: number;
  paymentLabel: string;
  customerName?: string;
  customerPhone?: string;
  qrCodeDataUrl?: string;
  shopNameFallback?: string;
  includePrintButton?: boolean;
}

export interface PaperConfig {
  pageSize: string;
  bodyWidth: string;
  maxWidth: string;
  windowWidth: number;
}

/**
 * Single source of truth for the printable receipt HTML.
 * Used by POS billing for the real print AND by the Bill Settings live
 * preview, so what the shop owner sees while choosing a template is
 * exactly what the printer produces.
 */
@Injectable({ providedIn: 'root' })
export class ReceiptTemplateService {

  getPaperConfig(paperWidth: string): PaperConfig {
    switch (paperWidth) {
      case '58mm':
        return { pageSize: '58mm auto', bodyWidth: '180px', maxWidth: '180px', windowWidth: 300 };
      case 'A4':
        return { pageSize: 'A4', bodyWidth: '100%', maxWidth: '600px', windowWidth: 700 };
      case '80mm':
      default:
        return { pageSize: '80mm auto', bodyWidth: '260px', maxWidth: '260px', windowWidth: 350 };
    }
  }

  private getSeparatorStyle(style: string): string {
    switch (style) {
      case 'solid': return 'border-top: 1px solid #000; margin: 4px 0;';
      case 'dotted': return 'border-top: 1px dotted #000; margin: 4px 0;';
      case 'none': return 'margin: 4px 0;';
      case 'dashed':
      default: return 'border-top: 1px dashed #000; margin: 4px 0;';
    }
  }

  /**
   * Escape HTML special characters so user-entered values (product names,
   * customer name/phone, shop settings, custom fields) can never inject
   * markup/script into the receipt - this HTML is passed to document.write()
   * or an iframe, not rendered through Angular's sanitizer.
   */
  private escapeHtml(value: any): string {
    if (value === null || value === undefined) return '';
    return String(value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  private getCustomFieldsHtml(bs: any, position: 'header' | 'footer', fontSize: number): string {
    const fields = (bs.customFields || [])
      .filter((f: any) => f.enabled && f.label && f.value && f.position === position);
    if (fields.length === 0) return '';
    return fields.map((f: any) => `
      <div style="font-size: ${fontSize}px; text-align: center; margin: 2px 0;">
        <span style="color: #000;">${this.escapeHtml(f.label)}:</span> <span style="font-weight: 600;">${this.escapeHtml(f.value)}</span>
      </div>
    `).join('');
  }

  generateReceiptHtml(bs: any, data: ReceiptData): string {
    const bodyFontSize = bs.bodyFontSize || 12;
    const headerFontSize = bs.headerFontSize || 16;
    const footerFontSize = bs.footerFontSize || 10;
    const paperConfig = this.getPaperConfig(bs.paperWidth || '80mm');
    const qrCodeDataUrl = data.qrCodeDataUrl || '';

    const items = data.items.map(item => {
      const englishName = this.escapeHtml(item.name || '');
      const tamilName = this.escapeHtml(item.nameTamil || '');
      const rate = item.rate || 0;
      const mrp = item.mrp || rate;
      const discount = Math.max(mrp - rate, 0);
      let nameHtml = '';
      if (bs.showEnglish && bs.showTamil && tamilName && tamilName.trim() !== englishName.trim()) {
        nameHtml = `${englishName}<br><span style="font-size: ${Math.max(bodyFontSize - 3, 8)}px; color: #000;">${tamilName}</span>`;
      } else if (bs.showEnglish) {
        nameHtml = englishName;
      } else if (bs.showTamil && tamilName) {
        nameHtml = tamilName;
      } else {
        nameHtml = englishName;
      }
      return `
      <tr>
        <td style="font-size: ${bodyFontSize}px; padding: 2px 0; font-weight: 600; word-wrap: break-word; max-width: 60px;">${nameHtml}</td>
        ${bs.showItemMrp ? `<td style="font-size: ${bodyFontSize}px; text-align: right; padding: 2px 0; font-weight: 600; white-space: nowrap;">${mrp}</td>` : ''}
        ${bs.showSellingPrice ? `<td style="font-size: ${bodyFontSize}px; text-align: right; padding: 2px 0; font-weight: 600; white-space: nowrap;">${rate}</td>` : ''}
        ${bs.showItemDiscount ? `<td style="font-size: ${bodyFontSize}px; text-align: right; padding: 2px 0; font-weight: 600; white-space: nowrap;">${discount}</td>` : ''}
        <td style="font-size: ${bodyFontSize}px; text-align: center; padding: 2px 0; font-weight: 700; white-space: nowrap;">${item.quantity}</td>
        <td style="font-size: ${bodyFontSize}px; text-align: right; padding: 2px 0; font-weight: 700; white-space: nowrap;">${item.total.toFixed(0)}</td>
      </tr>
    `;
    }).join('');

    const shopName = this.escapeHtml((bs.shopName && bs.shopName.trim()) || data.shopNameFallback || 'Shop');
    const shopPhone = this.escapeHtml(bs.shopPhone || '');
    const customerName = this.escapeHtml(data.customerName || '');
    const customerPhone = this.escapeHtml(data.customerPhone || '');
    const shopAddress = this.escapeHtml(bs.shopAddress || '');
    const gstNumber = this.escapeHtml(bs.gstNumber || '');
    const fssaiNumber = this.escapeHtml(bs.fssaiNumber || '');
    const fssaiName = this.escapeHtml(bs.fssaiName || '');
    const footerNote = this.escapeHtml(bs.footerNote || '');
    const thankYouMessage = this.escapeHtml(bs.thankYouMessage || '');
    const upiIdEscaped = this.escapeHtml(bs.upiId || '');

    const now = new Date();
    let formattedDate = '';
    switch (bs.dateFormat) {
      case 'MM/DD/YYYY':
        formattedDate = `${String(now.getMonth() + 1).padStart(2, '0')}/${String(now.getDate()).padStart(2, '0')}/${now.getFullYear()}`;
        break;
      case 'YYYY-MM-DD':
        formattedDate = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
        break;
      case 'DD/MM/YYYY':
      default:
        formattedDate = `${String(now.getDate()).padStart(2, '0')}/${String(now.getMonth() + 1).padStart(2, '0')}/${now.getFullYear()}`;
    }
    const formattedTime = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    const orderRef = this.escapeHtml(data.orderRef || '');
    const billNumber = bs.billNumberPrefix
      ? `${this.escapeHtml(bs.billNumberPrefix)}${orderRef}`
      : `#${orderRef}`;

    const separatorStyle = this.getSeparatorStyle(bs.separatorStyle || 'dashed');
    const dividerBorder = bs.separatorStyle === 'none' ? 'none' : `1px ${bs.separatorStyle || 'dashed'} #000`;
    const itemCount = data.items.length;
    const totalQty = data.items.reduce((sum, item) => sum + item.quantity, 0);
    const bodyPadding = bs.paperWidth === '58mm' ? '2mm' : bs.paperWidth === 'A4' ? '10mm' : '3mm';

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Receipt - ${orderRef}</title>
        <style>
          @page {
            size: ${paperConfig.pageSize};
            margin: 1mm;
          }
          @media print {
            html, body { width: 100%; overflow: hidden; }
            body {
              -webkit-print-color-adjust: exact;
              print-color-adjust: exact;
            }
            .no-print { display: none !important; }
          }
          body {
            box-sizing: border-box;
            background: #fff;
            font-family: 'Noto Sans Tamil', 'Latha', 'Tamil Sangam MN', Arial, sans-serif;
            font-size: ${bodyFontSize}px;
            width: ${paperConfig.bodyWidth};
            max-width: ${paperConfig.maxWidth};
            margin: 0 auto;
            padding: ${bodyPadding};
            line-height: 1.2;
            overflow-wrap: anywhere;
          }
          *, *::before, *::after { box-sizing: border-box; }
          .center { text-align: center; }
          .divider {
            ${separatorStyle}
          }
          .divider-solid {
            border-top: 1px solid #000;
            margin: 4px 0;
          }
          table { width: 100%; border-collapse: collapse; }
          .shop-name {
            font-family: 'Noto Sans Tamil', 'Latha', 'Tamil Sangam MN', Arial, sans-serif;
            font-size: ${headerFontSize}px;
            font-weight: 700;
            margin-bottom: 3px;
          }
          .shop-phone {
            font-size: ${Math.max(headerFontSize - 4, 10)}px;
            color: #000;
            font-weight: 700;
            margin-bottom: 2px;
          }
          .fssai-info {
            font-size: ${Math.max(footerFontSize, 8)}px;
            color: #000;
            margin-bottom: 2px;
          }
          .order-number {
            font-size: ${Math.max(bodyFontSize - 1, 9)}px;
            font-weight: 600;
            margin: 2px 0;
            overflow-wrap: anywhere;
          }
          .customer-name {
            font-size: ${bodyFontSize}px;
            font-weight: 700;
          }
          .customer-phone {
            font-size: ${Math.max(bodyFontSize - 2, 10)}px;
            color: #000;
          }
          .item-header th {
            font-size: ${Math.max(bodyFontSize - 3, 8)}px;
            padding: 3px 1px;
            border-bottom: ${dividerBorder};
            text-transform: uppercase;
            font-weight: 600;
          }
          .payment-badge {
            font-size: ${Math.max(bodyFontSize - 2, 10)}px;
            font-weight: 600;
            padding: 2px 0;
            display: inline-block;
            margin: 2px 0;
          }
          .footer-text {
            font-size: ${footerFontSize}px;
            color: #000;
            font-weight: 600;
            margin-top: 4px;
          }
          .flex-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
          }
          /* ============ Template styles (shared by print and live preview) ============ */

          /* Market Classic: light-green filled header + soft green total box.
             'current' (Current Print) has no overrides - it IS the base design. */
          body.template-classic .receipt-header {
            margin: -${bodyPadding} -${bodyPadding} 6px;
            padding: 8px 6px 7px;
            background: #43d77d !important;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
          }
          body.template-classic .receipt-header,
          body.template-classic .receipt-header div { color: #fff !important; }
          body.template-classic .grand-total-box { background: #e6f9ee !important; border-top: none !important; padding: 6px !important; }

          /* Clean Counter: airy sans-serif, faded light dividers, soft grey total (no hard boxes) */
          body.template-minimal {
            font-family: Arial, sans-serif;
            line-height: 1.4;
          }
          body.template-minimal .receipt-header { padding-bottom: 6px; border-bottom: 2px solid #159b5b; margin-bottom: 4px; }
          body.template-minimal .divider,
          body.template-minimal .divider-solid { opacity: 0.45; margin: 9px 0 !important; }
          body.template-minimal .item-header th { border-bottom-color: #999 !important; }
          body.template-minimal .grand-total-box { background: #f1f3f2 !important; border-top: none !important; padding: 6px !important; }

          /* NammaOoru Bold: green filled shop-name header banner + strong green totals */
          body.template-bold {
            font-family: Arial, sans-serif;
          }
          body.template-bold .receipt-header {
            margin: -${bodyPadding} -${bodyPadding} 6px;
            padding: 8px 6px 7px;
            background: #159b5b !important;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
          }
          body.template-bold .receipt-header,
          body.template-bold .receipt-header div { color: #fff !important; }
          body.template-bold .shop-name { letter-spacing: 0.02em; }
          body.template-bold .grand-total-value { color: #087443; }
          body.template-bold .grand-total-box { background: #d8f5e5 !important; border: 1px solid #8bd3aa; border-top: 1px solid #8bd3aa !important; }

          /* Compact Thermal: one step smaller fonts, tight spacing everywhere */
          body.template-compact { line-height: 1.08; font-size: ${Math.max(bodyFontSize - 1, 8)}px; }
          body.template-compact .receipt-header div { margin-bottom: 0 !important; }
          body.template-compact .shop-name { font-size: ${Math.max(headerFontSize - 3, 11)}px !important; margin-bottom: 1px; }
          body.template-compact .shop-phone { font-size: ${Math.max(headerFontSize - 6, 9)}px; }
          body.template-compact .divider, body.template-compact .divider-solid { margin: 3px 0 !important; }
          body.template-compact td { font-size: ${Math.max(bodyFontSize - 2, 8)}px !important; padding-top: 1px !important; padding-bottom: 1px !important; }
          body.template-compact .item-header th { font-size: ${Math.max(bodyFontSize - 4, 7)}px !important; padding: 1px !important; }
          body.template-compact .flex-row span { font-size: ${Math.max(bodyFontSize - 2, 8)}px !important; }
          body.template-compact .flex-row { padding-top: 1px !important; padding-bottom: 1px !important; }
          body.template-compact .grand-total-box { padding: 3px 4px !important; margin-top: 2px !important; }
          body.template-compact .grand-total-box span { font-size: ${Math.max(headerFontSize - 3, 11)}px !important; }
          body.template-compact .footer-text { margin-top: 3px; font-size: ${Math.max(footerFontSize - 1, 7)}px !important; }

          /* GST Professional: left-aligned header, Arial, solid rules, double-rule totals */
          body.template-invoice { font-family: Arial, sans-serif; border-top: 4px double #159b5b; padding-top: 4mm; }
          body.template-invoice .receipt-header { padding-bottom: 4px; border-bottom: 2px solid #159b5b; margin-bottom: 4px; }
          body.template-invoice .receipt-header .center,
          body.template-invoice .receipt-header div { text-align: left !important; }
          body.template-invoice .divider { border-top-style: solid !important; opacity: 0.7; }
          body.template-invoice .grand-total-box { background: #fff !important; border-top: 3px double #159b5b !important; border-bottom: 3px double #159b5b; padding: 5px 2px !important; }

          /* Border Receipt: outer green frame, dotted item rows, green filled TOTAL box */
          body.template-bordered { border: 2px solid #159b5b; font-family: Arial, sans-serif; }
          body.template-bordered .receipt-header { border: 1px solid #159b5b; padding: 5px 4px; margin-bottom: 5px; }
          body.template-bordered .shop-name { color: #087443; }
          body.template-bordered tbody td { border-bottom: 1px dotted #aaa; }
          body.template-bordered .grand-total-box {
            background: #159b5b !important;
            border-top: none !important;
            padding: 6px !important;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
          }
          body.template-bordered .grand-total-box span { color: #fff !important; }
        </style>
      </head>
      <body class="template-${bs.templateStyle || 'current'}">
        <div class="receipt-header">
          ${bs.showShopName ? `<div class="center shop-name">${shopName}</div>` : ''}
          ${bs.showShopAddress && shopAddress ? `<div class="center" style="font-size: ${Math.max(footerFontSize, 9)}px; color: #000; font-weight: 600;">${shopAddress}</div>` : ''}
          ${bs.showShopPhone && shopPhone ? `<div class="center shop-phone">Ph: ${shopPhone}</div>` : ''}
          ${bs.showGstNumber && gstNumber ? `<div class="center" style="font-size: ${Math.max(footerFontSize, 9)}px;">GST: ${gstNumber}</div>` : ''}
          ${bs.showFssaiInfo && fssaiNumber ? `
            <div class="center fssai-info">
              FSSAI: ${fssaiNumber}
              ${fssaiName ? `<br>${fssaiName}` : ''}
            </div>
          ` : ''}
        </div>
        ${this.getCustomFieldsHtml(bs, 'header', Math.max(footerFontSize, 9))}
        <div class="center" style="font-size: ${Math.max(footerFontSize, 9)}px; color: #000; font-weight: 600;">Order Receipt</div>
        <div class="divider"></div>

        ${bs.showBillNumber || bs.showDateTime ? `
        <div class="center order-number" style="margin-bottom: 4px;">
          ${[
            bs.showBillNumber ? billNumber : '',
            bs.showDateTime ? `${formattedDate} ${formattedTime}` : ''
          ].filter(Boolean).join(' | ')}
        </div>
        ` : ''}
        <div class="divider"></div>

        ${bs.showCustomerDetails && (customerName || customerPhone) ? `
        <div style="margin-bottom: 4px;">
          ${customerName ? `<div class="customer-name">${customerName}</div>` : ''}
          ${customerPhone ? `<div class="customer-phone">${customerPhone}</div>` : ''}
        </div>
        <div class="divider"></div>
        ` : ''}

        <table>
          <thead>
            <tr class="item-header">
              <th style="text-align: left;">ITEM</th>
              ${bs.showItemMrp ? '<th style="text-align: right;">MRP</th>' : ''}
              ${bs.showSellingPrice ? '<th style="text-align: right;">RATE</th>' : ''}
              ${bs.showItemDiscount ? '<th style="text-align: right;">DISC</th>' : ''}
              <th style="text-align: center;">QTY</th>
              <th style="text-align: right;">AMT</th>
            </tr>
          </thead>
          <tbody>
            ${items}
          </tbody>
        </table>
        <div class="divider"></div>

        ${bs.showSubtotal ? `<div class="flex-row" style="font-size: ${bodyFontSize}px; padding: 2px 0;">
          <span style="font-weight: 600;">Items: ${itemCount} (Qty: ${totalQty})</span>
          <span style="font-weight: 700;">₹${data.subtotal.toFixed(0)}</span>
        </div>` : ''}

        ${bs.showTotalSavings && data.totalDiscount > 0 ? `
        <div class="flex-row" style="font-size: ${bodyFontSize}px; padding: 2px 0;">
          <span style="font-weight: 600;">MRP Total</span>
          <span style="font-weight: 600;">₹${data.totalMrp.toFixed(0)}</span>
        </div>
        <div class="flex-row" style="font-size: ${bodyFontSize}px; padding: 2px 0;">
          <span style="font-weight: 600;">You Save</span>
          <span style="font-weight: 700;">₹${data.totalDiscount.toFixed(0)}</span>
        </div>
        ` : ''}

        ${bs.showTotalSavings && data.billDiscount > 0 ? `
        <div class="flex-row" style="font-size: ${bodyFontSize}px; padding: 2px 0;">
          <span style="font-weight: 600;">Subtotal</span>
          <span style="font-weight: 600;">₹${data.subtotal.toFixed(0)}</span>
        </div>
        <div class="flex-row" style="font-size: ${bodyFontSize}px; padding: 2px 0;">
          <span style="font-weight: 600;">Discount</span>
          <span style="font-weight: 700;">- ₹${data.billDiscount.toFixed(0)}</span>
        </div>
        ` : ''}

        <div class="flex-row grand-total-box" style="border-top: ${dividerBorder}; padding: 4px; margin-top: 2px;">
          <span style="font-size: ${headerFontSize}px; font-weight: 700;">TOTAL</span>
          <span class="grand-total-value" style="font-size: ${headerFontSize + 2}px; font-weight: 700;">₹${data.totalAmount.toFixed(0)}</span>
        </div>

        ${bs.showPaymentMethod ? `
        <div class="divider"></div>
        <div class="center">
          <span class="payment-badge">Paid by: ${this.escapeHtml(data.paymentLabel)}</span>
        </div>
        ` : ''}

        ${bs.showUpiQrCode && bs.upiId && qrCodeDataUrl ? `
        <div class="center" style="padding: 3px 0; page-break-inside: avoid;">
          <img src="${qrCodeDataUrl}"
               alt="UPI QR Code"
               style="display:block; width: ${bs.paperWidth === '58mm' ? '72px' : bs.paperWidth === 'A4' ? '108px' : '88px'}; height: ${bs.paperWidth === '58mm' ? '72px' : bs.paperWidth === 'A4' ? '108px' : '88px'}; margin: 2px auto;">
          <div style="font-size: ${Math.max(footerFontSize - 1, 7)}px; color: #000;">${upiIdEscaped}</div>
        </div>
        ` : ''}

        <div class="divider"></div>

        ${this.getCustomFieldsHtml(bs, 'footer', footerFontSize)}

        ${footerNote ? `
        <div class="center" style="font-size: ${footerFontSize}px; color: #000; font-weight: 600; margin: 4px 0;">
          ${footerNote}
        </div>
        ` : ''}

        ${bs.showThankYouMessage ? `
        <div class="center footer-text">
          ${thankYouMessage || 'Thank you for your order!'}<br>
          Printed: ${new Date().toLocaleString('en-IN')}
        </div>
        ` : ''}

        ${bs.showAppDownloadLink !== false ? `
        <div class="center" style="font-size: ${Math.max(footerFontSize - 1, 7)}px; margin-top: 4px;">
          <a href="https://play.google.com/store/apps/details?id=com.nammaooru.app&hl=en_IN" target="_blank" rel="noopener" style="color:#000;text-decoration:none;">📱 Download the Namma Ooru Connect App</a>
        </div>
        ` : ''}

        ${bs.showOrderDetailsLink !== false && data.orderRef ? `
        <div class="center" style="font-size: ${Math.max(footerFontSize - 1, 7)}px; margin-top: 2px;">
          <a href="https://nammaoorudelivary.in/customer/track-order/${encodeURIComponent(data.orderRef)}" target="_blank" rel="noopener" style="color:#000;text-decoration:none;">🔗 View Order Details</a>
        </div>
        ` : ''}

        <div class="center" style="font-size: ${Math.max(footerFontSize - 1, 7)}px; margin-top: 4px;">
          <a href="https://nammaoorudelivary.in" target="_blank" rel="noopener" style="color:#000;text-decoration:none;">Powered by Namma Ooru Connect</a>
        </div>

        ${data.includePrintButton ? `
        <!-- Print Button (hidden during print) -->
        <div class="no-print" style="margin-top: 15px; text-align: center;">
          <button onclick="window.onafterprint=function(){window.close()};window.print()" style="
            background: #4CAF50;
            color: white;
            border: none;
            padding: 12px 30px;
            font-size: 16px;
            font-weight: bold;
            border-radius: 5px;
            cursor: pointer;
            margin-right: 10px;
          ">&#128424;&#65039; PRINT</button>
          <button onclick="window.close()" style="
            background: #666;
            color: white;
            border: none;
            padding: 12px 20px;
            font-size: 14px;
            border-radius: 5px;
            cursor: pointer;
          ">Close</button>
        </div>
        ` : ''}
      </body>
      </html>
    `;
  }
}
