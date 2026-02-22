import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { PushNotificationService, PushNotificationRequest } from '../../../../core/services/push-notification.service';

@Component({
  selector: 'app-push-notification-sender',
  templateUrl: './push-notification-sender.component.html',
  styleUrls: ['./push-notification-sender.component.scss']
})
export class PushNotificationSenderComponent implements OnInit {
  notificationForm!: FormGroup;
  loading = false;
  uploading = false;
  useLocationFilter = false;
  recipientTypes = ['ALL_CUSTOMERS', 'SPECIFIC_USER'];
  notificationTypes: string[] = [];
  priorities: string[] = [];
  radiusOptions = [5, 10, 25, 50, 100];

  // Image upload
  selectedFile: File | null = null;
  imagePreview: string | null = null;
  uploadedImageUrl: string | null = null;

  constructor(
    private fb: FormBuilder,
    private pushNotificationService: PushNotificationService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.initializeForm();
    this.loadEnums();
  }

  private initializeForm(): void {
    this.notificationForm = this.fb.group({
      title: ['', [Validators.required, Validators.maxLength(100)]],
      message: ['', [Validators.required, Validators.maxLength(500)]],
      priority: ['HIGH', Validators.required],
      type: ['INFO', Validators.required],
      recipientType: ['ALL_CUSTOMERS', Validators.required],
      recipientId: [null],
      latitude: [null],
      longitude: [null],
      radiusKm: [25]
    });

    // Handle recipientId validation based on recipientType
    this.notificationForm.get('recipientType')?.valueChanges.subscribe(value => {
      const recipientIdControl = this.notificationForm.get('recipientId');
      if (value === 'SPECIFIC_USER') {
        recipientIdControl?.setValidators([Validators.required]);
        this.useLocationFilter = false;
      } else {
        recipientIdControl?.clearValidators();
        recipientIdControl?.setValue(null);
      }
      recipientIdControl?.updateValueAndValidity();
    });
  }

  toggleLocationFilter(): void {
    this.useLocationFilter = !this.useLocationFilter;
    if (!this.useLocationFilter) {
      this.notificationForm.patchValue({ latitude: null, longitude: null });
    }
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files[0]) {
      const file = input.files[0];

      // Validate file type
      if (!file.type.startsWith('image/')) {
        this.snackBar.open('Please select an image file', 'Close', {
          duration: 3000,
          panelClass: ['error-snackbar']
        });
        return;
      }

      // Validate file size (max 2MB)
      if (file.size > 2 * 1024 * 1024) {
        this.snackBar.open('Image size must be less than 2MB', 'Close', {
          duration: 3000,
          panelClass: ['error-snackbar']
        });
        return;
      }

      this.selectedFile = file;

      // Show preview
      const reader = new FileReader();
      reader.onload = () => {
        this.imagePreview = reader.result as string;
      };
      reader.readAsDataURL(file);

      // Upload immediately
      this.uploadImage(file);
    }
  }

  uploadImage(file: File): void {
    this.uploading = true;
    this.pushNotificationService.uploadNotificationImage(file).subscribe({
      next: (response) => {
        this.uploading = false;
        this.uploadedImageUrl = response.url;
        this.snackBar.open('Image uploaded successfully', 'Close', {
          duration: 2000,
          panelClass: ['success-snackbar']
        });
      },
      error: (error) => {
        this.uploading = false;
        console.error('Image upload failed:', error);
        this.snackBar.open('Failed to upload image', 'Close', {
          duration: 3000,
          panelClass: ['error-snackbar']
        });
        this.removeImage();
      }
    });
  }

  removeImage(): void {
    this.selectedFile = null;
    this.imagePreview = null;
    this.uploadedImageUrl = null;
  }

  private loadEnums(): void {
    this.pushNotificationService.getNotificationEnums().subscribe({
      next: (enums) => {
        this.notificationTypes = enums.notificationTypes || ['REMINDER', 'SUCCESS', 'PAYMENT', 'ANNOUNCEMENT', 'ERROR', 'ORDER_UPDATE', 'WARNING', 'ORDER', 'SYSTEM', 'PROMOTION', 'INFO'];
        this.priorities = enums.notificationPriorities || ['HIGH', 'MEDIUM', 'LOW'];
      },
      error: (error) => {
        console.error('Error loading enums:', error);
        // Use defaults
        this.notificationTypes = ['REMINDER', 'SUCCESS', 'PAYMENT', 'ANNOUNCEMENT', 'ERROR', 'ORDER_UPDATE', 'WARNING', 'ORDER', 'SYSTEM', 'PROMOTION', 'INFO'];
        this.priorities = ['HIGH', 'MEDIUM', 'LOW'];
      }
    });
  }

  onSubmit(): void {
    if (this.notificationForm.invalid) {
      this.markFormGroupTouched(this.notificationForm);
      return;
    }

    if (this.uploading) {
      this.snackBar.open('Please wait for image upload to complete', 'Close', {
        duration: 3000,
        panelClass: ['error-snackbar']
      });
      return;
    }

    this.loading = true;
    const formValue = this.notificationForm.value;
    const request: PushNotificationRequest = {
      title: formValue.title,
      message: formValue.message,
      priority: formValue.priority,
      type: formValue.type,
      recipientType: formValue.recipientType,
      recipientId: formValue.recipientId,
      sendPush: true
    };

    // Add image URL if uploaded
    if (this.uploadedImageUrl) {
      request.imageUrl = this.uploadedImageUrl;
    }

    // Add location targeting if enabled
    if (this.useLocationFilter && formValue.latitude && formValue.longitude && formValue.radiusKm) {
      request.latitude = formValue.latitude;
      request.longitude = formValue.longitude;
      request.radiusKm = formValue.radiusKm;
    }

    const sendObservable = request.recipientType === 'ALL_CUSTOMERS'
      ? this.pushNotificationService.sendBroadcastNotification(request)
      : this.pushNotificationService.sendNotificationToUser(request);

    sendObservable.subscribe({
      next: (response) => {
        this.loading = false;
        this.snackBar.open('Push notification sent successfully!', 'Close', {
          duration: 3000,
          panelClass: ['success-snackbar']
        });
        this.notificationForm.reset({
          priority: 'HIGH',
          type: 'INFO',
          recipientType: 'ALL_CUSTOMERS'
        });
        this.removeImage();
      },
      error: (error) => {
        this.loading = false;
        console.error('Error sending notification:', error);
        const errorMessage = error.error?.message || 'Failed to send push notification';
        this.snackBar.open(errorMessage, 'Close', {
          duration: 5000,
          panelClass: ['error-snackbar']
        });
      }
    });
  }

  private markFormGroupTouched(formGroup: FormGroup): void {
    Object.keys(formGroup.controls).forEach(key => {
      const control = formGroup.get(key);
      control?.markAsTouched();
      if (control instanceof FormGroup) {
        this.markFormGroupTouched(control);
      }
    });
  }

  get isSpecificUser(): boolean {
    return this.notificationForm.get('recipientType')?.value === 'SPECIFIC_USER';
  }
}
