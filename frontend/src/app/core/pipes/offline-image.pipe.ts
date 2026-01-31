import { Pipe, PipeTransform, OnDestroy } from '@angular/core';
import { OfflineStorageService } from '../services/offline-storage.service';
import { getImageUrl } from '../utils/image-url.util';

/**
 * Pipe that returns cached image URL when offline
 * Usage: [src]="product.imageUrl | offlineImage | async"
 *
 * When online: Returns the original URL
 * When offline: Returns a blob URL from IndexedDB cache
 */
@Pipe({
  name: 'offlineImage',
  pure: false  // Must be impure to react to online/offline changes
})
export class OfflineImagePipe implements PipeTransform, OnDestroy {
  private cachedUrls = new Map<string, string>();
  private pendingPromises = new Map<string, Promise<string>>();

  constructor(private offlineStorage: OfflineStorageService) {}

  transform(imageUrl: string | null | undefined, placeholder: string = 'assets/images/product-placeholder.svg'): Promise<string> {
    if (!imageUrl) {
      return Promise.resolve(placeholder);
    }

    const fullUrl = getImageUrl(imageUrl);
    if (!fullUrl) {
      return Promise.resolve(placeholder);
    }

    // If online, just return the URL
    if (navigator.onLine) {
      return Promise.resolve(fullUrl);
    }

    // If we already have a cached blob URL, return it
    if (this.cachedUrls.has(fullUrl)) {
      return Promise.resolve(this.cachedUrls.get(fullUrl)!);
    }

    // If there's already a pending promise for this URL, return it
    if (this.pendingPromises.has(fullUrl)) {
      return this.pendingPromises.get(fullUrl)!;
    }

    // Create a new promise to fetch from cache
    const promise = this.getFromCache(fullUrl, placeholder);
    this.pendingPromises.set(fullUrl, promise);

    return promise;
  }

  private async getFromCache(fullUrl: string, placeholder: string): Promise<string> {
    try {
      const blob = await this.offlineStorage.getCachedImage(fullUrl);
      if (blob) {
        const blobUrl = URL.createObjectURL(blob);
        this.cachedUrls.set(fullUrl, blobUrl);
        this.pendingPromises.delete(fullUrl);
        return blobUrl;
      }
    } catch (error) {
      console.warn('Error getting cached image:', error);
    }

    this.pendingPromises.delete(fullUrl);
    return placeholder;
  }

  ngOnDestroy(): void {
    // Revoke all blob URLs to free memory
    this.cachedUrls.forEach(blobUrl => {
      URL.revokeObjectURL(blobUrl);
    });
    this.cachedUrls.clear();
    this.pendingPromises.clear();
  }
}
