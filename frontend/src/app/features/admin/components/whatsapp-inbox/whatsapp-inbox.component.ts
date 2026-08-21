import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { MatTableModule } from '@angular/material/table';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonToggleModule } from '@angular/material/button-toggle';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatSelectModule } from '@angular/material/select';
import { SwalService } from '../../../../core/services/swal.service';
import { WhatsAppInboxService, WhatsAppInboxMessage, ShopOption, SuggestProduct } from '../../services/whatsapp-inbox.service';

/** One line of the customer's order text, matched against shop products. */
interface ParsedLine {
  raw: string;
  qty: number;
  keyword: string;
  options: SuggestProduct[];
  selected: SuggestProduct | null;
}

/**
 * Inbox of customer messages sent to the business WhatsApp number (orders
 * typed as chat messages, received via the Meta webhook). Staff read the
 * order text, assign it to the shop that will fulfil it, open POS with the
 * customer prefilled, and mark it processed.
 *
 * Standalone so both the admin (/admin/whatsapp-inbox) and shop-owner
 * (/shop-owner/whatsapp-inbox) routes can mount the same screen.
 */
@Component({
  selector: 'app-whatsapp-inbox',
  templateUrl: './whatsapp-inbox.component.html',
  styleUrls: ['./whatsapp-inbox.component.css'],
  standalone: true,
  imports: [
    CommonModule,
    MatTableModule,
    MatButtonModule,
    MatIconModule,
    MatButtonToggleModule,
    MatProgressSpinnerModule,
    MatTooltipModule,
    MatSelectModule
  ]
})
export class WhatsAppInboxComponent implements OnInit, OnDestroy {
  messages: WhatsAppInboxMessage[] = [];
  shops: ShopOption[] = [];
  /** Shop catalog for order-text suggestions (empty for admins without a shop). */
  products: SuggestProduct[] = [];
  expandedId: number | null = null;
  suggestMap: { [messageId: number]: ParsedLine[] } = {};
  loading = true;
  currentPage = 0;
  totalPages = 0;
  totalItems = 0;
  pageSize = 20;
  newCount = 0;

  /** '' = all */
  filterStatus: string = 'NEW';

  displayedColumns = ['receivedAt', 'customer', 'body', 'shop', 'status', 'actions'];

  // New orders should appear without the admin pressing refresh
  private refreshTimer: any = null;
  private readonly REFRESH_MS = 30000;

  constructor(
    private inboxService: WhatsAppInboxService,
    private router: Router,
    private swal: SwalService
  ) {}

  ngOnInit(): void {
    this.load();
    this.inboxService.getShops().subscribe({
      next: (shops) => this.shops = shops,
      error: (err) => console.error('Error loading shops:', err)
    });
    this.inboxService.getMyProducts().subscribe({
      next: (products) => this.products = products,
      error: () => this.products = []  // admin without a shop — no suggestions
    });
    this.refreshTimer = setInterval(() => this.load(true), this.REFRESH_MS);
  }

