import { Component, Inject, OnInit } from '@angular/core';
import { AbstractControl, FormBuilder, FormGroup, ValidationErrors, ValidatorFn, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { PromoCodeService } from '../../../../core/services/promo-code.service';
import { SwalService } from '../../../../core/services/swal.service';
import { PromoCode, CreatePromoCodeRequest, PromoBannerType } from '../../../../core/models/promo-code.model';
import { environment } from '../../../../../environments/environment';

@Component({
  selector: 'app-promo-code-form',
  templateUrl: './promo-code-form.component.html',
  styleUrls: ['./promo-code-form.component.css']
})
export class PromoCodeFormComponent implements OnInit {
  promoForm!: FormGroup;
  isEditMode = false;
  isLoading = false;
  isUploading = false;
  isUploadingVideo = false;
  selectedFile: File | null = null;
  imagePreview: string | null = null;
  videoPreview: string | null = null;
  discountTypes = [
    { value: 'PERCENTAGE', label: 'Percentage Discount', icon: 'percent' },
    { value: 'FIXED_AMOUNT', label: 'Fixed Amount', icon: 'attach_money' },
    { value: 'FREE_SHIPPING', label: 'Free Delivery', icon: 'local_shipping' }
  ];
  statusOptions = [
    { value: 'ACTIVE', label: 'Active', color: 'primary' },
    { value: 'INACTIVE', label: 'Inactive', color: 'warn' }
  ];
  // Promo code (default) vs. image-only home banner. An image banner has no
  // code / discount / usage rules - just artwork, dates and an optional link.
  bannerTypeOptions: { value: PromoBannerType; label: string; icon: string; hint: string }[] = [
    { value: 'PROMO_CODE', label: 'Promo code', icon: 'confirmation_number', hint: 'A code customers apply at checkout for a discount' },
    { value: 'IMAGE_BANNER', label: 'Image banner', icon: 'image', hint: 'Image or video on the home carousel - no code, no discount' }
  ];

  constructor(
    private fb: FormBuilder,
    private promoCodeService: PromoCodeService,
    private swal: SwalService,
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
      bannerType: ['PROMO_CODE' as PromoBannerType, Validators.required],
      linkUrl: ['', [Validators.maxLength(500), Validators.pattern(/^(https?:\/\/|[a-z][a-z0-9+.-]*:\/\/).+/i)]],
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
      imageUrl: [''],
      videoUrl: ['']
    });

    // Add validation for discount value based on type
    this.promoForm.get('type')?.valueChanges.subscribe(type => {
      if (this.isImageBanner) {
        return; // discountValue carries no validators for an image banner
      }
      const discountControl = this.promoForm.get('discountValue');
      if (type === 'PERCENTAGE') {
        discountControl?.setValidators([Validators.required, Validators.min(0), Validators.max(100)]);
      } else {
        discountControl?.setValidators([Validators.required, Validators.min(0)]);
      }
      discountControl?.updateValueAndValidity();
    });

    this.promoForm.get('bannerType')?.valueChanges.subscribe((bannerType: PromoBannerType) => {
      this.applyBannerTypeValidators(bannerType);
    });

    // An image banner needs an image OR a video, so adding/removing the video
    // changes whether the (otherwise empty) image control is valid.
    this.promoForm.get('videoUrl')?.valueChanges.subscribe(() => {
      this.promoForm.get('imageUrl')?.updateValueAndValidity({ emitEvent: false });
    });

    // Disable code field in edit mode
    if (this.isEditMode) {
      this.promoForm.get('code')?.disable();
    }
  }

  get isImageBanner(): boolean {
    return this.promoForm?.get('bannerType')?.value === 'IMAGE_BANNER';
  }

  /** True when an image banner has neither an image nor a video yet. */
  get isBannerMediaMissing(): boolean {
    return this.isImageBanner && !!this.promoForm?.get('imageUrl')?.hasError('mediaRequired');
  }

  /**
   * Image-banner rule: the banner is its media, so at least one of image or
   * video must be present. Lives on the image control (so the existing
   * touched/invalid styling applies) but looks across at the video control.
   */
  private readonly imageOrVideoRequired: ValidatorFn = (control: AbstractControl): ValidationErrors | null => {
    const image = (control.value ?? '').toString().trim();
    const video = (control.parent?.get('videoUrl')?.value ?? '').toString().trim();
    return image || video ? null : { mediaRequired: true };
  };

  /**
   * Swap the required-ness of the two halves of the form. For an image banner
   * the code/discount/usage controls are irrelevant (and hidden) so they must
   * not block submit; the image itself becomes mandatory instead.
   */
  private applyBannerTypeValidators(bannerType: PromoBannerType): void {
    const code = this.promoForm.get('code');
    const type = this.promoForm.get('type');
    const discount = this.promoForm.get('discountValue');
    const minOrder = this.promoForm.get('minimumOrderAmount');
    const usageLimit = this.promoForm.get('usageLimit');
    const perCustomer = this.promoForm.get('usageLimitPerCustomer');
    const imageUrl = this.promoForm.get('imageUrl');

    if (bannerType === 'IMAGE_BANNER') {
      [code, type, discount, minOrder, usageLimit, perCustomer].forEach(c => {
        c?.clearValidators();
        c?.updateValueAndValidity({ emitEvent: false });
      });
      imageUrl?.setValidators([this.imageOrVideoRequired]);
      imageUrl?.updateValueAndValidity({ emitEvent: false });
    } else {
      code?.setValidators([
        Validators.required,
        Validators.pattern(/^[A-Z0-9]+$/),
        Validators.minLength(4),
        Validators.maxLength(20)
      ]);
      type?.setValidators([Validators.required]);
      discount?.setValidators(
        type?.value === 'PERCENTAGE'
          ? [Validators.required, Validators.min(0), Validators.max(100)]
          : [Validators.required, Validators.min(0)]
      );
      minOrder?.setValidators([Validators.min(0)]);
      usageLimit?.setValidators([Validators.min(1)]);
      perCustomer?.setValidators([Validators.min(1)]);
      imageUrl?.clearValidators();
      [code, type, discount, minOrder, usageLimit, perCustomer, imageUrl].forEach(c =>
        c?.updateValueAndValidity({ emitEvent: false })
      );
      // A promo code converted back from an image banner needs sane defaults
      // in the fields that were blanked.
      if (!type?.value) type?.setValue('PERCENTAGE', { emitEvent: false });
      if (discount?.value === null || discount?.value === undefined) discount?.setValue(0, { emitEvent: false });
    }
  }

  populateForm(promo: PromoCode): void {
    this.promoForm.patchValue({
      bannerType: promo.bannerType ?? 'PROMO_CODE',
      linkUrl: promo.linkUrl ?? '',
      code: promo.code ?? '',
      title: promo.title,
      description: promo.description,
      type: promo.type ?? 'PERCENTAGE',
      discountValue: promo.discountValue ?? 0,
      minimumOrderAmount: promo.minimumOrderAmount || 0,
      maximumDiscountAmount: promo.maximumDiscountAmount,
      startDate: new Date(promo.startDate),
      endDate: new Date(promo.endDate),
      status: promo.status,
      usageLimit: promo.usageLimit,
      usageLimitPerCustomer: promo.usageLimitPerCustomer,
      firstTimeOnly: promo.firstTimeOnly,
      // The API sends this as isPublic; reading only applicableToAllShops
      // left the box unchecked on every edit and un-published the promo on save.
      applicableToAllShops: promo.applicableToAllShops ?? promo.isPublic ?? true,
      imageUrl: promo.imageUrl,
      videoUrl: promo.videoUrl
    });

    // patchValue above already fired the bannerType subscription, but run it
    // once more now that every control holds its loaded value.
    this.applyBannerTypeValidators(promo.bannerType ?? 'PROMO_CODE');

    // Show existing image as preview when editing
    if (promo.imageUrl) {
      this.imagePreview = promo.imageUrl;
    }

    if (promo.videoUrl) {
      this.videoPreview = this.toMediaUrl(promo.videoUrl);
    }
  }

  /** Uploads come back as /uploads/... paths; the <video> tag needs an origin. */
  toMediaUrl(url: string): string {
    if (!url) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    const path = url.startsWith('/') ? url : `/${url}`;
    return `${environment.imageBaseUrl}${path.startsWith('/uploads/') ? path : '/uploads' + path}`;
  }

  onSubmit(): void {
    if (this.isUploading || this.isUploadingVideo) {
      this.showSnackBar('Please wait for the upload to finish', 'error');
      return;
    }
    if (this.promoForm.valid) {
      this.isLoading = true;

      // Get form value and re-enable code field to include it
      const formValue = this.promoForm.getRawValue();
      const bannerType: PromoBannerType = formValue.bannerType || 'PROMO_CODE';

      let formData: CreatePromoCodeRequest;
      if (bannerType === 'IMAGE_BANNER') {
        // No code, discount or usage rules travel with an image banner - the
        // server rejects them anyway, so only send what the banner is.
        const { code, type, discountValue, minimumOrderAmount, maximumDiscountAmount,
                usageLimit, usageLimitPerCustomer, firstTimeOnly, ...rest } = formValue;
        formData = {
          ...rest,
          bannerType,
          linkUrl: formValue.linkUrl?.trim() || null,
          startDate: this.formatDateToISO(formValue.startDate),
          endDate: this.formatDateToISO(formValue.endDate)
        };
      } else {
        const { linkUrl, ...rest } = formValue;
        formData = {
          ...rest,
          bannerType,
          code: (formValue.code || '').toUpperCase(),
          startDate: this.formatDateToISO(formValue.startDate),
          endDate: this.formatDateToISO(formValue.endDate)
        };
      }

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
      this.showSnackBar(
        this.isBannerMediaMissing
          ? 'A banner needs an image or a video - please upload one'
          : 'Please fill all required fields correctly',
        'error'
      );
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
      return fieldName === 'linkUrl'
        ? 'Enter a full URL, e.g. https://... or nammaooru://...'
        : 'Only uppercase letters and numbers allowed';
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

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files[0]) {
      const file = input.files[0];

      // Validate file type
      if (!file.type.startsWith('image/')) {
        this.showSnackBar('Please select an image file', 'error');
        return;
      }

      // Validate file size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        this.showSnackBar('Image size should be less than 5MB', 'error');
        return;
      }

      this.selectedFile = file;

      // Create preview
      const reader = new FileReader();
      reader.onload = (e) => {
        this.imagePreview = e.target?.result as string;
      };
      reader.readAsDataURL(file);

      // Upload immediately - previously this required a separate manual
      // "Upload" button click before saving, which was easy to miss: the
      // preview shown above already made it look attached, so clicking
      // Save/Update right after selecting a file saved the promo with no
      // image at all.
      this.uploadImage();
    }
  }

  uploadImage(): void {
    if (!this.selectedFile) return;

    this.isUploading = true;
    this.promoCodeService.uploadPromoImage(this.selectedFile).subscribe({
      next: (response) => {
        this.promoForm.patchValue({ imageUrl: response.imageUrl });
        this.isUploading = false;
        this.showSnackBar('Image uploaded successfully', 'success');
      },
      error: (error) => {
        console.error('Error uploading image:', error);
        this.isUploading = false;
        this.showSnackBar('Failed to upload image', 'error');
      }
    });
  }

  removeImage(): void {
    this.selectedFile = null;
    this.imagePreview = null;
    this.promoForm.patchValue({ imageUrl: '' });
  }

  onVideoSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (!input.files || !input.files[0]) return;
    const file = input.files[0];

    if (!file.type.startsWith('video/')) {
      this.showSnackBar('Please select a video file', 'error');
      return;
    }

    // Mirrors file.upload.max-video-size on the server.
    if (file.size > 30 * 1024 * 1024) {
      this.showSnackBar('Video size should be less than 30MB', 'error');
      return;
    }

    this.isUploadingVideo = true;
    this.promoCodeService.uploadPromoVideo(file).subscribe({
      next: (response) => {
        this.promoForm.patchValue({ videoUrl: response.videoUrl });
        this.videoPreview = this.toMediaUrl(response.videoUrl);
        this.isUploadingVideo = false;
        // An admin is the approver, so this one goes live on save with no
        // second review - unlike a shop owner's, which queues as PENDING.
        this.showSnackBar('Video uploaded - it goes live on the home banner when you save', 'success');
      },
      error: (error) => {
        console.error('Error uploading video:', error);
        this.isUploadingVideo = false;
        this.showSnackBar(error.error?.message || 'Failed to upload video', 'error');
      }
    });
  }

  removeVideo(): void {
    this.videoPreview = null;
    this.promoForm.patchValue({ videoUrl: '' });
  }

  private showSnackBar(message: string, type: 'success' | 'error'): void {
    this.swal.toast(message, type);
  }
}
