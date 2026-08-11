import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { SwalService } from '../../../../core/services/swal.service';
import { ShopContextService } from '../../services/shop-context.service';

interface CustomField {
  label: string;
  value: string;
  enabled: boolean;
  position: 'header' | 'footer';
}

interface BillSettings {
  shopName: string; shopPhone: string; shopAddress: string; gstNumber: string; fssaiNumber: string; fssaiName: string;
  dateFormat: 'DD/MM/YYYY' | 'MM/DD/YYYY' | 'YYYY-MM-DD'; billNumberPrefix: string; showBillNumber: boolean;
  paperWidth: '58mm' | '80mm' | 'A4'; templateStyle: 'classic' | 'minimal' | 'bold'; headerFontSize: number; bodyFontSize: number; footerFontSize: number;
  showShopName: boolean; showShopPhone: boolean; showShopAddress: boolean; showGstNumber: boolean; showFssaiInfo: boolean;
  showDateTime: boolean; showCustomerDetails: boolean; showThankYouMessage: boolean;
  showItemSku: boolean; showItemBarcode: boolean; showItemMrp: boolean; showItemDiscount: boolean; showItemTax: boolean;
  showSubtotal: boolean; showTotalSavings: boolean; showTaxBreakdown: boolean; showPaymentMethod: boolean;
  showEnglish: boolean; showTamil: boolean; thankYouMessage: string; footerNote: string;
  separatorStyle: 'solid' | 'dashed' | 'dotted' | 'none'; upiId: string; showUpiQrCode: boolean;
  autoSendWhatsAppOnPrint: boolean; autoSendEmailOnPrint: boolean;
  customFields: CustomField[]; sectionOrder: string[];
}

const DEFAULT_SETTINGS: BillSettings = {
  shopName: '', shopPhone: '', shopAddress: '', gstNumber: '', fssaiNumber: '', fssaiName: '',
  dateFormat: 'DD/MM/YYYY', billNumberPrefix: '', showBillNumber: true, paperWidth: '80mm', templateStyle: 'classic',
  headerFontSize: 16, bodyFontSize: 12, footerFontSize: 10,
  showShopName: true, showShopPhone: true, showShopAddress: false, showGstNumber: false, showFssaiInfo: false,
  showDateTime: true, showCustomerDetails: true, showThankYouMessage: true,
  showItemSku: false, showItemBarcode: false, showItemMrp: true, showItemDiscount: true, showItemTax: false,
  showSubtotal: true, showTotalSavings: true, showTaxBreakdown: false, showPaymentMethod: true,
  showEnglish: true, showTamil: true, thankYouMessage: 'Thank you for your order!', footerNote: '',
  separatorStyle: 'dashed', upiId: '', showUpiQrCode: false,
  autoSendWhatsAppOnPrint: false, autoSendEmailOnPrint: false,
  customFields: [
    { label: '', value: '', enabled: false, position: 'header' },
    { label: '', value: '', enabled: false, position: 'footer' }
  ],
  sectionOrder: ['header', 'billInfo', 'items', 'summary', 'payment', 'qrCode', 'footer']
};

@Component({
  selector: 'app-bill-settings',
  templateUrl: './bill-settings.component.html',
  styleUrls: ['./bill-settings.component.scss']
})
export class BillSettingsComponent implements OnInit {
  settings: BillSettings = this.cloneDefaults();
  readonly templates = [
    { value: 'classic', name: 'Market Classic', note: 'Familiar, detailed and practical', icon: 'receipt_long' },
    { value: 'minimal', name: 'Clean Counter', note: 'Quiet, fast-scanning layout', icon: 'density_small' },
    { value: 'bold', name: 'NammaOoru Bold', note: 'Strong green total and shop identity', icon: 'storefront' }
  ] as const;

  constructor(
    private router: Router,
    private swal: SwalService,
    private shopContext: ShopContextService
  ) {}

  ngOnInit(): void {
    const saved = localStorage.getItem('pos_bill_settings');
    if (saved) {
      try { this.settings = { ...this.cloneDefaults(), ...JSON.parse(saved) }; } catch { /* retain defaults */ }
    }
    const shop = this.shopContext.getCurrentShop();
    if (shop && !this.settings.shopName) this.settings.shopName = shop.name || shop.businessName || '';
    if (shop && !this.settings.shopPhone) this.settings.shopPhone = (shop as any).phone || '';
  }

  selectTemplate(value: 'classic' | 'minimal' | 'bold'): void { this.settings.templateStyle = value; }
  addCustomField(): void {
    if (this.settings.customFields.length < 6) this.settings.customFields.push({ label: '', value: '', enabled: true, position: 'footer' });
  }
  removeCustomField(index: number): void { this.settings.customFields.splice(index, 1); }
  moveSection(index: number, direction: -1 | 1): void {
    const target = index + direction;
    if (target < 0 || target >= this.settings.sectionOrder.length) return;
    [this.settings.sectionOrder[index], this.settings.sectionOrder[target]] = [this.settings.sectionOrder[target], this.settings.sectionOrder[index]];
  }
  sectionLabel(section: string): string {
    return ({ header: 'Shop header', billInfo: 'Bill information', items: 'Items', summary: 'Totals', payment: 'Payment', qrCode: 'UPI QR', footer: 'Footer' } as any)[section] || section;
  }
  save(): void {
    if (!this.settings.showEnglish && !this.settings.showTamil) {
      this.swal.warning('Choose a language', 'Keep English or Tamil enabled for the receipt.'); return;
    }
    localStorage.setItem('pos_bill_settings', JSON.stringify(this.settings));
    localStorage.setItem('pos_receipt_language', JSON.stringify({ english: this.settings.showEnglish, tamil: this.settings.showTamil }));
    this.swal.success('Saved', 'Bill design settings saved');
  }
  reset(): void { this.settings = this.cloneDefaults(); }
  back(): void { this.router.navigate(['/shop-owner/pos-billing']); }
  trackByIndex(index: number): number { return index; }
  private cloneDefaults(): BillSettings { return JSON.parse(JSON.stringify(DEFAULT_SETTINGS)); }
}
