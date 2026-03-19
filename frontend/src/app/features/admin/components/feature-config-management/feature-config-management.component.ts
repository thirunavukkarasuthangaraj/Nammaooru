import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { FeatureConfigService, FeatureConfig } from '../../services/feature-config.service';
import { environment } from '../../../../../environments/environment';

@Component({
  selector: 'app-feature-config-management',
  templateUrl: './feature-config-management.component.html',
  styleUrls: ['./feature-config-management.component.scss']
})
export class FeatureConfigManagementComponent implements OnInit {
  features: FeatureConfig[] = [];
  isLoading = true;
  showForm = false;
  editingId: number | null = null;
  featureForm!: FormGroup;
  selectedImage: File | null = null;
  imagePreview: string | null = null;
  editingImageUrl: string | null = null;

  displayedColumns: string[] = [
    'displayOrder', 'image', 'featureName', 'displayName', 'displayNameTamil',
    'icon', 'color', 'radiusKm', 'maxPostsPerUser', 'maxImagesPerPost', 'active', 'actions'
  ];

  // ── Grouped getters ──────────────────────────────────────────────────────────
  /** Bottom nav items (nav_cart, nav_orders, nav_profile) */
  get navFeatures(): FeatureConfig[] {
    return this.features.filter(f => f.featureName.startsWith('nav_'));
  }
  /** Dashboard section items (section_deliver_to, section_featured_shops, etc.) */
  get sectionFeatures(): FeatureConfig[] {
    return this.features.filter(f => f.featureName.startsWith('section_'));
  }
  /** Service grid tiles (grocery, food, labours, etc.) */
  get serviceFeatures(): FeatureConfig[] {
    return this.features.filter(
      f => !f.featureName.startsWith('nav_') && !f.featureName.startsWith('section_')
    );
  }

  // Human-friendly metadata for nav items
  navMeta: Record<string, { label: string; icon: string; desc: string }> = {
    nav_cart:    { label: 'Cart Tab',    icon: 'shopping_cart', desc: 'Show Cart icon in bottom navigation' },
    nav_orders:  { label: 'Orders Tab',  icon: 'list_alt',      desc: 'Show Orders icon in bottom navigation' },
    nav_profile: { label: 'Profile Tab', icon: 'person',        desc: 'Show Profile icon in bottom navigation' },
  };
  // Human-friendly metadata for section items
  sectionMeta: Record<string, { label: string; icon: string; desc: string }> = {
    section_deliver_to:     { label: 'Deliver To Bar',  icon: 'location_on',  desc: 'Address selector at top of home screen' },
    section_featured_shops: { label: 'Featured Shops',  icon: 'store',        desc: 'Featured shops section on home screen' },
    section_recent_orders:  { label: 'Recent Orders',   icon: 'receipt_long', desc: 'Recent orders section on home screen' },
  };

  getNavMeta(f: FeatureConfig) {
    return this.navMeta[f.featureName] ?? { label: f.displayName, icon: 'settings', desc: '' };
  }
  getSectionMeta(f: FeatureConfig) {
    return this.sectionMeta[f.featureName] ?? { label: f.displayName, icon: 'dashboard', desc: '' };
  }

  constructor(
    private featureConfigService: FeatureConfigService,
    private fb: FormBuilder,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.initForm();
    this.loadFeatures();
  }

  initForm(): void {
    this.featureForm = this.fb.group({
      featureName: ['', Validators.required],
      displayName: ['', Validators.required],
      displayNameTamil: [''],
      icon: [''],
      color: [''],
      route: [''],
      latitude: [null],
      longitude: [null],
      radiusKm: [50],
      displayOrder: [0],
      isActive: [true],
      maxPostsPerUser: [0],
      maxImagesPerPost: [3]
    });
  }

