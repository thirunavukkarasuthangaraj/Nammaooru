import { Component, Inject, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { PromoCodeService } from '../../../../core/services/promo-code.service';
import { PromoCode, CreatePromoCodeRequest } from '../../../../core/models/promo-code.model';

@Component({
  selector: 'app-promo-code-form',
  templateUrl: './promo-code-form.component.html',
  styleUrls: ['./promo-code-form.component.css']
})
export class PromoCodeFormComponent implements OnInit {
  promoForm!: FormGroup;
  isEditMode = false;
  isLoading = false;
  discountTypes = [
    { value: 'PERCENTAGE', label: 'Percentage Discount', icon: 'percent' },
    { value: 'FIXED_AMOUNT', label: 'Fixed Amount', icon: 'attach_money' },
    { value: 'FREE_SHIPPING', label: 'Free Delivery', icon: 'local_shipping' }
  ];
  statusOptions = [
    { value: 'ACTIVE', label: 'Active', color: 'primary' },
    { value: 'INACTIVE', label: 'Inactive', color: 'warn' }
  ];

  constructor(
    private fb: FormBuilder,
    private promoCodeService: PromoCodeService,
    private snackBar: MatSnackBar,
    public dialogRef: MatDialogRef<PromoCodeFormComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { mode: 'create' | 'edit'; promoCode?: PromoCode }
  ) {
    this.isEditMode = data.mode === 'edit';
  }

  ngOnInit(): void {
    this.initForm();
    if (this.isEditMode && this.data.promoCode) {
      this.populateForm(this.data.promoCode);
    }
  }

  initForm(): void {
    const today = new Date();
    const nextMonth = new Date();
    nextMonth.setMonth(nextMonth.getMonth() + 1);

    this.promoForm = this.fb.group({
      code: ['', [
        Validators.required,
        Validators.pattern(/^[A-Z0-9]+$/),
        Validators.minLength(4),
        Validators.maxLength(20)
      ]],
      title: ['', [Validators.required, Validators.maxLength(100)]],
      description: ['', Validators.maxLength(500)],
      type: ['PERCENTAGE', Validators.required],
      discountValue: [0, [Validators.required, Validators.min(0)]],
      minimumOrderAmount: [0, Validators.min(0)],
      maximumDiscountAmount: [null],
      startDate: [today, Validators.required],
      endDate: [nextMonth, Validators.required],
      status: ['ACTIVE', Validators.required],
      usageLimit: [null, Validators.min(1)],
      usageLimitPerCustomer: [null, Validators.min(1)],
      firstTimeOnly: [false],
      applicableToAllShops: [true],
      imageUrl: ['']
    });

    // Add validation for discount value based on type
    this.promoForm.get('type')?.valueChanges.subscribe(type => {
      const discountControl = this.promoForm.get('discountValue');
      if (type === 'PERCENTAGE') {
        discountControl?.setValidators([Validators.required, Validators.min(0), Validators.max(100)]);
      } else {
        discountControl?.setValidators([Validators.required, Validators.min(0)]);
      }
      discountControl?.updateValueAndValidity();
    });

    // Disable code field in edit mode
    if (this.isEditMode) {
      this.promoForm.get('code')?.disable();
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
      status: promo.status,
      usageLimit: promo.usageLimit,
      usageLimitPerCustomer: promo.usageLimitPerCustomer,
      firstTimeOnly: promo.firstTimeOnly,
      applicableToAllShops: promo.applicableToAllShops,
      imageUrl: promo.imageUrl
    });
  }

  onSubmit(): void {
    if (this.promoForm.valid) {
      this.isLoading = true;

      // Get form value and re-enable code field to include it
      const formValue = this.promoForm.getRawValue();

      const formData: CreatePromoCodeRequest = {
        ...formValue,
        code: formValue.code.toUpperCase(),
        startDate: this.formatDateToISO(formValue.startDate),
        endDate: this.formatDateToISO(formValue.endDate)
      };

      const apiCall = this.isEditMode && this.data.promoCode
        ? this.promoCodeService.updatePromoCode(this.data.promoCode.id, formData)
        : this.promoCodeService.createPromoCode(formData);

      apiCall.subscribe({
        next: () => {
          this.isLoading = false;
          this.showSnackBar(
            this.isEditMode ? 'Promo code updated successfully' : 'Promo code created successfully',
            'success'
          );
          this.dialogRef.close(true);
        },
        error: (error) => {
          console.error('Error saving promo code:', error);
          this.isLoading = false;
          const errorMessage = error.error?.message || 'Failed to save promo code';
          this.showSnackBar(errorMessage, 'error');
        }
      });
    } else {
      this.markFormGroupTouched(this.promoForm);
      this.showSnackBar('Please fill all required fields correctly', 'error');
    }
  }

  formatDateToISO(date: Date): string {
    return date.toISOString();
  }

  markFormGroupTouched(formGroup: FormGroup): void {
    Object.keys(formGroup.controls).forEach(key => {
      const control = formGroup.get(key);
      control?.markAsTouched();
    });
  }

  getErrorMessage(fieldName: string): string {
    const control = this.promoForm.get(fieldName);
    if (control?.hasError('required')) {
      return 'This field is required';
    }
    if (control?.hasError('pattern')) {
      return 'Only uppercase letters and numbers allowed';
    }
    if (control?.hasError('minlength')) {
      return `Minimum ${control.errors?.['minlength'].requiredLength} characters`;
    }
    if (control?.hasError('maxlength')) {
      return `Maximum ${control.errors?.['maxlength'].requiredLength} characters`;
    }
    if (control?.hasError('min')) {
      return `Minimum value is ${control.errors?.['min'].min}`;
    }
    if (control?.hasError('max')) {
      return `Maximum value is ${control.errors?.['max'].max}`;
    }
    return '';
  }

  onCancel(): void {
    this.dialogRef.close(false);
  }

  generateRandomCode(): void {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    for (let i = 0; i < 8; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    this.promoForm.patchValue({ code });
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
