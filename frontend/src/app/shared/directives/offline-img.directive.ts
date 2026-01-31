import { Directive, Input, ElementRef, OnInit, OnDestroy, OnChanges, SimpleChanges } from '@angular/core';
import { OfflineStorageService } from '../../core/services/offline-storage.service';
import { getImageUrl } from '../../core/utils/image-url.util';

/**
 * Directive that handles offline image loading
 * When offline, it loads images from IndexedDB cache
 *
 * Usage:
 * <img [appOfflineImg]="product.imageUrl" [fallback]="'assets/placeholder.svg'">
 */
@Directive({
  selector: '[appOfflineImg]'
})
export class OfflineImgDirective implements OnInit, OnDestroy, OnChanges {
  @Input('appOfflineImg') imageUrl: string | null | undefined;
  @Input() fallback: string = 'assets/images/product-placeholder.svg';

  private blobUrl: string | null = null;
  private isLoading = false;
  private onlineHandler: () => void;
  private offlineHandler: () => void;

  constructor(
    private el: ElementRef<HTMLImageElement>,
    private offlineStorage: OfflineStorageService
  ) {
    this.onlineHandler = () => this.loadImage();
    this.offlineHandler = () => this.loadImage();
  }

  ngOnInit(): void {
    // Listen for online/offline events
    window.addEventListener('online', this.onlineHandler);
    window.addEventListener('offline', this.offlineHandler);

    this.loadImage();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['imageUrl'] && !changes['imageUrl'].firstChange) {
      this.cleanupBlobUrl();
      this.loadImage();
    }
  }

  ngOnDestroy(): void {
    window.removeEventListener('online', this.onlineHandler);
    window.removeEventListener('offline', this.offlineHandler);
    this.cleanupBlobUrl();
  }

  private async loadImage(): Promise<void> {
    if (this.isLoading) return;
    this.isLoading = true;

    try {
      if (!this.imageUrl) {
        this.setSource(this.fallback);
        return;
      }

      const fullUrl = getImageUrl(this.imageUrl);
      if (!fullUrl) {
        this.setSource(this.fallback);
        return;
      }

      // If online, just use the URL directly
      if (navigator.onLine) {
        this.setSource(fullUrl);
        return;
      }

      // If offline, try to load from cache
      const blob = await this.offlineStorage.getCachedImage(fullUrl);
      if (blob) {
        this.cleanupBlobUrl();
        this.blobUrl = URL.createObjectURL(blob);
        this.setSource(this.blobUrl);
      } else {
        // No cached image, use fallback
        this.setSource(this.fallback);
      }
    } catch (error) {
      console.warn('Error loading offline image:', error);
      this.setSource(this.fallback);
    } finally {
      this.isLoading = false;
    }
  }

  private setSource(src: string): void {
    if (this.el.nativeElement) {
      this.el.nativeElement.src = src;
    }
  }

  private cleanupBlobUrl(): void {
    if (this.blobUrl) {
      URL.revokeObjectURL(this.blobUrl);
      this.blobUrl = null;
    }
  }
}
