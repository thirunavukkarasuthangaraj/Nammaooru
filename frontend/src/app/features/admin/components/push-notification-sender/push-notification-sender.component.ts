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
  recipientTypes = ['ALL_CUSTOMERS', 'SPECIFIC_USER'];
  notificationTypes: string[] = [];
  priorities: string[] = [];

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
      recipientId: [null]
    });

    // Handle recipientId validation based on recipientType
    this.notificationForm.get('recipientType')?.valueChanges.subscribe(value => {
      const recipientIdControl = this.notificationForm.get('recipientId');
      if (value === 'SPECIFIC_USER') {
        recipientIdControl?.setValidators([Validators.required]);
      } else {
        recipientIdControl?.clearValidators();
        recipientIdControl?.setValue(null);
      }
      recipientIdControl?.updateValueAndValidity();
    });
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
