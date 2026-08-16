import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { VillageService, Village } from '../../services/village.service';
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

  displayedColumns: string[] = [
    'displayOrder', 'name', 'nameTamil', 'district', 'panchayatName',
    'panchayatUrl', 'active', 'actions'
  ];

  constructor(
    private villageService: VillageService,
    private fb: FormBuilder,
    private swal: SwalService
  ) {}

  ngOnInit(): void {
    this.initForm();
    this.loadVillages();
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
      isActive: [true]
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

  openAddForm(): void {
    this.editingId = null;
    this.villageForm.reset({ displayOrder: 0, isActive: true });
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
      isActive: village.isActive
    });
    this.showForm = true;
  }

  cancelForm(): void {
    this.showForm = false;
    this.editingId = null;
  }

  saveVillage(): void {
    if (this.villageForm.invalid) return;

    const village: Village = this.villageForm.value;

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
