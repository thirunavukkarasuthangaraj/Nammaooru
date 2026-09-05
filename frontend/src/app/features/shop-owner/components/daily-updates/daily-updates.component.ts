import { Component, OnDestroy } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged, takeUntil } from 'rxjs/operators';
import { environment } from '../../../../../environments/environment';
import { SwalService } from '../../../../core/services/swal.service';
import { getImageUrl as getImageUrlUtil } from '../../../../core/utils/image-url.util';

interface DailyUpdateProduct {
  id: number;
  name: string;
  unitLabel: string;
  sortWeight: number;
  imageUrl?: string;
  price: number;
  originalPrice: number | null;
  suggested?: boolean;
  originalValues: {
    price: number;
    originalPrice: number | null;
  };
}

interface ProductGroup {
  key: string;
  displayName: string;
  imageUrl?: string;
  rows: DailyUpdateProduct[];
}

// AI-parsed shape of a spoken/typed phrase like "vengayam 1kg 100 rs",
// returned by the backend's Gemini-powered /parse-price-entry endpoint.
interface ParsedPriceEntry {
  item: string;
  weight: number | null;
  unit: string | null;
  price: number | null;
}

// Pack-size tokens that get stripped off a product name to derive its
// group key, e.g. "Onion 1kg" and "Onion 500g" both group under "Onion".
const SIZE_SUFFIX = /[\s\-,]*\d+(\.\d+)?\s*(kgs?|gms?|grams?|g|ml|ltrs?|litres?|l|pcs?|pieces?|nos?)\.?\s*$/i;

@Component({
  selector: 'app-daily-updates',
  templateUrl: './daily-updates.component.html',
  styleUrls: ['./daily-updates.component.scss']
})
export class DailyUpdatesComponent implements OnDestroy {
  private destroy$ = new Subject<void>();
  private searchSubject$ = new Subject<string>();
  private apiUrl = environment.apiUrl;

  searchTerm = '';
  hasSearched = false;
  loading = false;
  saving = false;
  aiResolving = false;
  aiKeywords: string[] | null = null;

  // Quick voice/typed entry: "onion 1kg 45"
  quickEntryText = '';
  recording = false;
  transcribing = false;
  parsingEntry = false;
  micSupported = !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
  private mediaRecorder: MediaRecorder | null = null;
  private audioChunks: Blob[] = [];

  viewMode: 'sheet' | 'card' = 'sheet';

  groups: ProductGroup[] = [];
  activeGroupKey: string | null = null;
  modified: Map<number, DailyUpdateProduct> = new Map();

