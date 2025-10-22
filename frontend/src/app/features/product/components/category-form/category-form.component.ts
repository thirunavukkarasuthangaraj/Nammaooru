import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { ProductCategoryService } from '../../../../core/services/product-category.service';
import { ProductCategory, ProductCategoryRequest } from '../../../../core/models/product.model';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-category-form',
  template: `
    <div class="form-wrapper">
      <mat-card class="form-card">
        <mat-card-header class="form-header">
          <div mat-card-avatar class="form-avatar">
            <mat-icon>category</mat-icon>
          </div>
          <mat-card-title>{{ isEditMode ? 'Edit Category' : 'Create New Category' }}</mat-card-title>
          <mat-card-subtitle>{{ isEditMode ? 'Update category information' : 'Add a new product category' }}</mat-card-subtitle>
        </mat-card-header>

        <mat-card-content class="form-content">
          <form [formGroup]="categoryForm" (ngSubmit)="onSubmit()" class="category-form">
            
            <!-- Image Upload Section -->
            <div class="form-section">
              <h3 class="section-title">
                <mat-icon class="section-icon">image</mat-icon>
                Category Image
              </h3>

              <div class="image-upload-area">
                <input type="file"
                       #fileInput
                       (change)="onImageSelected($event)"
                       accept="image/*"
                       style="display: none;">

                <div class="upload-placeholder"
                     *ngIf="!previewImageUrl && !categoryForm.get('iconUrl')?.value"
                     (click)="fileInput.click()"
                     (dragover)="onDragOver($event)"
                     (dragleave)="onDragLeave($event)"
                     (drop)="onDrop($event)"
                     [class.dragover]="isDragging">
                  <mat-icon class="upload-icon">cloud_upload</mat-icon>
                  <h3>Click to Upload Category Image</h3>
                  <p>or drag and drop</p>
                  <span class="file-info">PNG, JPG, GIF up to 5MB</span>
                </div>

                <div class="image-preview-container" *ngIf="previewImageUrl || categoryForm.get('iconUrl')?.value">
                  <img [src]="previewImageUrl || categoryForm.get('iconUrl')?.value"
                       alt="Category Preview"
                       class="preview-image">
                  <div class="image-actions">
                    <button mat-icon-button
                            type="button"
                            (click)="fileInput.click()"
                            matTooltip="Change Image">
                      <mat-icon>edit</mat-icon>
                    </button>
                    <button mat-icon-button
                            type="button"
                            (click)="removeImage()"
                            matTooltip="Remove Image">
                      <mat-icon>delete</mat-icon>
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <div class="form-section">
              <h3 class="section-title">
                <mat-icon class="section-icon">info</mat-icon>
                Basic Information
              </h3>
              
              <div class="form-grid">
                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Category Name</mat-label>
                  <input matInput formControlName="name" placeholder="Enter category name">
                  <mat-icon matSuffix>title</mat-icon>
                  <mat-error *ngIf="categoryForm.get('name')?.hasError('required')">
                    Category name is required
                  </mat-error>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Slug</mat-label>
                  <input matInput formControlName="slug" placeholder="URL-friendly name">
                  <mat-icon matSuffix>link</mat-icon>
                  <mat-hint>Auto-generated from name if left empty</mat-hint>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Parent Category</mat-label>
                  <mat-select formControlName="parentId">
                    <mat-option [value]="null">None (Root Category)</mat-option>
                    <mat-option *ngFor="let category of parentCategories" [value]="category.id">
                      {{ category.name }}
                    </mat-option>
                  </mat-select>
                  <mat-icon matSuffix>account_tree</mat-icon>
                </mat-form-field>

                <mat-form-field appearance="outline" class="form-field">
                  <mat-label>Sort Order</mat-label>
                  <input matInput formControlName="sortOrder" type="number" placeholder="0">
                  <mat-icon matSuffix>sort</mat-icon>
                  <mat-hint>Lower numbers appear first</mat-hint>
                </mat-form-field>
              </div>

              <mat-form-field appearance="outline" class="form-field full-width">
                <mat-label>Description</mat-label>
                <textarea matInput formControlName="description" rows="3" placeholder="Category description..."></textarea>
                <mat-icon matSuffix>description</mat-icon>
              </mat-form-field>

              <!-- Icon URL field hidden when image is uploaded -->
              <mat-form-field appearance="outline" class="form-field full-width" *ngIf="!selectedImageFile">
                <mat-label>Icon URL (Optional)</mat-label>
                <input matInput formControlName="iconUrl" placeholder="https://example.com/icon.png">
                <mat-icon matSuffix>link</mat-icon>
                <mat-hint>Alternatively, provide a URL to category icon image</mat-hint>
              </mat-form-field>
            </div>

            <div class="form-section">
              <h3 class="section-title">
                <mat-icon class="section-icon">tune</mat-icon>
                Settings
              </h3>
              
              <div class="checkbox-group">
                <mat-checkbox formControlName="isActive" class="feature-checkbox">
                  <div class="checkbox-content">
                    <mat-icon class="checkbox-icon">visibility</mat-icon>
                    <div>
                      <div class="checkbox-title">Active Category</div>
                      <div class="checkbox-subtitle">Category is visible and can be used</div>
                    </div>
                  </div>
                </mat-checkbox>
              </div>
            </div>
          </form>
        </mat-card-content>

        <mat-card-actions class="form-actions">
          <button mat-button type="button" (click)="onCancel()" class="cancel-btn">
            <mat-icon>cancel</mat-icon>
            Cancel
          </button>
          <button mat-flat-button color="primary" type="submit" 
                  [disabled]="categoryForm.invalid || isLoading" 
                  (click)="onSubmit()" 
                  class="submit-btn">
            <mat-spinner diameter="20" *ngIf="isLoading" class="loading-spinner"></mat-spinner>
            <mat-icon *ngIf="!isLoading">{{ isEditMode ? 'update' : 'add' }}</mat-icon>
            {{ isLoading ? 'Saving...' : (isEditMode ? 'Update Category' : 'Create Category') }}
          </button>
        </mat-card-actions>
      </mat-card>
    </div>
  `,
  styles: [`
    .form-wrapper {
      min-height: 100vh;
      padding: 20px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      display: flex;
      align-items: flex-start;
      justify-content: center;
    }

    .form-card {
      width: 100%;
      max-width: 800px;
      margin: 20px auto;
      border-radius: 16px;
      box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
      overflow: hidden;
    }

    .form-header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 24px;
    }

    .form-header .mat-mdc-card-title {
      color: white !important;
      font-size: 1.5rem;
      font-weight: 600;
    }

    .form-header .mat-mdc-card-subtitle {
      color: rgba(255, 255, 255, 0.8) !important;
      margin-top: 8px;
    }

    .form-avatar {
      background: rgba(255, 255, 255, 0.2);
      border-radius: 50%;
      width: 48px;
      height: 48px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-right: 16px;
    }

    .form-avatar mat-icon {
      color: white;
      font-size: 28px;
      width: 28px;
      height: 28px;
    }

    .form-content {
      padding: 32px;
      background: #fafafa;
    }

    .category-form {
      display: flex;
      flex-direction: column;
      gap: 32px;
    }

    .form-section {
      background: white;
      border-radius: 12px;
      padding: 24px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
      border: 1px solid #e0e0e0;
    }

    .section-title {
      display: flex;
      align-items: center;
      margin: 0 0 24px 0;
      color: #333;
      font-size: 1.1rem;
      font-weight: 600;
    }

    .section-icon {
      margin-right: 12px;
      color: #667eea;
      font-size: 20px;
      width: 20px;
      height: 20px;
    }

    .form-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 20px;
      margin-bottom: 20px;
    }

    .form-field {
      width: 100%;
    }

    .form-field.full-width {
      grid-column: 1 / -1;
    }

    .checkbox-group {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .feature-checkbox {
      background: #f8f9fa;
      border: 1px solid #e9ecef;
      border-radius: 8px;
      padding: 16px;
      transition: all 0.2s ease;
    }

    .feature-checkbox:hover {
      background: #e8f0fe;
      border-color: #1976d2;
    }

    .checkbox-content {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .checkbox-icon {
      color: #667eea;
      font-size: 20px;
      width: 20px;
      height: 20px;
    }

    .checkbox-title {
      font-weight: 600;
      color: #333;
      margin-bottom: 4px;
    }

    .checkbox-subtitle {
      font-size: 12px;
      color: #666;
    }

    .form-actions {
      background: white;
      padding: 24px 32px;
      border-top: 1px solid #e0e0e0;
      display: flex;
      gap: 16px;
      justify-content: flex-end;
    }

    .cancel-btn {
      padding: 8px 24px;
      border-radius: 8px;
      color: #666;
      border: 1px solid #ddd;
    }

    .cancel-btn:hover {
      background: #f5f5f5;
    }

    .submit-btn {
      padding: 8px 32px;
      border-radius: 8px;
      font-weight: 600;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .submit-btn:disabled {
      background: #ccc;
      color: #666;
    }

    .loading-spinner {
      margin-right: 8px;
    }

    /* Focus states */
    .mat-mdc-form-field.mat-focused .mat-mdc-form-field-outline-thick {
      color: #667eea;
    }

    .mat-mdc-form-field.mat-focused .mat-mdc-floating-label {
      color: #667eea;
    }

    /* Image Upload Styles */
    .image-upload-area {
      position: relative;
      margin-top: 16px;
    }

    .upload-placeholder {
      border: 3px dashed #cbd5e1;
      border-radius: 12px;
      padding: 48px 32px;
      text-align: center;
      cursor: pointer;
      background: #f8fafc;
      transition: all 0.3s ease;
    }

    .upload-placeholder:hover {
      border-color: #667eea;
      background: #f0f4ff;
    }

    .upload-placeholder.dragover {
      border-color: #667eea;
      background: #e0e7ff;
      transform: scale(1.02);
    }

    .upload-icon {
      font-size: 64px !important;
      width: 64px !important;
      height: 64px !important;
      color: #94a3b8;
      margin-bottom: 16px;
    }

    .upload-placeholder h3 {
      margin: 0 0 8px 0;
      font-size: 20px;
      font-weight: 600;
      color: #334155;
    }

    .upload-placeholder p {
      margin: 0 0 8px 0;
      color: #64748b;
      font-size: 14px;
    }

    .file-info {
      display: block;
      font-size: 12px;
      color: #94a3b8;
    }

    .image-preview-container {
      position: relative;
      border: 1px solid #e2e8f0;
      border-radius: 12px;
      padding: 16px;
      background: white;
    }

    .preview-image {
      width: 100%;
      max-height: 300px;
      object-fit: contain;
      border-radius: 8px;
    }

    .image-actions {
      position: absolute;
      top: 24px;
      right: 24px;
      display: flex;
      gap: 8px;
    }

    .image-actions button {
      background: white;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .image-actions button mat-icon {
      font-size: 20px;
    }

    @media (max-width: 768px) {
      .form-wrapper {
        padding: 10px;
      }

      .form-card {
        margin: 10px;
        border-radius: 12px;
      }

      .form-content {
        padding: 20px;
      }

      .form-section {
        padding: 20px;
      }

      .form-grid {
        grid-template-columns: 1fr;
        gap: 16px;
      }

      .form-actions {
        padding: 20px;
        flex-direction: column-reverse;
      }

      .cancel-btn,
      .submit-btn {
        width: 100%;
        justify-content: center;
      }
    }
  `]
})
export class CategoryFormComponent implements OnInit {
  categoryForm: FormGroup;
  parentCategories: ProductCategory[] = [];
  isLoading = false;
  isEditMode = false;
  categoryId?: number;
  previewImageUrl: string | null = null;
  selectedImageFile: File | null = null;
  isDragging = false;

