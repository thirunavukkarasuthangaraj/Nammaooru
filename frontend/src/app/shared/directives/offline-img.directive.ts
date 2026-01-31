import { Directive, Input, ElementRef, OnInit, OnChanges, SimpleChanges, HostListener } from '@angular/core';
import { getImageUrl } from '../../core/utils/image-url.util';

/**
 * Simple directive for offline-friendly images
 * - Converts image paths to full URLs
 * - Shows fallback on error (offline or missing image)
 * - Service Worker handles actual caching (ngsw-config.json)
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

  constructor(private el: ElementRef<HTMLImageElement>) {}

  ngOnInit(): void {
    this.updateImage();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['imageUrl']) {
      this.hasError = false;
      this.updateImage();
    }
  }

  @HostListener('error')
  onError(): void {
    if (!this.hasError) {
      this.hasError = true;
      this.el.nativeElement.src = this.fallback;
    }
  }

  private updateImage(): void {
    if (!this.imageUrl) {
      this.el.nativeElement.src = this.fallback;
      return;
    }

    // If already a data URL or blob URL, use directly
    if (this.imageUrl.startsWith('data:') || this.imageUrl.startsWith('blob:')) {
      this.el.nativeElement.src = this.imageUrl;
      return;
    }

    // Convert to full URL and let Service Worker handle caching
    const fullUrl = getImageUrl(this.imageUrl);
    this.el.nativeElement.src = fullUrl || this.fallback;
  }
}
