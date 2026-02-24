import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { PostLimitsService, UserPostLimit } from '../../services/post-limits.service';
import { FeatureConfigService, FeatureConfig } from '../../services/feature-config.service';
import { SettingsService } from '../../../../core/services/settings.service';

@Component({
  selector: 'app-post-limits',
  templateUrl: './post-limits.component.html',
  styleUrls: ['./post-limits.component.scss']
})
export class PostLimitsComponent implements OnInit {
  // Service area restriction
  serviceAreaEnabled = false;
  serviceAreaLat = 12.4955;
  serviceAreaLng = 78.5514;
  serviceAreaRadius = 50;
  serviceAreaLoading = true;
  serviceAreaSaving = false;

  // Global free post limit
  globalFreePostLimit: number = 1;
  globalFreePostLimitLoading = true;
  globalFreePostLimitSaving = false;

  // Global limits
  globalLimits: FeatureConfig[] = [];
  globalLoading = true;
  editingGlobalId: number | null = null;
  editGlobalValue: number = 0;

  // User-specific overrides
  limits: UserPostLimit[] = [];
  isLoading = true;
  showForm = false;
  limitForm!: FormGroup;
  lookupResult: any = null;
  lookupError: string = '';
  lookupLoading = false;

  featureNames = [
    { value: 'PARCEL_SERVICE', label: 'Packers & Movers' },
    { value: 'MARKETPLACE', label: 'Marketplace' },
    { value: 'LABOURS', label: 'Labours' },
    { value: 'FARM_PRODUCTS', label: 'Farm Products' },
    { value: 'TRAVELS', label: 'Travels' },
    { value: 'RENTAL', label: 'Rentals' },
    { value: 'REAL_ESTATE', label: 'Real Estate' },
    { value: 'WOMENS_CORNER', label: "Women's Corner" }
  ];

  // Paid post config
  paidPostEnabled = false;
  paidPostCurrency = 'INR';
  paidPostLoading = true;
  paidPostSaving = false;

  // Post Type Settings (duration, auto-approve, etc.)
  selectedTabIndex = 0;
  savingType: string | null = null;
  typeSettingsLoading = false;
  postTypeConfigs: { key: string; prefix: string; label: string; icon: string; color: string; durationDays: number; autoApprove: boolean; visibleStatuses: string[]; reportThreshold: number }[] = [
    { key: 'MARKETPLACE', prefix: 'marketplace', label: 'Marketplace', icon: 'storefront', color: '#4527A0', durationDays: 30, autoApprove: false, visibleStatuses: ['APPROVED'], reportThreshold: 3 },
    { key: 'FARM_PRODUCTS', prefix: 'farmer', label: 'Farmer Products', icon: 'agriculture', color: '#33691E', durationDays: 30, autoApprove: false, visibleStatuses: ['APPROVED'], reportThreshold: 3 },
    { key: 'LABOURS', prefix: 'labour', label: 'Labours', icon: 'engineering', color: '#1565C0', durationDays: 30, autoApprove: false, visibleStatuses: ['APPROVED'], reportThreshold: 3 },
    { key: 'TRAVELS', prefix: 'travel', label: 'Travels', icon: 'directions_car', color: '#00897B', durationDays: 30, autoApprove: false, visibleStatuses: ['APPROVED'], reportThreshold: 3 },
    { key: 'PARCEL_SERVICE', prefix: 'parcel', label: 'Packers & Movers', icon: 'local_shipping', color: '#E65100', durationDays: 30, autoApprove: false, visibleStatuses: ['APPROVED'], reportThreshold: 3 },
    { key: 'REAL_ESTATE', prefix: 'realestate', label: 'Real Estate', icon: 'apartment', color: '#AD1457', durationDays: 30, autoApprove: false, visibleStatuses: ['APPROVED'], reportThreshold: 3 },
    { key: 'RENTAL', prefix: 'rental', label: 'Rentals', icon: 'vpn_key', color: '#FF6F00', durationDays: 30, autoApprove: false, visibleStatuses: ['APPROVED'], reportThreshold: 3 },
    { key: 'WOMENS_CORNER', prefix: 'womens_corner', label: "Women's Corner", icon: 'auto_awesome', color: '#E91E63', durationDays: 30, autoApprove: true, visibleStatuses: ['APPROVED'], reportThreshold: 5 },
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
    'APPROVED': 'Approved', 'PENDING_APPROVAL': 'Pending Approval', 'SOLD': 'Sold',
    'FLAGGED': 'Flagged', 'HOLD': 'Hold', 'HIDDEN': 'Hidden', 'CORRECTION_REQUIRED': 'Correction Required'
  };