  constructor(
    private fb: FormBuilder,
    private categoryService: ProductCategoryService,
    private route: ActivatedRoute,
    private router: Router
  ) {
    this.categoryForm = this.createForm();
  }

  ngOnInit() {
    this.loadParentCategories();
    
    this.categoryId = this.route.snapshot.params['id'];
    if (this.categoryId) {
      this.isEditMode = true;
      this.loadCategory();
    }

    // Auto-generate slug from name
    this.categoryForm.get('name')?.valueChanges.subscribe(name => {
      if (name && !this.categoryForm.get('slug')?.value) {
        const slug = name.toLowerCase()
          .replace(/[^a-z0-9]+/g, '-')
          .replace(/^-|-$/g, '');
        this.categoryForm.get('slug')?.setValue(slug);
      }
    });
  }

  private createForm(): FormGroup {
    return this.fb.group({
      name: ['', [Validators.required, Validators.maxLength(255)]],
      description: [''],
      slug: [''],
      parentId: [null],
      isActive: [true],
      sortOrder: [0, [Validators.min(0)]],
      iconUrl: ['']
    });
  }

  private loadParentCategories() {
    this.categoryService.getRootCategories().subscribe({
      next: (categories) => {
        this.parentCategories = categories;
      },
      error: (error) => {
        console.error('Error loading parent categories:', error);
      }
    });
  }

