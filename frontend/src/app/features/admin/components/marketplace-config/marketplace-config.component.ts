import { Component, OnInit } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { SettingsService } from '../../../../core/services/settings.service';

interface PostTypeConfig {
  key: string;
  prefix: string;
  label: string;
  icon: string;
  color: string;
  durationDays: number;
  autoApprove: boolean;
  visibleStatuses: string[];
  reportThreshold: number;
}

@Component({
  selector: 'app-marketplace-config',
  templateUrl: './marketplace-config.component.html',
  styleUrls: ['./marketplace-config.component.scss']
})
export class MarketplaceConfigComponent implements OnInit {
  loading = false;
  savingType: string | null = null;
  selectedTabIndex = 0;

  // Paid post config
  paidPostEnabled = false;
  paidPostSaving = false;
  savingPrices = false;
  postTypePrices: { [key: string]: number } = {};

  postTypes: PostTypeConfig[] = [
    { key: 'MARKETPLACE', prefix: 'marketplace', label: 'Marketplace', icon: 'storefront', color: '#4527A0', durationDays: 30, autoApprove: false, visibleStatuses: ['APPROVED'], reportThreshold: 3 },
    { key: 'FARM_PRODUCTS', prefix: 'farmer', label: 'Farmer Products', icon: 'agriculture', color: '#33691E', durationDays: 30, autoApprove: false, visibleStatuses: ['APPROVED'], reportThreshold: 3 },
    { key: 'LABOURS', prefix: 'labour', label: 'Labours', icon: 'engineering', color: '#1565C0', durationDays: 30, autoApprove: false, visibleStatuses: ['APPROVED'], reportThreshold: 3 },
    { key: 'TRAVELS', prefix: 'travel', label: 'Travels', icon: 'directions_car', color: '#00897B', durationDays: 30, autoApprove: false, visibleStatuses: ['APPROVED'], reportThreshold: 3 },
    { key: 'PARCEL_SERVICE', prefix: 'parcel', label: 'Packers & Movers', icon: 'local_shipping', color: '#E65100', durationDays: 30, autoApprove: false, visibleStatuses: ['APPROVED'], reportThreshold: 3 },
    { key: 'REAL_ESTATE', prefix: 'realestate', label: 'Real Estate', icon: 'apartment', color: '#AD1457', durationDays: 30, autoApprove: false, visibleStatuses: ['APPROVED'], reportThreshold: 3 },
    { key: 'RENTAL', prefix: 'rental', label: 'Rentals', icon: 'vpn_key', color: '#FF6F00', durationDays: 30, autoApprove: false, visibleStatuses: ['APPROVED'], reportThreshold: 3 },
  ];

  durationOptions = [
    { label: '1 Month', value: 30 },
    { label: '2 Months', value: 60 },
    { label: '3 Months', value: 90 },
    { label: '6 Months', value: 180 },
    { label: '1 Year', value: 365 },
    { label: 'No Expiry', value: 0 }
  ];

  allStatuses = ['APPROVED', 'PENDING_APPROVAL', 'SOLD', 'FLAGGED', 'HOLD', 'HIDDEN', 'CORRECTION_REQUIRED'];

  statusLabels: { [key: string]: string } = {
    'APPROVED': 'Approved',
    'PENDING_APPROVAL': 'Pending Approval',
    'SOLD': 'Sold',
    'FLAGGED': 'Flagged',
    'HOLD': 'Hold',
    'HIDDEN': 'Hidden',
    'CORRECTION_REQUIRED': 'Correction Required'
  };

  constructor(
    private settingsService: SettingsService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadAllSettings();
  }

