import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';

declare var google: any;

/**
 * Loads the Google Maps JavaScript API at runtime with a key fetched from the
 * backend (Admin > Settings: google.maps.browser_key). The key is no longer in
 * the website source; it is still visible to browsers, so keep it restricted to
 * this site's HTTP referrers in Google Cloud Console.
 */
@Injectable({ providedIn: 'root' })
export class MapsLoaderService {
  private loading: Promise<boolean> | null = null;

  constructor(private http: HttpClient) {}

  /** Resolves true once google.maps is available, false if no key is configured. */
  load(): Promise<boolean> {
    if (typeof google !== 'undefined' && google.maps) return Promise.resolve(true);
    if (this.loading) return this.loading;
    this.loading = new Promise<boolean>((resolve) => {
      this.http.get<any>(`${environment.apiUrl}/transport/public/maps-key`, { params: { silentError: '1' } }).subscribe({
        next: (res) => {
          const data = res?.data || res || {};
          const key = (data.key || '').trim();
          if (!key) { console.warn('[maps] No Google Maps key configured (Admin > Settings > google.maps.browser_key)'); resolve(false); return; }
          const libs = data.libraries || 'places,geometry';
          const s = document.createElement('script');
          s.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(key)}&libraries=${encodeURIComponent(libs)}&loading=async`;
          s.async = true;
          s.defer = true;
          s.onload = () => {
            // With loading=async the namespace may land a tick later
            const wait = (): void => {
              if (typeof google !== 'undefined' && google.maps) { resolve(true); return; }
              setTimeout(wait, 50);
            };
            wait();
          };
          s.onerror = () => { console.error('[maps] Google Maps script failed to load'); resolve(false); };
          document.head.appendChild(s);
        },
        error: () => { console.warn('[maps] Could not fetch Google Maps key'); resolve(false); }
      });
    });
    return this.loading;
  }
}

/** APP_INITIALIZER factory: start loading early, never block app start. */
export function startMapsLoader(loader: MapsLoaderService) {
  return () => { loader.load().catch(() => {}); return Promise.resolve(); };
}
