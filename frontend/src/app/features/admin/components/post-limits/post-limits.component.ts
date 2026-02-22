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
    { value: 'REAL_ESTATE', label: 'Real Estate' }
  ];

  // Paid post config
  paidPostEnabled = false;
  paidPostCurrency = 'INR';
  paidPostLoading = true;
  paidPostSaving = false;

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
    this.loadGlobalFreePostLimit();
    this.loadGlobalLimits();
    this.loadLimits();
    this.loadPaidPostConfig();
  }

  initForm(): void {
    this.limitForm = this.fb.group({
      userIdentifier: ['', [Validators.required]],
      featureName: ['', Validators.required],
      maxPosts: [5, [Validators.required, Validators.min(0)]]
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
        const postFeatures = ['PARCEL_SERVICE', 'MARKETPLACE', 'LABOURS', 'FARM_PRODUCTS', 'TRAVELS', 'RENTAL', 'REAL_ESTATE'];
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
