import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { FeatureConfigService, FeatureConfig } from '../../services/feature-config.service';

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

  displayedColumns: string[] = [
    'displayOrder', 'featureName', 'displayName', 'displayNameTamil',
    'icon', 'color', 'radiusKm', 'maxPostsPerUser', 'active', 'actions'
  ];

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
      maxPostsPerUser: [0]
    });
  }

  loadFeatures(): void {
    this.isLoading = true;
    this.featureConfigService.getAllFeatures().subscribe({
      next: (response: any) => {
        this.features = response.data || [];
        this.isLoading = false;
      },
      error: (err) => {
        this.snackBar.open('Failed to load feature configs', 'Close', { duration: 3000 });
        this.isLoading = false;
      }
    });
  }

  openAddForm(): void {
    this.editingId = null;
    this.featureForm.reset({ radiusKm: 50, displayOrder: 0, isActive: true, maxPostsPerUser: 0 });
    this.showForm = true;
  }

  openEditForm(feature: FeatureConfig): void {
    this.editingId = feature.id!;
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
      maxPostsPerUser: feature.maxPostsPerUser || 0
    });
    this.showForm = true;
  }

  cancelForm(): void {
    this.showForm = false;
    this.editingId = null;
  }

  saveFeature(): void {
    if (this.featureForm.invalid) return;

    const config: FeatureConfig = this.featureForm.value;

    if (this.editingId) {
      this.featureConfigService.updateFeature(this.editingId, config).subscribe({
        next: () => {
          this.snackBar.open('Feature updated successfully', 'Close', { duration: 3000 });
          this.showForm = false;
          this.loadFeatures();
        },
        error: () => this.snackBar.open('Failed to update feature', 'Close', { duration: 3000 })
      });
    } else {
      this.featureConfigService.createFeature(config).subscribe({
        next: () => {
          this.snackBar.open('Feature created successfully', 'Close', { duration: 3000 });
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
        if (idx >= 0 && updated) {
          this.features[idx] = updated;
        }
        this.snackBar.open('Feature toggled', 'Close', { duration: 2000 });
      },
      error: () => this.snackBar.open('Failed to toggle feature', 'Close', { duration: 3000 })
    });
  }

  deleteFeature(feature: FeatureConfig): void {
    if (!confirm(`Delete feature "${feature.displayName}"?`)) return;

    this.featureConfigService.deleteFeature(feature.id!).subscribe({
      next: () => {
        this.snackBar.open('Feature deleted', 'Close', { duration: 3000 });
        this.loadFeatures();
      },
      error: () => this.snackBar.open('Failed to delete feature', 'Close', { duration: 3000 })
    });
  }
}
