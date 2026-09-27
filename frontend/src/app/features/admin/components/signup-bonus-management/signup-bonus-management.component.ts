import { Component, OnInit } from '@angular/core';
import { SignupBonusService } from '../../services/signup-bonus.service';
import { SwalService } from '../../../../core/services/swal.service';

interface SignupBonusRow {
  id: number;
  mobileNumber: string;
  amount: number;
  status: 'UNPAID' | 'PAID';
  createdAt: string;
  // Local UI state
  referenceInput?: string;
}

@Component({
  selector: 'app-signup-bonus-management',
  templateUrl: './signup-bonus-management.component.html',
  styleUrls: ['./signup-bonus-management.component.scss']
})
export class SignupBonusManagementComponent implements OnInit {
  private static readonly SUCCESS_CODE = '0000';

  bonuses: SignupBonusRow[] = [];
  isLoading = false;
  processingId: number | null = null;

  enabled = false;
  amount = 10;
  reminderIntervalMinutes = 60;
  isSavingConfig = false;

  constructor(
    private signupBonusService: SignupBonusService,
    private swal: SwalService
  ) {}

  ngOnInit(): void {
    this.loadConfig();
    this.loadBonuses();
  }

  loadConfig(): void {
    this.signupBonusService.getConfig().subscribe({
      next: (response) => {
        if (this.isSuccess(response)) {
          this.enabled = response.data.enabled;
          this.amount = response.data.amount;
          this.reminderIntervalMinutes = response.data.reminderIntervalMinutes;
        }
      },
      error: (error) => console.error('Error loading signup bonus config:', error)
    });
  }

  loadBonuses(): void {
    this.isLoading = true;
    this.signupBonusService.getPending(0, 100).subscribe({
      next: (response) => {
        if (this.isSuccess(response)) {
          this.bonuses = response.data?.content || [];
        } else {
          this.swal.toast(response.message || 'Failed to load welcome bonuses', 'error');
        }
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading welcome bonuses:', error);
        this.swal.toast('Error loading welcome bonuses', 'error');
        this.isLoading = false;
      }
    });
  }

  // There's no reliable cross-app deep link for "pay by mobile number" (the
  // standard upi://pay intent needs a VPA, not a phone number, and support
  // for a bare number varies by app) - so this just copies the number for
  // you to paste into your own UPI app's "pay by mobile number" option.
  copyMobileNumber(row: SignupBonusRow): void {
    navigator.clipboard.writeText(row.mobileNumber).then(
      () => this.swal.toast('Mobile number copied', 'success'),
      () => this.swal.toast('Could not copy - copy it manually', 'warning')
    );
  }

  markPaid(row: SignupBonusRow): void {
    const reference = (row.referenceInput || '').trim();
    if (!reference) {
      this.swal.toast('Enter the UPI transaction reference first', 'warning');
      return;
    }
    this.processingId = row.id;
    this.signupBonusService.markPaid(row.id, reference).subscribe({
      next: (response) => {
        this.processingId = null;
        if (this.isSuccess(response)) {
          this.swal.toast(`Marked ${row.mobileNumber}'s welcome bonus as paid`, 'success');
          this.bonuses = this.bonuses.filter((b) => b.id !== row.id);
        } else {
          this.swal.toast(response.message || 'Failed to mark as paid', 'error');
        }
      },
      error: (error) => {
        this.processingId = null;
        console.error('Error marking welcome bonus paid:', error);
        this.swal.toast('Error marking welcome bonus as paid', 'error');
      }
    });
  }

  toggleEnabled(): void {
    this.isSavingConfig = true;
    this.signupBonusService.setEnabled(this.enabled).subscribe({
      next: (response) => {
        this.isSavingConfig = false;
        if (this.isSuccess(response)) {
          this.swal.toast(`Welcome bonus feature ${this.enabled ? 'enabled' : 'disabled'}`, 'success');
        } else {
          this.enabled = !this.enabled; // revert on failure
          this.swal.toast(response.message || 'Failed to update setting', 'error');
        }
      },
      error: () => {
        this.isSavingConfig = false;
        this.enabled = !this.enabled;
        this.swal.toast('Error updating setting', 'error');
      }
    });
  }

  saveAmount(): void {
    if (this.amount == null || this.amount < 0) {
      this.swal.toast('Enter a valid amount', 'warning');
      return;
    }
    this.isSavingConfig = true;
    this.signupBonusService.setAmount(this.amount).subscribe({
      next: (response) => {
        this.isSavingConfig = false;
        if (this.isSuccess(response)) {
          this.swal.toast('Welcome bonus amount updated', 'success');
        } else {
          this.swal.toast(response.message || 'Failed to update amount', 'error');
        }
      },
      error: () => {
        this.isSavingConfig = false;
        this.swal.toast('Error updating amount', 'error');
      }
    });
  }

  saveReminderInterval(): void {
    if (!this.reminderIntervalMinutes || this.reminderIntervalMinutes < 5) {
      this.swal.toast('Interval must be at least 5 minutes', 'warning');
      return;
    }
    this.isSavingConfig = true;
    this.signupBonusService.setReminderInterval(this.reminderIntervalMinutes).subscribe({
      next: (response) => {
        this.isSavingConfig = false;
        if (this.isSuccess(response)) {
          this.swal.toast('Reminder interval updated', 'success');
        } else {
          this.swal.toast(response.message || 'Failed to update interval', 'error');
        }
      },
      error: () => {
        this.isSavingConfig = false;
        this.swal.toast('Error updating interval', 'error');
      }
    });
  }

  private isSuccess(response: any): boolean {
    return response?.statusCode === SignupBonusManagementComponent.SUCCESS_CODE;
  }
}
