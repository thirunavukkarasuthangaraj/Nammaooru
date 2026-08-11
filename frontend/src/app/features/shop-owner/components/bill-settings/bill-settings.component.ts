import { Component, ElementRef, HostListener, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { SwalService } from '../../../../core/services/swal.service';
import { ShopContextService } from '../../services/shop-context.service';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';

interface CustomField {
  label: string;
  value: string;
  enabled: boolean;
  position: 'header' | 'footer';
}

interface BillSettings {
  identityVisibilityVersion: number;
  shopName: string; shopPhone: string; shopAddress: string; gstNumber: string; fssaiNumber: string; fssaiName: string;
  dateFormat: 'DD/MM/YYYY' | 'MM/DD/YYYY' | 'YYYY-MM-DD'; billNumberPrefix: string; showBillNumber: boolean;
  paperWidth: '58mm' | '80mm' | 'A4'; templateStyle: 'classic' | 'minimal' | 'bold' | 'compact' | 'invoice' | 'bordered'; accentColor: string; headerFontSize: number; bodyFontSize: number; footerFontSize: number;
  showShopName: boolean; showShopPhone: boolean; showShopAddress: boolean; showGstNumber: boolean; showFssaiInfo: boolean;
  showDateTime: boolean; showCustomerDetails: boolean; showThankYouMessage: boolean;
  showItemSku: boolean; showItemBarcode: boolean; showItemMrp: boolean; showSellingPrice: boolean; showItemDiscount: boolean; showItemTax: boolean;
  showSubtotal: boolean; showTotalSavings: boolean; showTaxBreakdown: boolean; showPaymentMethod: boolean;
  showEnglish: boolean; showTamil: boolean; thankYouMessage: string; footerNote: string;
  separatorStyle: 'solid' | 'dashed' | 'dotted' | 'none'; upiId: string; showUpiQrCode: boolean;
  autoSendWhatsAppOnPrint: boolean; autoSendEmailOnPrint: boolean;
  customFields: CustomField[]; sectionOrder: string[];
}

const DEFAULT_SETTINGS: BillSettings = {
  identityVisibilityVersion: 1,
  shopName: '', shopPhone: '', shopAddress: '', gstNumber: '', fssaiNumber: '', fssaiName: '',
  dateFormat: 'DD/MM/YYYY', billNumberPrefix: '', showBillNumber: true, paperWidth: '80mm', templateStyle: 'classic', accentColor: '#43d77d',
  headerFontSize: 16, bodyFontSize: 12, footerFontSize: 10,
  showShopName: true, showShopPhone: true, showShopAddress: false, showGstNumber: false, showFssaiInfo: false,
  showDateTime: true, showCustomerDetails: true, showThankYouMessage: true,
  showItemSku: false, showItemBarcode: false, showItemMrp: true, showSellingPrice: true, showItemDiscount: false, showItemTax: false,
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
  @ViewChild('paperStage') paperStage?: ElementRef<HTMLElement>;
  settings: BillSettings = this.cloneDefaults();
  private shopId?: number;
  private serverLoaded = false;
  private saveTimer?: ReturnType<typeof setTimeout>;
  readonly templates = [
    { value: 'classic', name: 'Market Classic', note: 'Familiar, detailed and practical', icon: 'receipt_long' },
    { value: 'minimal', name: 'Clean Counter', note: 'Quiet, fast-scanning layout', icon: 'density_small' },
    { value: 'bold', name: 'NammaOoru Bold', note: 'Strong total and shop identity', icon: 'storefront' },
    { value: 'compact', name: 'Compact Thermal', note: 'Saves paper on busy counters', icon: 'compress' },
    { value: 'invoice', name: 'GST Professional', note: 'Structured business receipt', icon: 'request_quote' },
    { value: 'bordered', name: 'Border Receipt', note: 'Clear framed sections and total', icon: 'border_outer' }
  ] as const;
  readonly accentColors = ['#43d77d', '#1687d9', '#7c4dff', '#ef6c00', '#d81b60', '#263238'];

  constructor(
    private router: Router,
    private swal: SwalService,
    private shopContext: ShopContextService,
    private http: HttpClient
  ) {}

  ngOnInit(): void {
    const saved = localStorage.getItem('pos_bill_settings');
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        this.settings = { ...this.cloneDefaults(), ...parsed };
        if (parsed.identityVisibilityVersion !== 1) {
          if (this.settings.shopAddress?.trim()) this.settings.showShopAddress = true;
          if (this.settings.shopPhone?.trim()) this.settings.showShopPhone = true;
          if (this.settings.gstNumber?.trim()) this.settings.showGstNumber = true;
          if (this.settings.fssaiNumber?.trim() || this.settings.fssaiName?.trim()) this.settings.showFssaiInfo = true;
          this.settings.identityVisibilityVersion = 1;
          this.persistDraft();
        }
      } catch { /* retain defaults */ }
    }
    const shop = this.shopContext.getCurrentShop();
    if (shop && !this.settings.shopName) this.settings.shopName = shop.name || shop.businessName || '';
    if (shop && !this.settings.shopPhone) this.settings.shopPhone = (shop as any).phone || '';
    if (shop?.id) this.loadServerSettings(shop.id);
    else this.shopContext.shop$.subscribe(current => {
      if (current?.id && !this.serverLoaded) this.loadServerSettings(current.id);
    });
  }

  @HostListener('input')
  @HostListener('change')
  persistDraft(): void {
    localStorage.setItem('pos_bill_settings', JSON.stringify(this.settings));
    localStorage.setItem('pos_receipt_language', JSON.stringify({ english: this.settings.showEnglish, tamil: this.settings.showTamil }));
    if (this.serverLoaded && this.shopId) {
      clearTimeout(this.saveTimer);
      this.saveTimer = setTimeout(() => this.saveToServer(false), 700);
    }
  }

  selectTemplate(value: BillSettings['templateStyle']): void { this.settings.templateStyle = value; this.persistDraft(); }
  showPreviewTop(): void {
    requestAnimationFrame(() => this.paperStage?.nativeElement.scrollTo({ top: 0, behavior: 'smooth' }));
  }
  identityChanged(field: 'address' | 'phone' | 'gst' | 'fssai', value: string): void {
    if (value && value.trim()) {
      if (field === 'address') this.settings.showShopAddress = true;
      if (field === 'phone') this.settings.showShopPhone = true;
      if (field === 'gst') this.settings.showGstNumber = true;
      if (field === 'fssai') this.settings.showFssaiInfo = true;
    }
    this.persistDraft();
    this.showPreviewTop();
  }
  addCustomField(): void {
    if (this.settings.customFields.length < 6) { this.settings.customFields.push({ label: '', value: '', enabled: true, position: 'footer' }); this.persistDraft(); }
  }
  removeCustomField(index: number): void { this.settings.customFields.splice(index, 1); this.persistDraft(); }
  moveSection(index: number, direction: -1 | 1): void {
    const target = index + direction;
    if (target < 0 || target >= this.settings.sectionOrder.length) return;
    [this.settings.sectionOrder[index], this.settings.sectionOrder[target]] = [this.settings.sectionOrder[target], this.settings.sectionOrder[index]];
    this.persistDraft();
  }
  sectionLabel(section: string): string {
    return ({ header: 'Shop header', billInfo: 'Bill information', items: 'Items', summary: 'Totals', payment: 'Payment', qrCode: 'UPI QR', footer: 'Footer' } as any)[section] || section;
  }
  save(): void {
    if (!this.settings.showEnglish && !this.settings.showTamil) {
      this.swal.warning('Choose a language', 'Keep English or Tamil enabled for the receipt.'); return;
    }
    this.persistDraft();
    this.saveToServer(true);
  }
  reset(): void { this.settings = this.cloneDefaults(); this.persistDraft(); }
  back(): void { this.router.navigate(['/shop-owner/pos-billing']); }
  trackByIndex(index: number): number { return index; }
  private cloneDefaults(): BillSettings { return JSON.parse(JSON.stringify(DEFAULT_SETTINGS)); }

  private loadServerSettings(shopId: number): void {
    this.shopId = shopId;
    this.http.get<any>(`${environment.apiUrl}/pos/shops/${shopId}/bill-settings`).subscribe({
      next: response => {
        const data = response?.data || response;
        this.settings = { ...this.cloneDefaults(), ...(data || {}) };
        this.serverLoaded = true;
        localStorage.setItem('pos_bill_settings', JSON.stringify(this.settings));
      },
      error: error => {
        console.warn('Using locally cached bill settings until the server is available', error);
        this.serverLoaded = true;
      }
    });
  }

  private saveToServer(showConfirmation: boolean): void {
    if (!this.shopId) {
      if (showConfirmation) this.swal.warning('Not saved to server', 'Shop information is still loading. Please try again.');
      return;
    }
    this.http.put<any>(`${environment.apiUrl}/pos/shops/${this.shopId}/bill-settings`, this.settings).subscribe({
      next: response => {
        const data = response?.data || response;
        if (data) this.settings = { ...this.cloneDefaults(), ...data };
        localStorage.setItem('pos_bill_settings', JSON.stringify(this.settings));
        if (showConfirmation) this.swal.success('Saved', 'This design will be used for print, WhatsApp and email bills.');
      },
      error: () => {
        if (showConfirmation) this.swal.error('Could not save', 'The design is cached on this device, but was not saved to the server.');
      }
    });
  }
}