  // Per-type pricing
  postTypePrices: { [key: string]: number } = {};
  savingPrices = false;
  postTypes = [
    { key: 'MARKETPLACE', label: 'Marketplace (Buy & Sell)' },
    { key: 'FARM_PRODUCTS', label: 'Farmer Products' },
    { key: 'LABOURS', label: 'Labours' },
    { key: 'TRAVELS', label: 'Travels' },
    { key: 'PARCEL_SERVICE', label: 'Packers & Movers' },
    { key: 'REAL_ESTATE', label: 'Real Estate' },
    { key: 'RENTAL', label: 'Rentals' },
    { key: 'WOMENS_CORNER', label: "Women's Corner" },
  ];

  displayedColumns: string[] = ['userInfo', 'featureName', 'maxPosts', 'createdAt', 'actions'];
  globalDisplayedColumns: string[] = ['featureName', 'maxPosts', 'actions'];

  constructor(
    private postLimitsService: PostLimitsService,
    private featureConfigService: FeatureConfigService,
    private settingsService: SettingsService,
    private fb: FormBuilder,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.initForm();
    this.loadServiceAreaConfig();
    this.loadGlobalFreePostLimit();
    this.loadGlobalLimits();
    this.loadLimits();
    this.loadPaidPostConfig();
    this.loadPostTypeSettings();
  }

  initForm(): void {
    this.limitForm = this.fb.group({
      userIdentifier: ['', [Validators.required]],
      featureName: ['', Validators.required],
      maxPosts: [5, [Validators.required, Validators.min(0)]]
    });
  }

  // ===== Service Area Restriction =====

  loadServiceAreaConfig(): void {
    this.serviceAreaLoading = true;
    this.settingsService.getAllSettings().subscribe({
      next: (settings) => {
        for (const s of settings) {
          if (s.key === 'service.area.enabled') this.serviceAreaEnabled = s.value === 'true';
          if (s.key === 'service.area.center.latitude') this.serviceAreaLat = parseFloat(s.value) || 12.4955;
          if (s.key === 'service.area.center.longitude') this.serviceAreaLng = parseFloat(s.value) || 78.5514;
          if (s.key === 'service.area.radius.km') this.serviceAreaRadius = parseInt(s.value, 10) || 50;
        }
        this.serviceAreaLoading = false;
      },
      error: () => {
        this.snackBar.open('Failed to load service area config', 'Close', { duration: 3000 });
        this.serviceAreaLoading = false;
      }
    });
  }

  saveServiceAreaConfig(): void {
    this.serviceAreaSaving = true;
    const settings: { [key: string]: string } = {
      'service.area.enabled': String(this.serviceAreaEnabled),
      'service.area.center.latitude': String(this.serviceAreaLat),
      'service.area.center.longitude': String(this.serviceAreaLng),
      'service.area.radius.km': String(this.serviceAreaRadius)
    };
    this.settingsService.updateMultipleSettings(settings).subscribe({
      next: () => {
        this.snackBar.open('Service area config saved successfully', 'Close', { duration: 3000 });
        this.serviceAreaSaving = false;
      },
      error: () => {
        this.snackBar.open('Failed to save service area config', 'Close', { duration: 3000 });
        this.serviceAreaSaving = false;
      }
    });
  }

  // ===== Global Free Post Limit =====

  loadGlobalFreePostLimit(): void {
    this.globalFreePostLimitLoading = true;
    this.settingsService.getAllSettings().subscribe({
      next: (settings) => {
        for (const s of settings) {
          if (s.key === 'global.free_post_limit') {
            this.globalFreePostLimit = parseInt(s.value, 10);
            if (isNaN(this.globalFreePostLimit)) this.globalFreePostLimit = 1;
          }
        }
        this.globalFreePostLimitLoading = false;
      },
      error: () => {
        this.snackBar.open('Failed to load global free post limit', 'Close', { duration: 3000 });
        this.globalFreePostLimitLoading = false;
      }
    });
  }