  private loadCategory() {
    if (!this.categoryId) return;

    this.isLoading = true;
    this.categoryService.getCategory(this.categoryId).subscribe({
      next: (category) => {
        this.categoryForm.patchValue({
          name: category.name,
          description: category.description,
          slug: category.slug,
          parentId: category.parentId,
          isActive: category.isActive,
          sortOrder: category.sortOrder,
          iconUrl: category.iconUrl
        });
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading category:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Failed to load category',
          icon: 'error',
          confirmButtonText: 'OK'
        });
        this.isLoading = false;
      }
    });
  }

  onSubmit() {
    if (this.categoryForm.invalid) return;

    this.isLoading = true;

    // If there's an image file selected
    if (this.selectedImageFile) {
      if (this.isEditMode) {
        // In edit mode, first update the category, then upload the image
        this.updateCategoryThenUploadImage();
      } else {
        // In create mode, create category with image
        this.createCategoryWithImage();
      }
      return;
    }

    // No image file selected, proceed with normal create/update
    this.saveCategory();
  }

  private createCategoryWithImage() {
    const formData = new FormData();
    formData.append('name', this.categoryForm.get('name')?.value);
    formData.append('description', this.categoryForm.get('description')?.value || '');
    formData.append('slug', this.categoryForm.get('slug')?.value || '');
    formData.append('isActive', this.categoryForm.get('isActive')?.value.toString());
    formData.append('sortOrder', this.categoryForm.get('sortOrder')?.value.toString());

    if (this.categoryForm.get('parentId')?.value) {
      formData.append('parentId', this.categoryForm.get('parentId')?.value);
    }

    formData.append('image', this.selectedImageFile!);

    this.categoryService.createCategoryWithImage(formData).subscribe({
      next: () => {
        this.isLoading = false;
        Swal.fire({
          icon: 'success',
          title: 'Success!',
          text: 'Category created successfully with image!',
          timer: 2000,
          showConfirmButton: false
        });
        this.router.navigate(['/products/categories']);
      },
      error: (error) => {
        this.isLoading = false;
        Swal.fire({
          icon: 'error',
          title: 'Error',
          text: error.error?.message || 'Failed to create category'
        });
      }
    });
  }

  private updateCategoryThenUploadImage() {
    const formValue = this.categoryForm.value;
    const request: ProductCategoryRequest = {
      name: formValue.name,
      description: formValue.description || undefined,
      slug: formValue.slug || undefined,
      parentId: formValue.parentId || undefined,
      isActive: formValue.isActive,
      sortOrder: formValue.sortOrder || undefined,
      iconUrl: formValue.iconUrl || undefined
    };

    this.categoryService.updateCategory(this.categoryId!, request).subscribe({
      next: (category) => {
        // Now upload the image
        this.categoryService.uploadCategoryImage(this.categoryId!, this.selectedImageFile!).subscribe({
          next: () => {
            this.isLoading = false;
            Swal.fire({
              title: 'Success!',
              text: 'Category updated successfully with image!',
              icon: 'success',
              timer: 2000,
              showConfirmButton: false
            });
            this.router.navigate(['/products/categories']);
          },
          error: (error) => {
            this.isLoading = false;
            Swal.fire({
              title: 'Partial Success',
              text: 'Category updated but failed to upload image',
              icon: 'warning',
              confirmButtonText: 'OK'
            });
          }
        });
      },
      error: (error) => {
        this.isLoading = false;
        Swal.fire({
          title: 'Error!',
          text: error.error?.message || 'Failed to update category',
          icon: 'error',
          confirmButtonText: 'OK'
        });
      }
    });
  }

  private saveCategory() {
    const formValue = this.categoryForm.value;

    const request: ProductCategoryRequest = {
      name: formValue.name,
      description: formValue.description || undefined,
      slug: formValue.slug || undefined,
      parentId: formValue.parentId || undefined,
      isActive: formValue.isActive,
      sortOrder: formValue.sortOrder || undefined,
      iconUrl: formValue.iconUrl || undefined
    };

    const operation = this.isEditMode
      ? this.categoryService.updateCategory(this.categoryId!, request)
      : this.categoryService.createCategory(request);

    operation.subscribe({
      next: (category) => {
        Swal.fire({
          title: 'Success!',
          text: `Category ${this.isEditMode ? 'updated' : 'created'} successfully!`,
          icon: 'success',
          timer: 2000,
          showConfirmButton: false
        });
        this.router.navigate(['/products/categories']);
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error saving category:', error);
        let errorMessage = `Failed to ${this.isEditMode ? 'update' : 'create'} category`;
        if (error.error?.message) {
          errorMessage = error.error.message;
        }
        Swal.fire({
          title: 'Error!',
          text: errorMessage,
          icon: 'error',
          confirmButtonText: 'OK'
        });
        this.isLoading = false;
      }
    });
  }

  onCancel() {
    this.router.navigate(['/products/categories']);
  }

  onImageSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files[0]) {
      this.processImageFile(input.files[0]);
    }
  }

  onDragOver(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = true;
  }

  onDragLeave(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = false;
  }

  onDrop(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragging = false;

    const files = event.dataTransfer?.files;
    if (files && files.length > 0) {
      const file = files[0];
      if (file.type.startsWith('image/')) {
        this.processImageFile(file);
      } else {
        Swal.fire({
          icon: 'error',
          title: 'Invalid File',
          text: 'Please drop an image file'
        });
      }
    }
  }

  private processImageFile(file: File): void {
    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      Swal.fire({
        icon: 'error',
        title: 'File Too Large',
        text: 'Image size should be less than 5MB'
      });
      return;
    }

    // Validate file type
    const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (!validTypes.includes(file.type)) {
      Swal.fire({
        icon: 'error',
        title: 'Invalid File Type',
        text: 'Please select a valid image file (JPEG, PNG, GIF, or WebP)'
      });
      return;
    }

    this.selectedImageFile = file;

    // Clear icon URL if image is selected
    this.categoryForm.get('iconUrl')?.setValue('');

    // Create preview
    const reader = new FileReader();
    reader.onload = (e) => {
      this.previewImageUrl = e.target?.result as string;
    };
    reader.readAsDataURL(file);
  }

  removeImage(): void {
    this.selectedImageFile = null;
    this.previewImageUrl = null;
  }
}