  loadAllSettings(): void {
    this.loading = true;

    this.settingsService.getAllSettings().subscribe({
      next: (settings) => {
        for (const s of settings) {
          if (s.key === 'paid_post.enabled') this.paidPostEnabled = s.value === 'true';

          const pricePrefix = 'paid_post.price.';
          if (s.key.startsWith(pricePrefix)) {
            const postType = s.key.substring(pricePrefix.length);
            this.postTypePrices[postType] = parseInt(s.value, 10) || 10;
          }
          if (s.key === 'paid_post.price') {
            const fallback = parseInt(s.value, 10) || 10;
            for (const pt of this.postTypes) {
              if (this.postTypePrices[pt.key] === undefined) {
                this.postTypePrices[pt.key] = fallback;
              }
            }
          }

          for (const pt of this.postTypes) {
            if (s.key === `${pt.prefix}.post.duration_days`) pt.durationDays = parseInt(s.value, 10) || 30;
            if (s.key === `${pt.prefix}.post.auto_approve`) pt.autoApprove = s.value === 'true';
            if (s.key === `${pt.prefix}.post.visible_statuses`) {
              try { pt.visibleStatuses = JSON.parse(s.value); } catch { pt.visibleStatuses = ['APPROVED']; }
            }
            if (s.key === `${pt.prefix}.post.report_threshold`) pt.reportThreshold = parseInt(s.value, 10) || 3;
          }
        }

        for (const pt of this.postTypes) {
          if (this.postTypePrices[pt.key] === undefined) {
            this.postTypePrices[pt.key] = 10;
          }
        }

        this.loading = false;
      },
      error: () => {
        this.snackBar.open('Failed to load settings', 'OK', { duration: 3000 });
        this.loading = false;
      }
    });
  }

  isStatusChecked(pt: PostTypeConfig, status: string): boolean {
    return pt.visibleStatuses.includes(status);
  }

  toggleStatus(pt: PostTypeConfig, status: string): void {
    const idx = pt.visibleStatuses.indexOf(status);
    if (idx >= 0) {
      if (pt.visibleStatuses.length > 1) {
        pt.visibleStatuses.splice(idx, 1);
      } else {
        this.snackBar.open('At least one status must be selected', 'OK', { duration: 3000 });
      }
    } else {
      pt.visibleStatuses.push(status);
    }
  }

  savePostTypeSettings(pt: PostTypeConfig): void {
    this.savingType = pt.key;
    const settings: { [key: string]: string } = {
      [`${pt.prefix}.post.duration_days`]: String(pt.durationDays),
      [`${pt.prefix}.post.auto_approve`]: String(pt.autoApprove),
      [`${pt.prefix}.post.visible_statuses`]: JSON.stringify(pt.visibleStatuses),
      [`${pt.prefix}.post.report_threshold`]: String(pt.reportThreshold)
    };

    this.settingsService.updateMultipleSettings(settings).subscribe({
      next: () => {
        this.savingType = null;
        this.snackBar.open(`${pt.label} settings saved`, 'OK', { duration: 3000 });
      },
      error: () => {
        this.savingType = null;
        this.snackBar.open(`Failed to save ${pt.label} settings`, 'OK', { duration: 3000 });
      }
    });
  }

  savePaidPostConfig(): void {
    this.paidPostSaving = true;
    const settings: { [key: string]: string } = {
      'paid_post.enabled': String(this.paidPostEnabled)
    };

    this.settingsService.updateMultipleSettings(settings).subscribe({
      next: () => {
        this.paidPostSaving = false;
        this.snackBar.open('Paid post config saved', 'OK', { duration: 3000 });
      },
      error: () => {
        this.paidPostSaving = false;
        this.snackBar.open('Failed to save config', 'OK', { duration: 3000 });
      }
    });
  }

  saveAllPrices(): void {
    this.savingPrices = true;
    const settings: { [key: string]: string } = {};
    for (const pt of this.postTypes) {
      settings[`paid_post.price.${pt.key}`] = String(this.postTypePrices[pt.key] || 10);
    }

    this.settingsService.updateMultipleSettings(settings).subscribe({
      next: () => {
        this.savingPrices = false;
        this.snackBar.open('Prices saved successfully', 'OK', { duration: 3000 });
      },
      error: () => {
        this.savingPrices = false;
        this.snackBar.open('Failed to save prices', 'OK', { duration: 3000 });
      }
    });
  }
}