  loadFeatures(): void {
    this.isLoading = true;
    this.featureConfigService.getAllFeatures().subscribe({
      next: (response: any) => {
        this.features = response.data || [];
        this.isLoading = false;
      },
      error: () => {
        this.snackBar.open('Failed to load feature configs', 'Close', { duration: 3000 });
        this.isLoading = false;
      }
    });
  }

  getImageUrl(imageUrl: string): string {
    if (!imageUrl) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    const base = environment.apiUrl.replace('/api', '');
    return `${base}${imageUrl}`;
  }

  onImageSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this.selectedImage = input.files[0];
      const reader = new FileReader();
      reader.onload = () => { this.imagePreview = reader.result as string; };
      reader.readAsDataURL(this.selectedImage);
    }
  }

  removeImage(): void {
    this.selectedImage = null;
    this.imagePreview = null;
  }

  openAddForm(): void {
    this.editingId = null;
    this.selectedImage = null;
    this.imagePreview = null;
    this.editingImageUrl = null;
    this.featureForm.reset({ radiusKm: 50, displayOrder: 0, isActive: true, maxPostsPerUser: 0, maxImagesPerPost: 3 });
    this.showForm = true;
  }

  openEditForm(feature: FeatureConfig): void {
    this.editingId = feature.id!;
    this.selectedImage = null;
    this.imagePreview = null;
    this.editingImageUrl = feature.imageUrl || null;
    this.featureForm.patchValue({
      featureName: feature.featureName,
      displayName: feature.displayName,
      displayNameTamil: feature.displayNameTamil,
      icon: feature.icon,
      color: feature.color,
      route: feature.route,
      latitude: feature.latitude,
      longitude: feature.longitude,
      radiusKm: feature.radiusKm,
      displayOrder: feature.displayOrder,
      isActive: feature.isActive,
      maxPostsPerUser: feature.maxPostsPerUser || 0,
      maxImagesPerPost: feature.maxImagesPerPost || 3
    });
    this.showForm = true;
  }

  cancelForm(): void {
    this.showForm = false;
    this.editingId = null;
    this.selectedImage = null;
    this.imagePreview = null;
    this.editingImageUrl = null;
  }

  saveFeature(): void {
    if (this.featureForm.invalid) return;
    const config: FeatureConfig = this.featureForm.value;
    if (this.editingId) {
      this.featureConfigService.updateFeature(this.editingId, config, this.selectedImage || undefined).subscribe({
        next: () => {
          this.snackBar.open('Feature updated', 'Close', { duration: 3000 });
          this.showForm = false;
          this.loadFeatures();
        },
        error: () => this.snackBar.open('Failed to update feature', 'Close', { duration: 3000 })
      });
    } else {
      this.featureConfigService.createFeature(config, this.selectedImage || undefined).subscribe({
        next: () => {
          this.snackBar.open('Feature created', 'Close', { duration: 3000 });
          this.showForm = false;
          this.loadFeatures();
        },
        error: () => this.snackBar.open('Failed to create feature', 'Close', { duration: 3000 })
      });
    }
  }

  toggleActive(feature: FeatureConfig): void {
    this.featureConfigService.toggleActive(feature.id!).subscribe({
      next: (response: any) => {
        const updated = response.data;
        const idx = this.features.findIndex(f => f.id === feature.id);
        if (idx >= 0 && updated) this.features[idx] = { ...updated };
        this.snackBar.open(
          `${feature.displayName} ${updated?.isActive ? 'enabled' : 'disabled'} in app`,
          'Close', { duration: 2000 }
        );
      },
      error: () => this.snackBar.open('Failed to toggle', 'Close', { duration: 3000 })
    });
  }

  deleteFeature(feature: FeatureConfig): void {
    if (!confirm(`Delete "${feature.displayName}"?`)) return;
    this.featureConfigService.deleteFeature(feature.id!).subscribe({
      next: () => { this.snackBar.open('Deleted', 'Close', { duration: 3000 }); this.loadFeatures(); },
      error: () => this.snackBar.open('Failed to delete', 'Close', { duration: 3000 })
    });
  }
}