  saveGlobalFreePostLimit(): void {
    this.globalFreePostLimitSaving = true;
    const settings: { [key: string]: string } = {
      'global.free_post_limit': String(this.globalFreePostLimit)
    };
    this.settingsService.updateMultipleSettings(settings).subscribe({
      next: () => {
        this.snackBar.open('Global free post limit saved successfully', 'Close', { duration: 3000 });
        this.globalFreePostLimitSaving = false;
      },
      error: () => {
        this.snackBar.open('Failed to save global free post limit', 'Close', { duration: 3000 });
        this.globalFreePostLimitSaving = false;
      }
    });
  }

  // ===== Global Limits =====

  loadGlobalLimits(): void {
    this.globalLoading = true;
    this.featureConfigService.getAllFeatures().subscribe({
      next: (response: any) => {
        const features = response.data || response || [];
        // Filter to only post-related features
        const postFeatures = ['PARCEL_SERVICE', 'MARKETPLACE', 'LABOURS', 'FARM_PRODUCTS', 'TRAVELS', 'RENTAL', 'REAL_ESTATE', 'WOMENS_CORNER'];
        this.globalLimits = features.filter((f: FeatureConfig) => postFeatures.includes(f.featureName));
        this.globalLoading = false;
      },
      error: () => {
        this.snackBar.open('Failed to load global limits', 'Close', { duration: 3000 });
        this.globalLoading = false;
      }
    });
  }

  getGlobalFeatureLabel(featureName: string): string {
    const feature = this.featureNames.find(f => f.value === featureName);
    return feature ? feature.label : featureName;
  }

  startEditGlobal(config: FeatureConfig): void {
    this.editingGlobalId = config.id!;
    this.editGlobalValue = config.maxPostsPerUser || 0;
  }

  cancelEditGlobal(): void {
    this.editingGlobalId = null;
  }

  saveGlobalLimit(config: FeatureConfig): void {
    const updated = { ...config, maxPostsPerUser: this.editGlobalValue };
    this.featureConfigService.updateFeature(config.id!, updated).subscribe({
      next: () => {
        this.snackBar.open(`Global limit for ${this.getGlobalFeatureLabel(config.featureName)} updated`, 'Close', { duration: 3000 });
        this.editingGlobalId = null;
        this.loadGlobalLimits();
      },
      error: () => this.snackBar.open('Failed to update global limit', 'Close', { duration: 3000 })
    });
  }

  // ===== User-Specific Overrides =====

  loadLimits(): void {
    this.isLoading = true;
    this.postLimitsService.getAllLimits().subscribe({
      next: (response: any) => {
        this.limits = response.data || [];
        this.isLoading = false;
      },
      error: () => {
        this.snackBar.open('Failed to load user overrides', 'Close', { duration: 3000 });
        this.isLoading = false;
      }
    });
  }

  openAddForm(): void {
    this.limitForm.reset({ maxPosts: 5 });
    this.lookupResult = null;
    this.lookupError = '';
    this.showForm = true;
  }

  cancelForm(): void {
    this.showForm = false;
    this.lookupResult = null;
    this.lookupError = '';
  }

  lookupUser(): void {
    const query = this.limitForm.get('userIdentifier')?.value?.trim();
    if (!query) return;

    this.lookupLoading = true;
    this.lookupResult = null;
    this.lookupError = '';

    this.postLimitsService.lookupUser(query).subscribe({
      next: (response: any) => {
        this.lookupResult = response.data;
        this.lookupLoading = false;
      },
      error: () => {
        this.lookupError = 'No user found with this mobile number or email';
        this.lookupLoading = false;
      }
    });
  }

  saveLimit(): void {
    if (this.limitForm.invalid) return;

    const formValue = this.limitForm.value;
    this.postLimitsService.createOrUpdate({
      userIdentifier: formValue.userIdentifier.trim(),
      featureName: formValue.featureName,
      maxPosts: formValue.maxPosts
    }).subscribe({
      next: () => {
        this.snackBar.open('User override saved successfully', 'Close', { duration: 3000 });
        this.showForm = false;
        this.lookupResult = null;
        this.lookupError = '';
        this.loadLimits();
      },
      error: (err: any) => {
        const msg = err?.error?.message || 'Failed to save user override';
        this.snackBar.open(msg, 'Close', { duration: 4000 });
      }
    });
  }

  deleteLimit(limit: UserPostLimit): void {
    if (!confirm(`Delete post limit override for user ${limit.userId} on ${this.getFeatureLabel(limit.featureName)}?`)) return;

    this.postLimitsService.deleteLimit(limit.id!).subscribe({
      next: () => {
        this.snackBar.open('User override deleted', 'Close', { duration: 3000 });
        this.loadLimits();
      },
      error: () => this.snackBar.open('Failed to delete override', 'Close', { duration: 3000 })
    });
  }

