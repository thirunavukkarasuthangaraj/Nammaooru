import { Directive, Input, ElementRef, OnInit, OnChanges, SimpleChanges, HostListener } from '@angular/core';
import { OfflineStorageService } from '../../core/services/offline-storage.service';
import { getImageUrl } from '../../core/utils/image-url.util';

/**
 * Directive for offline-friendly images
 * - Loads from IndexedDB cache when available
 * - Falls back to network if not cached
 * - Shows fallback on error
 *
 * Usage:
 * <img [appOfflineImg]="product.imageUrl" [fallback]="'assets/placeholder.svg'">
 */
@Directive({
  selector: '[appOfflineImg]'
})
export class OfflineImgDirective implements OnInit, OnChanges {
  @Input('appOfflineImg') imageUrl: string | null | undefined;
  @Input() fallback: string = 'assets/images/product-placeholder.svg';

  private hasError = false;
  private blobUrl: string | null = null;

  constructor(
    private el: ElementRef<HTMLImageElement>,
    private offlineStorage: OfflineStorageService
  ) {}

  ngOnInit(): void {
    this.loadImage();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['imageUrl']) {
      this.hasError = false;
      this.cleanupBlobUrl();
      this.loadImage();
    }
  }

  @HostListener('error')
  onError(): void {
    if (!this.hasError) {
      this.hasError = true;
      this.el.nativeElement.src = this.fallback;
    }
  }

  private async loadImage(): Promise<void> {
    if (!this.imageUrl) {
      this.el.nativeElement.src = this.fallback;
      return;
    }

    // If already a data URL or blob URL, use directly
    if (this.imageUrl.startsWith('data:') || this.imageUrl.startsWith('blob:')) {
      this.el.nativeElement.src = this.imageUrl;
      return;
    }

    const fullUrl = getImageUrl(this.imageUrl);
    if (!fullUrl) {
      this.el.nativeElement.src = this.fallback;
      return;
    }

    // Try to load from IndexedDB cache first
    try {
      const cachedBlob = await this.offlineStorage.getCachedImage(fullUrl);
      if (cachedBlob) {
        this.cleanupBlobUrl();
        this.blobUrl = URL.createObjectURL(cachedBlob);
        this.el.nativeElement.src = this.blobUrl;
        return;
      }
    } catch (err) {
      // Cache lookup failed, fall through to network
    }

    // Not in cache - load from network (Service Worker will cache it)
    this.el.nativeElement.src = fullUrl;
  }

  private cleanupBlobUrl(): void {
    if (this.blobUrl) {
      URL.revokeObjectURL(this.blobUrl);
      this.blobUrl = null;
    }
  }

  ngOnDestroy(): void {
    this.cleanupBlobUrl();
  }
}