  ngOnDestroy(): void {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer);
    }
  }

  load(background: boolean = false): void {
    if (!background) {
      this.loading = true;
    }
    this.inboxService.list(this.filterStatus, this.currentPage, this.pageSize).subscribe({
      next: (page) => {
        this.messages = page?.content || [];
        this.totalPages = page?.totalPages || 0;
        this.totalItems = page?.totalElements || 0;
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading WhatsApp inbox:', err);
        this.loading = false;
        if (!background) {
          this.swal.toast('Failed to load WhatsApp messages', 'error');
        }
      }
    });
    this.inboxService.summary().subscribe({
      next: (s) => this.newCount = s.newCount,
      error: () => {}
    });
  }

  onFilterChange(status: string): void {
    this.filterStatus = status;
    this.currentPage = 0;
    this.load();
  }

  onPageChange(page: number): void {
    this.currentPage = page;
    this.load();
  }

  /** Assign (or clear, shopId=null) the shop that will fulfil this order. */
  assignShop(message: WhatsAppInboxMessage, shopId: number | null): void {
    const shop = this.shops.find(s => s.id === shopId) || null;
    this.inboxService.assignShop(message.id, shop).subscribe({
      next: (updated) => {
        message.shopId = updated.shopId;
        message.shopName = updated.shopName;
        this.swal.toast(shop ? `Assigned to ${shop.name}` : 'Assignment cleared', 'success');
      },
      error: (err) => {
        console.error('Error assigning shop:', err);
        this.swal.toast('Failed to assign shop', 'error');
      }
    });
  }

  /**
   * Open POS billing with this customer prefilled (same one-shot localStorage
   * handoff Order Management's "Add Cart Again" uses; items stay empty — staff
   * add products while reading the order text). The assigned shopId rides
   * along so the bill lands under the right shop.
   */
  createBill(message: WhatsAppInboxMessage): void {
    localStorage.setItem('pos_readd_order', JSON.stringify({
      shopId: message.shopId || undefined,
      customerName: message.profileName || '',
      customerPhone: this.toLocalNumber(message.fromNumber),
      items: [],
      whatsappOrderText: message.body || '',
      savedAt: Date.now()
    }));
    this.router.navigate(['/shop-owner/pos-billing']);
  }

  /** Toggle the suggestion panel for a message, computing matches on first open. */
  toggleSuggest(message: WhatsAppInboxMessage): void {
    if (this.expandedId === message.id) {
      this.expandedId = null;
      return;
    }
    this.expandedId = message.id;
    if (!this.suggestMap[message.id]) {
      this.suggestMap[message.id] = this.parseOrderText(message.body || '');
    }
  }

  suggestionsFor(message: WhatsAppInboxMessage): ParsedLine[] {
    return this.suggestMap[message.id] || [];
  }

  selectOption(line: ParsedLine, product: SuggestProduct): void {
    line.selected = line.selected?.id === product.id ? null : product;
  }

  /**
   * Open POS with the selected suggestions already in the cart (plus the
   * customer). Unmatched lines travel along so POS can remind staff to add
   * them manually.
   */
  addAllToCartAndBill(message: WhatsAppInboxMessage): void {
    const lines = this.suggestionsFor(message);
    const items = lines
      .filter(l => l.selected)
      .map(l => ({
        shopProductId: l.selected!.id,
        name: l.selected!.name,
        quantity: Math.max(1, Math.round(l.qty))
      }));
    if (items.length === 0) {
      this.createBill(message);
      return;
    }
    const unmatched = lines.filter(l => !l.selected).map(l => l.raw);
    localStorage.setItem('pos_readd_order', JSON.stringify({
      shopId: message.shopId || undefined,
      customerName: message.profileName || '',
      customerPhone: this.toLocalNumber(message.fromNumber),
      items,
      whatsappOrderText: message.body || '',
      whatsappUnmatchedText: unmatched.join('\n'),
      savedAt: Date.now()
    }));
    this.router.navigate(['/shop-owner/pos-billing']);
  }

  /** Split the order text into lines and fuzzy-match each against the catalog. */
  private parseOrderText(body: string): ParsedLine[] {
    return body
      .split(/\r?\n|,/)
      .map(raw => raw.trim())
      .filter(raw => raw.length > 0)
      .map(raw => {
        const { qty, keyword } = this.extractQtyAndKeyword(raw);
        const options = this.matchProducts(keyword);
        return { raw, qty, keyword, options, selected: options[0] || null };
      });
  }

  /** "2kg Onion" -> qty 2, keyword "onion"; "250g rava" -> qty 1 (one pack). */
  private extractQtyAndKeyword(raw: string): { qty: number; keyword: string } {
    let text = raw.toLowerCase();
    let qty = 1;
    const m = text.match(/(\d+(?:\.\d+)?)\s*(kg|kgs|gm|g|gram|grams|l|lt|ltr|litre|liter|ml|pc|pcs|piece|pieces|pkt|packet|dozen)?/);
    if (m) {
      const n = parseFloat(m[1]);
      const unit = (m[2] || '').toLowerCase();
      // grams/ml describe pack size, not count; everything else is a count
      qty = ['g', 'gm', 'gram', 'grams', 'ml'].includes(unit) ? 1 : (n || 1);
      text = text.replace(m[0], ' ');
    }
    const fillers = ['order', 'please', 'pls', 'need', 'want', 'send', 'and', 'the', 'for', 'venum', 'vennum'];
    const keyword = text
      .split(/[^a-z஀-௿0-9]+/)
      .filter(w => w.length > 1 && !fillers.includes(w))
      .join(' ')
      .trim();
    return { qty, keyword };
  }

  /** Top 3 catalog products matching the keyword (English + Tamil, typo-tolerant). */
  private matchProducts(keyword: string): SuggestProduct[] {
    if (!keyword) return [];
    const tokens = keyword.split(/\s+/).filter(t => t.length > 1);
    if (tokens.length === 0) return [];
    const scored = this.products
      .map(p => {
        const prodText = `${p.name} ${p.nameTamil}`.toLowerCase();
        const prodWords = prodText.split(/[^a-z஀-௿0-9]+/).filter(w => w.length > 1);
        let score = 0;
        for (const token of tokens) {
          if (prodWords.includes(token)) score += 3;
          else if (prodText.includes(token)) score += 2;
          else if (token.length >= 4 && prodWords.some(w => this.editDistanceAtMost1(token, w))) score += 1;
        }
        return { p, score };
      })
      .filter(s => s.score > 0)
      .sort((a, b) => b.score - a.score || a.p.name.length - b.p.name.length);
    return scored.slice(0, 3).map(s => s.p);
  }

  /** True when a and b differ by at most one edit (catches "suger" vs "sugar"). */
  private editDistanceAtMost1(a: string, b: string): boolean {
    if (Math.abs(a.length - b.length) > 1) return false;
    if (a === b) return true;
    const [shorter, longer] = a.length <= b.length ? [a, b] : [b, a];
    let i = 0, j = 0, edits = 0;
    while (i < shorter.length && j < longer.length) {
      if (shorter[i] === longer[j]) { i++; j++; continue; }
      if (++edits > 1) return false;
      if (shorter.length === longer.length) { i++; j++; } else { j++; }
    }
    return edits + (longer.length - j) + (shorter.length - i) <= 1;
  }

  markProcessed(message: WhatsAppInboxMessage): void {
    this.inboxService.markProcessed(message.id).subscribe({
      next: () => {
        this.swal.toast('Marked as processed', 'success');
        this.load();
      },
      error: (err) => {
        console.error('Error marking processed:', err);
        this.swal.toast('Failed to update message', 'error');
      }
    });
  }

  copyText(message: WhatsAppInboxMessage): void {
    navigator.clipboard.writeText(message.body || '').then(() => {
      this.swal.toast('Order text copied', 'success');
    });
  }

  /** Meta sends "9163742..." — POS expects the 10-digit local number */
  toLocalNumber(from: string): string {
    const digits = (from || '').replace(/\D/g, '');
    return digits.length === 12 && digits.startsWith('91') ? digits.substring(2) : digits;
  }

  formatDate(dateStr: string | null): string {
    if (!dateStr) return '';
    return new Date(dateStr).toLocaleDateString('en-IN', {
      day: '2-digit',
      month: 'short',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  getPages(): number[] {
    return Array.from({ length: this.totalPages }, (_, i) => i);
  }
}