  getFeatureLabel(featureName: string): string {
    const feature = this.featureNames.find(f => f.value === featureName);
    return feature ? feature.label : featureName;
  }

  // ===== Paid Post Config =====

  loadPaidPostConfig(): void {
    this.paidPostLoading = true;
    this.settingsService.getAllSettings().subscribe({
      next: (settings) => {
        for (const s of settings) {
          if (s.key === 'paid_post.enabled') this.paidPostEnabled = s.value === 'true';
          if (s.key === 'paid_post.currency') this.paidPostCurrency = s.value || 'INR';
          // Load per-type prices (e.g. paid_post.price.MARKETPLACE)
          const pricePrefix = 'paid_post.price.';
          if (s.key.startsWith(pricePrefix)) {
            const postType = s.key.substring(pricePrefix.length);
            this.postTypePrices[postType] = parseInt(s.value, 10) || 10;
          }
          // Fallback: use flat price as default for types not yet set
          if (s.key === 'paid_post.price') {
            const fallbackPrice = parseInt(s.value, 10) || 10;
            for (const pt of this.postTypes) {
              if (this.postTypePrices[pt.key] === undefined) {
                this.postTypePrices[pt.key] = fallbackPrice;
              }
            }
          }
        }
        // Ensure all post types have a default price
        for (const pt of this.postTypes) {
          if (this.postTypePrices[pt.key] === undefined) {
            this.postTypePrices[pt.key] = 10;
          }
        }
        this.paidPostLoading = false;
      },
      error: () => {
        this.snackBar.open('Failed to load paid post config', 'Close', { duration: 3000 });
        this.paidPostLoading = false;
      }
    });
  }

  savePaidPostConfig(): void {
    this.paidPostSaving = true;
    const settings: { [key: string]: string } = {
      'paid_post.enabled': String(this.paidPostEnabled),
      'paid_post.currency': this.paidPostCurrency
    };
    this.settingsService.updateMultipleSettings(settings).subscribe({
      next: () => {
        this.snackBar.open('Paid post config saved successfully', 'Close', { duration: 3000 });
        this.paidPostSaving = false;
      },
      error: () => {
        this.snackBar.open('Failed to save paid post config', 'Close', { duration: 3000 });
        this.paidPostSaving = false;
      }
    });
  }

  // ===== Post Type Settings =====

  loadPostTypeSettings(): void {
    this.typeSettingsLoading = true;
    this.settingsService.getAllSettings().subscribe({
      next: (settings) => {
        for (const s of settings) {
          for (const pt of this.postTypeConfigs) {
            if (s.key === `${pt.prefix}.post.duration_days`) pt.durationDays = parseInt(s.value, 10) || 30;
            if (s.key === `${pt.prefix}.post.auto_approve`) pt.autoApprove = s.value === 'true';
            if (s.key === `${pt.prefix}.post.visible_statuses`) {
              try { pt.visibleStatuses = JSON.parse(s.value); } catch { pt.visibleStatuses = ['APPROVED']; }
            }
            if (s.key === `${pt.prefix}.post.report_threshold`) pt.reportThreshold = parseInt(s.value, 10) || 3;
          }
        }
        this.typeSettingsLoading = false;
      },
      error: () => {
        this.snackBar.open('Failed to load post type settings', 'Close', { duration: 3000 });
        this.typeSettingsLoading = false;
      }
    });
  }

  isStatusChecked(pt: any, status: string): boolean {
    return pt.visibleStatuses.includes(status);
  }

  toggleStatus(pt: any, status: string): void {
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

  savePostTypeSettings(pt: any): void {
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

  savePostTypePrices(): void {
    this.savingPrices = true;
    const settings: { [key: string]: string } = {};
    for (const pt of this.postTypes) {
      settings[`paid_post.price.${pt.key}`] = String(this.postTypePrices[pt.key] || 10);
    }
    this.settingsService.updateMultipleSettings(settings).subscribe({
      next: () => {
        this.snackBar.open('Post type prices saved successfully', 'Close', { duration: 3000 });
        this.savingPrices = false;
      },
      error: () => {
        this.snackBar.open('Failed to save post type prices', 'Close', { duration: 3000 });
        this.savingPrices = false;
      }
    });
  }
}