  constructor(
    private http: HttpClient,
    private swalService: SwalService
  ) {
    this.searchSubject$.pipe(
      debounceTime(350),
      distinctUntilChanged(),
      takeUntil(this.destroy$)
    ).subscribe(term => this.search(term));
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
    if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
      this.mediaRecorder.stop();
    }
  }

  // ---------- Search box (manual typing) ----------

  onSearchInput(value: string): void {
    this.searchTerm = value;
    this.searchSubject$.next(value.trim());
  }

  searchNow(): void {
    this.search(this.searchTerm.trim());
  }

  private async search(term: string): Promise<void> {
    if (term.length < 2) {
      this.hasSearched = false;
      this.aiKeywords = null;
      return;
    }

    this.loading = true;
    this.hasSearched = true;
    this.aiKeywords = null;

    const { rows, keywords } = await this.findRowsForTerm(term);
    if (keywords) {
      this.aiKeywords = keywords;
    }

    this.mergeRowsIntoGroups(rows);
    this.loading = false;
  }

  // ---------- Quick voice/typed entry ----------

  async toggleRecording(): Promise<void> {
    if (!this.micSupported) {
      return;
    }
    if (this.recording) {
      this.mediaRecorder?.stop();
      return;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      this.audioChunks = [];
      this.mediaRecorder = new MediaRecorder(stream);
      this.mediaRecorder.ondataavailable = (e: BlobEvent) => {
        if (e.data.size > 0) {
          this.audioChunks.push(e.data);
        }
      };
      this.mediaRecorder.onstop = () => {
        stream.getTracks().forEach(track => track.stop());
        this.recording = false;
        const blob = new Blob(this.audioChunks, { type: this.mediaRecorder?.mimeType || 'audio/webm' });
        this.handleRecordedAudio(blob);
      };
      this.mediaRecorder.start();
      this.recording = true;
    } catch {
      this.swalService.toast('Microphone access denied or unavailable', 'error');
      this.recording = false;
    }
  }

  private async handleRecordedAudio(blob: Blob): Promise<void> {
    if (blob.size === 0) {
      this.swalService.toast('No audio captured — check mic permission and try again', 'warning');
      return;
    }

    this.transcribing = true;
    try {
      const formData = new FormData();
      formData.append('audio', blob, 'entry.webm');
      const response: any = await this.http.post(
        `${this.apiUrl}/v1/products/search/voice-audio`, formData,
        { params: { context: 'price-entry' } }
      ).pipe(takeUntil(this.destroy$)).toPromise();

      const transcript = response?.data?.transcription?.trim();
      console.log('[daily-updates] voice-audio response:', response);
      if (!transcript) {
        this.swalService.toast('Could not hear anything — please try again or type instead', 'warning');
        return;
      }
      this.quickEntryText = transcript;
      await this.submitQuickEntry();
    } catch (error: any) {
      console.error('[daily-updates] voice-audio failed:', error);
      const detail = error?.error?.message || error?.message || `HTTP ${error?.status ?? '?'}`;
      this.swalService.toast(`Voice transcription failed (${detail}) — please type instead`, 'error');
    } finally {
      this.transcribing = false;
    }
  }

  async submitQuickEntry(): Promise<void> {
    const text = this.quickEntryText.trim();
    if (!text) {
      return;
    }

    this.parsingEntry = true;
    const parsed = await this.parsePriceEntryWithAi(text);
    this.parsingEntry = false;

    if (!parsed || !parsed.item || parsed.price === null) {
      this.swalService.toast('Could not understand that — try "onion 1kg 45"', 'warning');
      return;
    }

    this.loading = true;
    const { rows } = await this.findRowsForTerm(parsed.item);
    this.loading = false;

    if (rows.length === 0) {
      this.swalService.toast(`No product found for "${parsed.item}"`, 'warning');
      return;
    }

    const freshGroups = this.groupRows(rows);
    const bestGroup = this.pickBestGroup(freshGroups, parsed.item);
    const group = this.upsertGroup(bestGroup);
    this.activeGroupKey = null;

    this.applyQuickEntryToGroup(group, parsed);

    this.swalService.toast(`${group.displayName}: updated from your entry`, 'success');
    this.quickEntryText = '';
  }

  // Single Gemini (Groq-fallback) call that both translates the item name to
  // English and extracts pack size + price in one shot — see backend
  // ProductAISearchController#parsePriceEntry.
  private async parsePriceEntryWithAi(text: string): Promise<ParsedPriceEntry | null> {
    try {
      const response: any = await this.http.get(
        `${this.apiUrl}/v1/products/search/parse-price-entry`,
        { params: { text } }
      ).pipe(takeUntil(this.destroy$)).toPromise();
      console.log('[daily-updates] parse-price-entry response:', response);
      const data = response?.data;
      if (!data) {
        return null;
      }
      return {
        item: (data.item || '').toString().trim(),
        weight: typeof data.weight === 'number' ? data.weight : null,
        unit: data.unit || null,
        price: typeof data.price === 'number' ? data.price : null
      };
    } catch (error) {
      console.error('[daily-updates] parse-price-entry failed:', error);
      return null;
    }
  }

  private applyQuickEntryToGroup(group: ProductGroup, parsed: ParsedPriceEntry): void {
    let anchor: DailyUpdateProduct;

    if (parsed.weight && parsed.unit) {
      const targetGrams = this.toGrams(parsed.unit, parsed.weight);
      anchor = group.rows.reduce((best, row) =>
        Math.abs(row.sortWeight - targetGrams) < Math.abs(best.sortWeight - targetGrams) ? row : best,
        group.rows[0]);
    } else if (group.rows.length === 1) {
      anchor = group.rows[0];
    } else {
      this.swalService.toast(`${group.displayName} has multiple pack sizes — say the size too, e.g. "1kg"`, 'warning');
      return;
    }

    anchor.price = parsed.price!;
    anchor.suggested = false;
    this.markModified(anchor);
    this.suggestSiblingPrices(group, anchor);
  }

  // Given one row's price just changed, proportionally scale every OTHER row
  // in the same group by weight ratio (e.g. 1kg=100 -> 500g suggested as 50).
  // A sibling the owner has manually typed a value into is left alone; a
  // sibling only holding an earlier AI suggestion is always refreshed to the
  // latest number, since a stale suggestion is never worth protecting.
  private suggestSiblingPrices(group: ProductGroup, anchor: DailyUpdateProduct): void {
    const anchorGrams = anchor.sortWeight;
    if (anchorGrams > 0) {
      const pricePerGram = anchor.price / anchorGrams;
      group.rows.forEach(row => {
        const isManuallyEdited = this.modified.has(row.id) && !row.suggested;
        if (row.id === anchor.id || row.sortWeight <= 0 || isManuallyEdited) {
          return;
        }
        row.price = Math.round(pricePerGram * row.sortWeight * 100) / 100;
        row.suggested = true;
        this.markModified(row);
      });
    }
    group.rows.sort((a, b) => a.sortWeight - b.sortWeight);
  }

  // Picks the fetched group whose name shares the most words with what was
  // said/typed — a plain relevance guess, good enough for a single-item phrase.
  private pickBestGroup(groups: ProductGroup[], itemText: string): ProductGroup {
    const words = itemText.toLowerCase().split(/\s+/);
    let best = groups[0];
    let bestScore = -1;
    for (const g of groups) {
      const nameWords = g.displayName.toLowerCase().split(/\s+/);
      const score = words.filter(w => nameWords.includes(w)).length;
      if (score > bestScore) {
        bestScore = score;
        best = g;
      }
    }
    return best;
  }

  // ---------- Shared fetch + AI keyword fallback ----------

  private async findRowsForTerm(term: string): Promise<{ rows: DailyUpdateProduct[]; keywords: string[] | null }> {
    let rows = await this.fetchRows(term);
    if (rows.length > 0) {
      return { rows, keywords: null };
    }

    // No direct match — the owner may have typed/said a Tamil/colloquial/misspelled
    // word (e.g. "vengayam") that doesn't appear in the stored product names.
    // Ask the existing AI keyword resolver (Gemini, falls back to Groq) what
    // English grocery term(s) that maps to, and retry with those.
    const keywords = await this.resolveKeywordsWithAi(term);
    if (keywords.length === 0) {
      return { rows: [], keywords: null };
    }

    const perKeyword = await Promise.all(keywords.map(k => this.fetchRows(k)));
    const merged = new Map<number, DailyUpdateProduct>();
    perKeyword.flat().forEach(row => merged.set(row.id, row));
    rows = Array.from(merged.values());
    return { rows, keywords: rows.length > 0 ? keywords : null };
  }

  private fetchRows(term: string): Promise<DailyUpdateProduct[]> {
    return this.http.get<any>(`${this.apiUrl}/shop-products/my-products`, {
      params: { search: term, size: '100', page: '0' }
    }).pipe(takeUntil(this.destroy$)).toPromise()
      .then(response => {
        const content = response?.data?.content || [];
        return content.map((p: any) => this.toRow(p));
      })
      .catch(() => {
        this.swalService.toast('Failed to search products', 'error');
        return [];
      });
  }

  private async resolveKeywordsWithAi(term: string): Promise<string[]> {
    this.aiResolving = true;
    try {
      const response: any = await this.http.get(
        `${this.apiUrl}/v1/products/search/resolve-keyword`,
        { params: { q: term } }
      ).pipe(takeUntil(this.destroy$)).toPromise();
      return response?.data?.keywords || [];
    } catch {
      return [];
    } finally {
      this.aiResolving = false;
    }
  }

  // ---------- Grouping (pack-size variants of the same product) ----------

  // Merges freshly fetched rows into the persistent groups list ("cart"),
  // so results from an earlier search/voice entry stay visible and their
  // unsaved edits are never overwritten by a later, unrelated lookup.
  private mergeRowsIntoGroups(rows: DailyUpdateProduct[]): void {
    this.groupRows(rows).forEach(freshGroup => this.upsertGroup(freshGroup));
    this.groups = [...this.groups].sort((a, b) => a.displayName.localeCompare(b.displayName));
  }

  private upsertGroup(freshGroup: ProductGroup): ProductGroup {
    let group = this.groups.find(g => g.key === freshGroup.key);
    if (!group) {
      group = { key: freshGroup.key, displayName: freshGroup.displayName, imageUrl: freshGroup.imageUrl, rows: [] };
      this.groups = [...this.groups, group];
    }

    freshGroup.rows.forEach(freshRow => {
      const idx = group!.rows.findIndex(r => r.id === freshRow.id);
      if (idx < 0) {
        group!.rows.push(freshRow);
      } else if (!this.modified.has(freshRow.id)) {
        // Safe to refresh from the server — no unsaved local edit to protect.
        group!.rows[idx] = freshRow;
      }
    });
    group.rows.sort((a, b) => a.sortWeight - b.sortWeight);
    return group;
  }

  private groupRows(rows: DailyUpdateProduct[]): ProductGroup[] {
    const order: string[] = [];
    const byKey = new Map<string, ProductGroup>();

    for (const row of rows) {
      const stripped = this.stripSizeSuffix(row.name);
      const key = stripped.toLowerCase();
      let group = byKey.get(key);
      if (!group) {
        group = { key, displayName: stripped, imageUrl: row.imageUrl, rows: [] };
        byKey.set(key, group);
        order.push(key);
      }
      group.rows.push(row);
    }

    return order.map(key => byKey.get(key)!)
      .map(g => ({ ...g, rows: [...g.rows].sort((a, b) => a.sortWeight - b.sortWeight) }));
  }

  private stripSizeSuffix(name: string): string {
    let s = name.trim().replace(/\([^)]*\)/g, ' ').trim();
    let prev: string;
    do {
      prev = s;
      s = s.replace(SIZE_SUFFIX, '').trim();
    } while (s !== prev && s.length > 0);
    return s || name;
  }

  private toRow(p: any): DailyUpdateProduct {
    const unit = p.baseUnit || p.masterProduct?.baseUnit || '';
    const weight = p.baseWeight ?? p.masterProduct?.baseWeight ?? 0;
    return {
      id: p.id,
      name: p.displayName || p.customName || p.masterProduct?.name || 'Unnamed product',
      unitLabel: weight && unit ? `${weight} ${unit}` : (unit || ''),
      sortWeight: this.toGrams(unit, weight),
      imageUrl: p.primaryImageUrl,
      price: p.price,
      originalPrice: p.originalPrice ?? null,
      originalValues: {
        price: p.price,
        originalPrice: p.originalPrice ?? null
      }
    };
  }

  // Normalizes weight/volume to a common scale so 500g sorts before 1kg
  // regardless of which unit each variant happens to be stored in.
  private toGrams(unit: string, weight: number): number {
    const u = (unit || '').toLowerCase();
    if (u.startsWith('kg') || u.startsWith('l') || u === 'ltr' || u === 'litre') {
      return weight * 1000;
    }
    return weight;
  }

  get visibleGroups(): ProductGroup[] {
    return this.activeGroupKey
      ? this.groups.filter(g => g.key === this.activeGroupKey)
      : this.groups;
  }

  get showSuggestions(): boolean {
    return this.groups.length > 1;
  }

  selectGroup(key: string): void {
    this.activeGroupKey = this.activeGroupKey === key ? null : key;
  }

  clearList(): void {
    this.groups = [];
    this.modified.clear();
    this.activeGroupKey = null;
    this.hasSearched = false;
    this.aiKeywords = null;
  }

  // ---------- Editing ----------

  onPriceChange(row: DailyUpdateProduct, value: string, group: ProductGroup): void {
    const parsed = parseFloat(value);
    if (isNaN(parsed)) {
      return;
    }
    row.price = parsed;
    row.suggested = false;
    this.markModified(row);
    this.suggestSiblingPrices(group, row);
  }

  onBasePriceChange(row: DailyUpdateProduct, value: string): void {
    if (value === '') {
      row.originalPrice = null;
    } else {
      const parsed = parseFloat(value);
      row.originalPrice = isNaN(parsed) ? row.originalPrice : parsed;
    }
    this.markModified(row);
  }

  private markModified(row: DailyUpdateProduct): void {
    const changed = row.price !== row.originalValues.price
      || row.originalPrice !== row.originalValues.originalPrice;
    if (changed) {
      this.modified.set(row.id, row);
    } else {
      this.modified.delete(row.id);
    }
  }

  isModified(row: DailyUpdateProduct): boolean {
    return this.modified.has(row.id);
  }

  get modifiedCount(): number {
    return this.modified.size;
  }

  isValidPrice(value: number): boolean {
    return value !== undefined && value !== null && !isNaN(value) && value >= 0;
  }

  getProductImageUrl(imageUrl?: string): string {
    return (imageUrl && getImageUrlUtil(imageUrl)) || 'assets/images/product-placeholder.svg';
  }

  // "Was X -> Now Y" comparison shown next to an edited price so the owner
  // can confirm the change before saving.
  priceDelta(row: DailyUpdateProduct): number {
    return row.price - row.originalValues.price;
  }

  discardChanges(): void {
    this.modified.forEach(row => {
      row.price = row.originalValues.price;
      row.originalPrice = row.originalValues.originalPrice;
      row.suggested = false;
    });
    this.modified.clear();
  }

  async updateAll(): Promise<void> {
    if (this.modified.size === 0) {
      this.swalService.toast('No changes to update', 'info');
      return;
    }

    const invalid = Array.from(this.modified.values()).find(row =>
      !this.isValidPrice(row.price) || (row.originalPrice !== null && !this.isValidPrice(row.originalPrice)));
    if (invalid) {
      this.swalService.toast(`${invalid.name}: enter a valid price`, 'warning');
      return;
    }

    this.saving = true;
    const rows = Array.from(this.modified.values());

    const results = await Promise.all(rows.map(row =>
      this.http.patch(`${this.apiUrl}/shop-products/${row.id}/quick-update`, {
        price: row.price,
        originalPrice: row.originalPrice
      }).toPromise()
        .then(() => {
          row.originalValues = { price: row.price, originalPrice: row.originalPrice };
          row.suggested = false;
          this.modified.delete(row.id);
          return true;
        })
        .catch(() => false)
    ));

    this.saving = false;
    const successCount = results.filter(Boolean).length;
    const errorCount = results.length - successCount;

    if (errorCount === 0) {
      this.swalService.toast(`${successCount} product(s) updated`, 'success');
    } else {
      this.swalService.toast(`Updated ${successCount}, failed ${errorCount}`, 'warning');
    }
  }
}
