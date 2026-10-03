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

        // Auto-reload to get new version — but never in the middle of a payment
        this.scheduleActivate();
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

  // ===== Reload deferral: a forced reload mid-checkout can take the user's money
  // without ever running the verify step, so updates wait for payments to finish. =====
  private static reloadBlocks = 0;

  /** Call when entering a flow a reload must not interrupt (Razorpay checkout etc). */
  static beginCriticalFlow(): void {
    PwaInstallService.reloadBlocks++;
  }

  static endCriticalFlow(): void {
    PwaInstallService.reloadBlocks = Math.max(0, PwaInstallService.reloadBlocks - 1);
  }

  // Last user interaction (touch/key/pointer). A new version must never reload
  // the page while someone is actively working — shop owners saw POS refresh
  // mid-billing after every deploy. Reload only when the tab is hidden or idle.
  private static lastActivity = Date.now();
  private static activityHooked = false;
  private static readonly IDLE_BEFORE_RELOAD_MS = 3 * 60 * 1000;
  private static hookActivity(): void {
    if (PwaInstallService.activityHooked || typeof document === 'undefined') return;
    PwaInstallService.activityHooked = true;
    const mark = () => { PwaInstallService.lastActivity = Date.now(); };
    ['keydown', 'pointerdown', 'touchstart', 'wheel'].forEach(ev => document.addEventListener(ev, mark, { passive: true, capture: true }));
  }

  /** True while the in-progress POS bill has items (persisted by the POS page). */
  private static posBillInProgress(): boolean {
    try {
      if (!location.pathname.includes('pos')) return false;
      const raw = localStorage.getItem('pos_cart_backup');
      if (!raw) return false;
      const parsed = JSON.parse(raw);
      const items = Array.isArray(parsed) ? parsed : (parsed?.cart || parsed?.items || []);
      return Array.isArray(items) && items.length > 0;
    } catch { return false; }
  }

  private static reloadBlocked(): boolean {
    PwaInstallService.hookActivity();
    // The DOM check is a safety net for any checkout path that forgot to register
    if (PwaInstallService.reloadBlocks > 0
      || !!document.querySelector('.razorpay-container, .razorpay-checkout-frame')) return true;
    if (PwaInstallService.posBillInProgress()) return true;
    // Visible and recently used: wait. Hidden tab or idle for a while: ok to reload.
    const visible = typeof document !== 'undefined' && document.visibilityState === 'visible';
    const idleMs = Date.now() - PwaInstallService.lastActivity;
    return visible && idleMs < PwaInstallService.IDLE_BEFORE_RELOAD_MS;
  }

  private scheduleActivate(): void {
    if (!PwaInstallService.reloadBlocked()) {
      this.activateUpdate();
      return;
    }
    console.log('Update ready but the user is busy (payment, open bill, or active) — deferring reload until idle/hidden');
    const timer = setInterval(() => {
      if (!PwaInstallService.reloadBlocked()) {
        clearInterval(timer);
        this.activateUpdate();
      }
    }, 15000);
    // Also take the first chance when the tab goes to the background
    const onHide = () => { if (document.visibilityState !== 'visible' && !PwaInstallService.reloadBlocked()) { document.removeEventListener('visibilitychange', onHide); clearInterval(timer); this.activateUpdate(); } };
    document.addEventListener('visibilitychange', onHide);
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
