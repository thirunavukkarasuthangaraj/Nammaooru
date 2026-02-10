import { Component, Inject, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { HttpClient } from '@angular/common/http';
import { MatSnackBar } from '@angular/material/snack-bar';
import { environment } from '../../../../../environments/environment';

export interface CategoryCreateDialogData {
  existingCategories: string[];
}

/**
 * Sync any offline-created categories to the server.
 * Call this when the app comes back online, before syncing products.
 */
export async function syncOfflineCategories(http: HttpClient, apiUrl: string): Promise<void> {
  try {
    const raw = localStorage.getItem('pending_offline_categories');
    if (!raw) return;
    const pending = JSON.parse(raw);
    if (!Array.isArray(pending) || pending.length === 0) return;

    const remaining: any[] = [];
    for (const cat of pending) {
      try {
        await http.post(`${apiUrl}/products/categories`, { name: cat.name }).toPromise();
        console.log('Synced offline category:', cat.name);
      } catch (err: any) {
        // 409 or duplicate means it already exists - that's fine
        if (err?.status === 409 || err?.error?.message?.includes('already exists')) {
          console.log('Category already exists on server:', cat.name);
        } else {
          remaining.push(cat);
          console.warn('Failed to sync category:', cat.name, err);
        }
      }
    }

    if (remaining.length > 0) {
      localStorage.setItem('pending_offline_categories', JSON.stringify(remaining));
    } else {
      localStorage.removeItem('pending_offline_categories');
    }
  } catch (e) {
    console.warn('Error syncing offline categories:', e);
  }
}

export interface CategoryCreateDialogResult {
  name: string;
  id?: number;
  slug?: string;
  createdOffline?: boolean;
}

@Component({
  selector: 'app-category-create-dialog',
  template: `
    <h2 mat-dialog-title>
      <mat-icon style="vertical-align: middle; margin-right: 8px;">create_new_folder</mat-icon>
      Create New Category
    </h2>

    <mat-dialog-content>
      <form [formGroup]="form" (ngSubmit)="onCreate()">
        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Category Name</mat-label>
          <input matInput
                 formControlName="name"
                 placeholder="e.g. SNACKS, DAIRY, BEVERAGES"
                 (input)="onNameInput()"
                 cdkFocusInitial>
          <mat-icon matPrefix>category</mat-icon>
          <mat-hint>Category name will be converted to UPPERCASE</mat-hint>
          <mat-error *ngIf="form.get('name')?.hasError('required')">
            Category name is required
          </mat-error>
          <mat-error *ngIf="form.get('name')?.hasError('minlength')">
            Name must be at least 2 characters
          </mat-error>
          <mat-error *ngIf="form.get('name')?.hasError('duplicate')">
            This category already exists
          </mat-error>
        </mat-form-field>
      </form>

      <div class="offline-hint" *ngIf="isOffline">
        <mat-icon>cloud_off</mat-icon>
        <span>You're offline. Category will be saved locally and synced when online.</span>
      </div>
    </mat-dialog-content>

    <mat-dialog-actions align="end">
      <button mat-button mat-dialog-close [disabled]="saving">Cancel</button>
      <button mat-raised-button
              color="primary"
              [disabled]="form.invalid || saving"
              (click)="onCreate()">
        <mat-spinner *ngIf="saving" diameter="18" style="display: inline-block; margin-right: 8px;"></mat-spinner>
        <mat-icon *ngIf="!saving" style="margin-right: 4px;">add</mat-icon>
        {{ saving ? 'Creating...' : 'Create Category' }}
      </button>
    </mat-dialog-actions>
  `,
  styles: [`
    .full-width {
      width: 100%;
    }

    mat-dialog-content {
      min-width: 350px;
      padding-top: 8px !important;
    }

    h2[mat-dialog-title] {
      display: flex;
      align-items: center;
      margin: 0;
      padding: 16px 24px;
      background: #f8f9fa;
      border-bottom: 1px solid #e0e0e0;
      font-size: 1.1rem;
    }

    .offline-hint {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px 12px;
      margin-top: 12px;
      background: #fff3e0;
      border-radius: 8px;
      font-size: 0.85rem;
      color: #e65100;
    }

    .offline-hint mat-icon {
      font-size: 18px;
      width: 18px;
      height: 18px;
    }

    mat-dialog-actions {
      padding: 12px 24px !important;
      border-top: 1px solid #e0e0e0;
    }

    @media (max-width: 480px) {
      mat-dialog-content {
        min-width: unset;
      }
    }
  `]
})
export class CategoryCreateDialogComponent implements OnInit {
  form!: FormGroup;
  saving = false;
  isOffline = false;
  private apiUrl = environment.apiUrl;
  private existingCategories: string[] = [];

  constructor(
    private fb: FormBuilder,
    private http: HttpClient,
    private snackBar: MatSnackBar,
    public dialogRef: MatDialogRef<CategoryCreateDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: CategoryCreateDialogData
  ) {}

  ngOnInit(): void {
    this.isOffline = !navigator.onLine;
    this.existingCategories = (this.data?.existingCategories || []).map(c => c.toUpperCase());

    this.form = this.fb.group({
      name: ['', [Validators.required, Validators.minLength(2)]]
    });
  }

  onNameInput(): void {
    const control = this.form.get('name');
    if (!control) return;
    const val = control.value?.trim().toUpperCase();
    if (val && this.existingCategories.includes(val)) {
      control.setErrors({ duplicate: true });
    } else if (control.hasError('duplicate')) {
      control.updateValueAndValidity();
    }
  }

  onCreate(): void {
    if (this.form.invalid || this.saving) return;

    const name = this.form.get('name')!.value.trim().toUpperCase();

    // Check duplicate again
    if (this.existingCategories.includes(name)) {
      this.form.get('name')!.setErrors({ duplicate: true });
      return;
    }

    this.saving = true;

    if (!navigator.onLine) {
      // Offline: save locally and return
      this.saveOffline(name);
      return;
    }

    // Online: call API
    this.http.post<any>(`${this.apiUrl}/products/categories`, { name }).subscribe({
      next: (response) => {
        const newCat = response?.data || response;
        const result: CategoryCreateDialogResult = {
          name: newCat?.name || name,
          id: newCat?.id,
          slug: newCat?.slug
        };
        this.saving = false;
        this.snackBar.open(`Category "${result.name}" created!`, 'Close', { duration: 2000 });
        this.dialogRef.close(result);
      },
      error: (err) => {
        console.error('Failed to create category via API:', err);
        // Fallback to offline save
        this.saveOffline(name);
      }
    });
  }

  private saveOffline(name: string): void {
    // Save to local cache
    try {
      const cachedNames = JSON.parse(localStorage.getItem('cached_product_category_names') || '[]');
      if (!cachedNames.includes(name)) {
        cachedNames.push(name);
        cachedNames.sort();
        localStorage.setItem('cached_product_category_names', JSON.stringify(cachedNames));
      }

      // Also save to pending offline categories for sync later
      const pendingCategories = JSON.parse(localStorage.getItem('pending_offline_categories') || '[]');
      pendingCategories.push({ name, createdAt: new Date().toISOString() });
      localStorage.setItem('pending_offline_categories', JSON.stringify(pendingCategories));
    } catch (e) {
      console.warn('Failed to save category offline:', e);
    }

    const result: CategoryCreateDialogResult = {
      name,
      createdOffline: true
    };
    this.saving = false;
    this.snackBar.open(`Category "${name}" saved locally. Will sync when online.`, 'Close', { duration: 3000 });
    this.dialogRef.close(result);
  }
}
