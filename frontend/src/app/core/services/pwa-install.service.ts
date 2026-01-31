import { Injectable, ApplicationRef } from '@angular/core';
import { BehaviorSubject, interval, concat } from 'rxjs';
import { first } from 'rxjs/operators';
import { SwUpdate, VersionReadyEvent } from '@angular/service-worker';

@Injectable({
  providedIn: 'root'
})
export class PwaInstallService {
  private deferredPrompt: any = null;
  private installableSubject = new BehaviorSubject<boolean>(false);
  private installedSubject = new BehaviorSubject<boolean>(false);
  private updateAvailableSubject = new BehaviorSubject<boolean>(false);

  isInstallable$ = this.installableSubject.asObservable();
  isInstalled$ = this.installedSubject.asObservable();
  updateAvailable$ = this.updateAvailableSubject.asObservable();

  constructor(private swUpdate: SwUpdate, private appRef: ApplicationRef) {
    this.initPwaPrompt();
    this.checkIfInstalled();
    this.initAutoUpdate();
  }

  /**
   * Initialize automatic update checking and reload
   */
  private initAutoUpdate(): void {
    if (!this.swUpdate.isEnabled) {
      console.log('Service Worker not enabled');
      return;
    }

    // Listen for version updates
    this.swUpdate.versionUpdates.subscribe(event => {
      if (event.type === 'VERSION_READY') {
        console.log('New version available:', (event as VersionReadyEvent).latestVersion);
        this.updateAvailableSubject.next(true);

        // Auto-reload to get new version
        this.activateUpdate();
      }
    });

    // Check for updates immediately after app is stable
    const appIsStable$ = this.appRef.isStable.pipe(first(isStable => isStable === true));
    concat(appIsStable$, interval(60000)).subscribe(() => {
      if (this.swUpdate.isEnabled) {
        this.swUpdate.checkForUpdate()
          .then(() => console.log('Checked for SW updates'))
          .catch(err => console.warn('SW update check failed:', err));
      }
    });
  }

  /**
   * Activate update and reload the page
   */
  async activateUpdate(): Promise<void> {
    if (!this.swUpdate.isEnabled) return;

    try {
      await this.swUpdate.activateUpdate();
      console.log('Update activated, reloading...');

      // Clear caches before reload
      if ('caches' in window) {
        const cacheNames = await caches.keys();
        await Promise.all(cacheNames.map(name => caches.delete(name)));
      }

      // Force reload
      window.location.reload();
    } catch (err) {
      console.error('Failed to activate update:', err);
      // Force reload anyway
      window.location.reload();
    }
  }

  /**
   * Force check for updates (can be called manually)
   */
  async checkForUpdate(): Promise<boolean> {
    if (!this.swUpdate.isEnabled) return false;

    try {
      const hasUpdate = await this.swUpdate.checkForUpdate();
      if (hasUpdate) {
        this.updateAvailableSubject.next(true);
      }
      return hasUpdate;
    } catch (err) {
      console.warn('Update check failed:', err);
      return false;
    }
  }

  private initPwaPrompt(): void {
    // Listen for the beforeinstallprompt event
    window.addEventListener('beforeinstallprompt', (e: Event) => {
      e.preventDefault();
      this.deferredPrompt = e;
      this.installableSubject.next(true);
      console.log('PWA install prompt available');
    });

    // Listen for successful installation
    window.addEventListener('appinstalled', () => {
      this.deferredPrompt = null;
      this.installableSubject.next(false);
      this.installedSubject.next(true);
      console.log('PWA installed successfully');

      // Store installation status
      localStorage.setItem('pwa_installed', 'true');
    });
  }

  private checkIfInstalled(): void {
    // Check if running in standalone mode (installed PWA)
    const isStandalone = window.matchMedia('(display-mode: standalone)').matches
      || (window.navigator as any).standalone
      || document.referrer.includes('android-app://');

    if (isStandalone) {
      this.installedSubject.next(true);
      this.installableSubject.next(false);
    }
  }

  async promptInstall(): Promise<boolean> {
    if (!this.deferredPrompt) {
      console.log('No install prompt available');
      return false;
    }

    // Show the install prompt
    this.deferredPrompt.prompt();

    // Wait for the user to respond
    const { outcome } = await this.deferredPrompt.userChoice;
    console.log('User response to install prompt:', outcome);

    // Clear the deferred prompt
    this.deferredPrompt = null;
    this.installableSubject.next(false);

    return outcome === 'accepted';
  }

  dismissInstallBanner(): void {
    // Store dismissal with timestamp (show again after 7 days)
    localStorage.setItem('pwa_banner_dismissed', Date.now().toString());
  }

  shouldShowBanner(): boolean {
    // Don't show if already installed
    if (localStorage.getItem('pwa_installed') === 'true') {
      return false;
    }

    // Check if dismissed recently (within 7 days)
    const dismissedAt = localStorage.getItem('pwa_banner_dismissed');
    if (dismissedAt) {
      const sevenDays = 7 * 24 * 60 * 60 * 1000;
      if (Date.now() - parseInt(dismissedAt, 10) < sevenDays) {
        return false;
      }
    }

    return true;
  }
}
