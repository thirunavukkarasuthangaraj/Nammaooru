import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subscription } from 'rxjs';
import { PwaInstallService } from '../../../core/services/pwa-install.service';

@Component({
  selector: 'app-pwa-install-banner',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="pwa-install-banner" *ngIf="showBanner">
      <div class="banner-content">
        <div class="app-icon">
          <span class="icon-text">N</span>
        </div>
        <div class="banner-text">
          <h4>Install NammaOoru App</h4>
          <p>Add to your desktop for quick access</p>
        </div>
        <div class="banner-actions">
          <button class="btn-dismiss" (click)="dismiss()">Not now</button>
          <button class="btn-install" (click)="install()">
            <span class="install-icon">+</span>
            Install
          </button>
        </div>
      </div>
    </div>

    <!-- Manual install banner when automatic prompt doesn't appear -->
    <div class="pwa-install-banner" *ngIf="showManualInstall && !showBanner">
      <div class="banner-content">
        <div class="app-icon">
          <span class="icon-text">N</span>
        </div>
        <div class="banner-text">
          <h4>Install NammaOoru App</h4>
          <p>Click the <strong>install icon</strong> in your browser's address bar</p>
        </div>
        <div class="banner-actions">
          <button class="btn-dismiss" (click)="dismissManual()">Got it</button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .pwa-install-banner {
      position: fixed;
      bottom: 20px;
      left: 50%;
      transform: translateX(-50%);
      background: white;
      border-radius: 12px;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15), 0 0 0 1px rgba(0, 0, 0, 0.05);
      padding: 16px 20px;
      z-index: 10000;
      max-width: 420px;
      width: calc(100% - 32px);
      animation: slideUp 0.3s ease-out;
    }

    @keyframes slideUp {
      from {
        opacity: 0;
        transform: translateX(-50%) translateY(20px);
      }
      to {
        opacity: 1;
        transform: translateX(-50%) translateY(0);
      }
    }

    .banner-content {
      display: flex;
      align-items: center;
      gap: 14px;
    }

    .app-icon {
      width: 48px;
      height: 48px;
      border-radius: 10px;
      overflow: hidden;
      flex-shrink: 0;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      background: linear-gradient(135deg, #f97316 0%, #ea580c 100%);
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .icon-text {
      font-size: 24px;
      font-weight: 700;
      color: white;
    }

    .banner-text {
      flex: 1;
      min-width: 0;
    }

    .banner-text h4 {
      margin: 0 0 2px 0;
      font-size: 15px;
      font-weight: 600;
      color: #1a1a1a;
    }

    .banner-text p {
      margin: 0;
      font-size: 13px;
      color: #666;
    }

    .banner-actions {
      display: flex;
      gap: 8px;
      flex-shrink: 0;
    }

    .btn-dismiss {
      padding: 8px 14px;
      border: none;
      background: transparent;
      color: #666;
      font-size: 13px;
      font-weight: 500;
      cursor: pointer;
      border-radius: 6px;
      transition: background 0.2s;
    }

    .btn-dismiss:hover {
      background: #f5f5f5;
    }

    .btn-install {
      padding: 8px 16px;
      border: none;
      background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
      color: white;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      border-radius: 6px;
      display: flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s;
      box-shadow: 0 2px 8px rgba(37, 99, 235, 0.3);
    }

    .btn-install:hover {
      transform: translateY(-1px);
      box-shadow: 0 4px 12px rgba(37, 99, 235, 0.4);
    }

    .install-icon {
      font-size: 16px;
      font-weight: bold;
    }

    @media (max-width: 480px) {
      .pwa-install-banner {
        bottom: 16px;
        padding: 14px 16px;
      }

      .banner-content {
        flex-wrap: wrap;
      }

      .banner-text {
        flex: 1 1 calc(100% - 62px);
      }

      .banner-actions {
        width: 100%;
        justify-content: flex-end;
        margin-top: 10px;
      }
    }
  `]
})
export class PwaInstallBannerComponent implements OnInit, OnDestroy {
  showBanner = false;
  showManualInstall = false;
  isChrome = false;
  private subscriptions: Subscription[] = [];

  constructor(private pwaService: PwaInstallService) {}

  ngOnInit(): void {
    // Check if Chrome browser
    this.isChrome = /Chrome/.test(navigator.userAgent) && !/Edge|Edg/.test(navigator.userAgent);

    // Check if should show banner
    if (!this.pwaService.shouldShowBanner()) {
      return;
    }

    // Subscribe to installable status
    const sub = this.pwaService.isInstallable$.subscribe(installable => {
      this.showBanner = installable && this.pwaService.shouldShowBanner();
    });
    this.subscriptions.push(sub);

    // Show manual install option after 2 seconds if automatic banner doesn't appear
    setTimeout(() => {
      if (!this.showBanner && this.isChrome && this.pwaService.shouldShowBanner()) {
        // Check if not in standalone mode (not already installed)
        const isStandalone = window.matchMedia('(display-mode: standalone)').matches;
        if (!isStandalone) {
          this.showManualInstall = true;
        }
      }
    }, 2000);
  }

  ngOnDestroy(): void {
    this.subscriptions.forEach(sub => sub.unsubscribe());
  }

  async install(): Promise<void> {
    const installed = await this.pwaService.promptInstall();
    if (installed) {
      this.showBanner = false;
    }
  }

  dismiss(): void {
    this.showBanner = false;
    this.pwaService.dismissInstallBanner();
  }

  dismissManual(): void {
    this.showManualInstall = false;
    this.pwaService.dismissInstallBanner();
  }
}
