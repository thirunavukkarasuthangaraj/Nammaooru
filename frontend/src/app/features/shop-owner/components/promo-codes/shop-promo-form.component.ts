import { Component, Inject, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';
import { PromoCode } from './shop-promo-list.component';

@Component({
  selector: 'app-shop-promo-form',
  templateUrl: './shop-promo-form.component.html',
  styleUrls: ['./shop-promo-form.component.css']
})
export class ShopPromoFormComponent implements OnInit {
  promoForm!: FormGroup;
  isEditMode = false;
  isSaving = false;
  isUploading = false;
  imagePreview: string | null = null;

  promoTypes = [
    { value: 'PERCENTAGE', label: 'Percentage Discount' },
    { value: 'FIXED_AMOUNT', label: 'Fixed Amount Off' },
    { value: 'FREE_SHIPPING', label: 'Free Delivery' }
  ];

  constructor(
    private fb: FormBuilder,
    private http: HttpClient,
    private snackBar: MatSnackBar,
    public dialogRef: MatDialogRef<ShopPromoFormComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { mode: 'create' | 'edit'; promo?: PromoCode; shopId: number }
  ) {
    this.isEditMode = data.mode === 'edit';
  }

  ngOnInit(): void {
    this.initForm();
    if (this.isEditMode && this.data.promo) {
      this.populateForm(this.data.promo);
    }
  }

  initForm(): void {
    const today = new Date();
    const nextMonth = new Date();
    nextMonth.setMonth(nextMonth.getMonth() + 1);

    this.promoForm = this.fb.group({
      code: ['', [Validators.required, Validators.minLength(4), Validators.maxLength(20), Validators.pattern(/^[A-Z0-9]+$/)]],
      title: ['', [Validators.required, Validators.maxLength(100)]],
      description: ['', Validators.maxLength(500)],
      type: ['PERCENTAGE', Validators.required],
      discountValue: [10, [Validators.required, Validators.min(1)]],
      minimumOrderAmount: [0],
      maximumDiscountAmount: [null],
      startDate: [today, Validators.required],
      endDate: [nextMonth, Validators.required],
      usageLimit: [null],
      usageLimitPerCustomer: [1],
      firstTimeOnly: [false],
      imageUrl: ['']
    });

    // Auto-generate code when title changes (only in create mode)
    if (!this.isEditMode) {
      this.promoForm.get('title')?.valueChanges.subscribe(title => {
        if (title && !this.promoForm.get('code')?.dirty) {
          const code = title.toUpperCase().replace(/[^A-Z0-9]/g, '').substring(0, 10);
          this.promoForm.patchValue({ code }, { emitEvent: false });
        }
      });
    }
  }

  populateForm(promo: PromoCode): void {
    this.promoForm.patchValue({
      code: promo.code,
      title: promo.title,
      description: promo.description,
      type: promo.type,
      discountValue: promo.discountValue,
      minimumOrderAmount: promo.minimumOrderAmount || 0,
      maximumDiscountAmount: promo.maximumDiscountAmount,
      startDate: new Date(promo.startDate),
      endDate: new Date(promo.endDate),
      usageLimit: promo.usageLimit,
      usageLimitPerCustomer: promo.usageLimitPerCustomer || 1,
      firstTimeOnly: promo.firstTimeOnly,
      imageUrl: promo.imageUrl
    });

    if (promo.imageUrl) {
      this.imagePreview = this.getImageUrl(promo.imageUrl);
    }
  }

  getImageUrl(imageUrl: string): string {
    if (!imageUrl) return '';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    let cleanPath = imageUrl.startsWith('/') ? imageUrl : '/' + imageUrl;
    // Add /uploads prefix if not already present
    if (!cleanPath.startsWith('/uploads/')) {
      cleanPath = '/uploads' + cleanPath;
    }
    return `${environment.imageBaseUrl}${cleanPath}`;
  }

  onFileSelected(event: any): void {
    const file = event.target.files[0];
    if (!file) return;

    // Validate file type
    if (!file.type.startsWith('image/')) {
      this.showSnackBar('Please select an image file', 'error');
      return;
    }

    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      this.showSnackBar('Image must be less than 5MB', 'error');
      return;
    }

    this.uploadImage(file);
  }

  uploadImage(file: File): void {
    this.isUploading = true;
    const formData = new FormData();
    formData.append('file', file);

    this.http.post<any>(`${environment.apiUrl}/uploads/promotion`, formData).subscribe({
      next: (response) => {
        const imageUrl = response.url || response.path || response.data?.url;
        this.promoForm.patchValue({ imageUrl });
        this.imagePreview = this.getImageUrl(imageUrl);
        this.isUploading = false;
        this.showSnackBar('Image uploaded', 'success');
      },
      error: (error) => {
        this.isUploading = false;
        this.showSnackBar(error.error?.message || 'Failed to upload image', 'error');
      }
    });
  }

  removeImage(): void {
    this.promoForm.patchValue({ imageUrl: '' });
    this.imagePreview = null;
  }

  onImageError(event: Event): void {
    console.log('Image failed to load');
    // Keep the preview area visible so user can remove it
  }

  generateCode(): void {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    for (let i = 0; i < 8; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    this.promoForm.patchValue({ code });
  }

  onSubmit(): void {
    if (this.promoForm.invalid) {
      this.markFormGroupTouched(this.promoForm);
      this.showSnackBar('Please fill all required fields', 'error');
      return;
    }

    this.isSaving = true;
    const formValue = this.promoForm.value;

    const payload = {
      code: formValue.code.toUpperCase(),
      title: formValue.title,
      description: formValue.description || null,
      type: formValue.type,
      discountValue: formValue.discountValue,
      minimumOrderAmount: formValue.minimumOrderAmount || 0,
      maximumDiscountAmount: formValue.maximumDiscountAmount || null,
      startDate: formValue.startDate.toISOString(),
      endDate: formValue.endDate.toISOString(),
      usageLimit: formValue.usageLimit || null,
      usageLimitPerCustomer: formValue.usageLimitPerCustomer || 1,
      firstTimeOnly: formValue.firstTimeOnly,
      imageUrl: formValue.imageUrl || null,
      status: 'ACTIVE'
    };

    const url = this.isEditMode
      ? `${environment.apiUrl}/shop-owner/promotions/${this.data.promo?.id}`
      : `${environment.apiUrl}/shop-owner/promotions`;

    const request = this.isEditMode
      ? this.http.put(url, payload)
      : this.http.post(url, payload);

    request.subscribe({
      next: () => {
        this.isSaving = false;
        this.showSnackBar(
          this.isEditMode ? 'Promo code updated!' : 'Promo code created!',
          'success'
        );
        this.dialogRef.close(true);
      },
      error: (error) => {
        this.isSaving = false;
        const message = error.error?.message || 'Failed to save promo code';
        this.showSnackBar(message, 'error');
      }
    });
  }

  markFormGroupTouched(formGroup: FormGroup): void {
    Object.keys(formGroup.controls).forEach(key => {
      const control = formGroup.get(key);
      control?.markAsTouched();
    });
  }

  onCancel(): void {
    this.dialogRef.close(false);
  }

  private showSnackBar(message: string, type: 'success' | 'error'): void {
    this.snackBar.open(message, 'Close', {
      duration: 3000,
      horizontalPosition: 'end',
      verticalPosition: 'top',
      panelClass: type === 'success' ? 'snackbar-success' : 'snackbar-error'
    });
  }
}
