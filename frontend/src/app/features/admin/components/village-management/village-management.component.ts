import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { VillageService, Village } from '../../services/village.service';
import { FeatureConfigService } from '../../services/feature-config.service';
import { SwalService } from '../../../../core/services/swal.service';

@Component({
  selector: 'app-village-management',
  templateUrl: './village-management.component.html',
  styleUrls: ['./village-management.component.scss']
})
export class VillageManagementComponent implements OnInit {
  villages: Village[] = [];
  isLoading = true;
  showForm = false;
  editingId: number | null = null;
  villageForm!: FormGroup;

  // Service Menu category tiles (Grocery, Food, etc.) - the same keys shown
  // in Feature Config's "Service Menu (Home Screen Grid)" table - loaded so
  // the multi-select always reflects whatever categories currently exist,
  // instead of a hardcoded list going stale as new ones are added.
  categoryOptions: { key: string; label: string }[] = [];

  displayedColumns: string[] = [
    'displayOrder', 'name', 'nameTamil', 'district', 'panchayatName',
    'panchayatUrl', 'active', 'hiddenCategories', 'actions'
  ];

  constructor(
    private villageService: VillageService,
    private featureConfigService: FeatureConfigService,
    private fb: FormBuilder,
    private swal: SwalService
  ) {}

  ngOnInit(): void {
    this.initForm();
    this.loadVillages();
    this.loadCategoryOptions();
  }

  initForm(): void {
    this.villageForm = this.fb.group({
      name: ['', Validators.required],
      nameTamil: [''],
      district: [''],
      panchayatName: [''],
      panchayatUrl: [''],
      description: [''],
      displayOrder: [0],
      isActive: [true],
      hiddenRegistrationCategories: [[] as string[]]
    });
  }

  loadVillages(): void {
    this.isLoading = true;
    this.villageService.getAllVillages().subscribe({
      next: (response: any) => {
        this.villages = response.data || [];
        this.isLoading = false;
      },
      error: () => {
        this.swal.toast('Failed to load villages', 'error');
        this.isLoading = false;
      }
    });
  }

  loadCategoryOptions(): void {
    // Service Menu tiles are plain uppercase keys (GROCERY, FOOD, ...);
    // nav_*/section_* entries are unrelated app-visibility toggles from the
    // same table and must not show up as CTA-hiding options.
    this.featureConfigService.getAllFeatures().subscribe({
      next: (response: any) => {
        const features = response.data || [];
        this.categoryOptions = features
          .filter((f: any) => f.featureName && !f.featureName.startsWith('nav_') && !f.featureName.startsWith('section_'))
          .map((f: any) => ({ key: f.featureName, label: f.displayName || f.featureName }));
      },
      error: () => this.swal.toast('Failed to load category options', 'error')
    });
  }

  categoryLabel(key: string): string {
    return this.categoryOptions.find(c => c.key === key)?.label || key;
  }

  hiddenCategoriesList(village: Village): string[] {
    if (!village.hiddenRegistrationCategories) return [];
    return village.hiddenRegistrationCategories.split(',').map(c => c.trim()).filter(Boolean);
  }

  openAddForm(): void {
    this.editingId = null;
    this.villageForm.reset({ displayOrder: 0, isActive: true, hiddenRegistrationCategories: [] });
    this.showForm = true;
  }

  openEditForm(village: Village): void {
    this.editingId = village.id!;
    this.villageForm.patchValue({
      name: village.name,
      nameTamil: village.nameTamil,
      district: village.district,
      panchayatName: village.panchayatName,
      panchayatUrl: village.panchayatUrl,
      description: village.description,
      displayOrder: village.displayOrder,
      isActive: village.isActive,
      hiddenRegistrationCategories: this.hiddenCategoriesList(village)
    });
    this.showForm = true;
  }

  cancelForm(): void {
    this.showForm = false;
    this.editingId = null;
  }

  saveVillage(): void {
    if (this.villageForm.invalid) return;

    const formValue = this.villageForm.value;
    const village: Village = {
      ...formValue,
      hiddenRegistrationCategories: (formValue.hiddenRegistrationCategories || []).join(',')
    };

    if (this.editingId) {
      this.villageService.updateVillage(this.editingId, village).subscribe({
        next: () => {
          this.swal.toast('Village updated successfully', 'success');
          this.showForm = false;
          this.loadVillages();
        },
        error: () => this.swal.toast('Failed to update village', 'error')
      });
    } else {
      this.villageService.createVillage(village).subscribe({
        next: () => {
          this.swal.toast('Village created successfully', 'success');
          this.showForm = false;
          this.loadVillages();
        },
        error: () => this.swal.toast('Failed to create village', 'error')
      });
    }
  }

  toggleActive(village: Village): void {
    this.villageService.toggleActive(village.id!).subscribe({
      next: (response: any) => {
        const updated = response.data;
        const idx = this.villages.findIndex(v => v.id === village.id);
        if (idx >= 0 && updated) {
          this.villages[idx] = updated;
        }
        this.swal.toast('Village toggled', 'success');
      },
      error: () => this.swal.toast('Failed to toggle village', 'error')
    });
  }

  deleteVillage(village: Village): void {
    if (!confirm(`Delete village "${village.name}"?`)) return;

    this.villageService.deleteVillage(village.id!).subscribe({
      next: () => {
        this.swal.toast('Village deleted', 'success');
        this.loadVillages();
      },
      error: () => this.swal.toast('Failed to delete village', 'error')
    });
  }

  truncateUrl(url: string): string {
    if (!url) return '';
    return url.length > 40 ? url.substring(0, 40) + '...' : url;
  }
}
