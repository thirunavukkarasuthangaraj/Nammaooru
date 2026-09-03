import { Component, OnInit } from '@angular/core';
import { WithdrawalService } from '../../services/withdrawal.service';
import { SwalService } from '../../../../core/services/swal.service';

interface WithdrawalRow {
  id: number;
  amount: number;
  status: string;
  requestedAt: string;
  notes: string | null;
  ownerType: 'SHOP' | 'DELIVERY_PARTNER';
  ownerId: number;
  ownerName: string;
  payoutMethod: 'BANK_ACCOUNT' | 'UPI' | null;
  upiId: string | null;
  bankAccountHolderName: string | null;
  bankAccountNumber: string | null;
  bankIfsc: string | null;
  payoutDetailsVerified: boolean;
  // Local UI state
  referenceInput?: string;
  showRejectInput?: boolean;
  rejectReasonInput?: string;
}

@Component({
  selector: 'app-withdrawal-management',
  templateUrl: './withdrawal-management.component.html',
  styleUrls: ['./withdrawal-management.component.scss']
})
export class WithdrawalManagementComponent implements OnInit {
  private static readonly SUCCESS_CODE = '0000';

  withdrawals: WithdrawalRow[] = [];
  isLoading = false;
  processingId: number | null = null;

  constructor(
    private withdrawalService: WithdrawalService,
    private swal: SwalService
  ) {}

  ngOnInit(): void {
    this.loadWithdrawals();
  }

  loadWithdrawals(): void {
    this.isLoading = true;
    this.withdrawalService.getPendingWithdrawals(0, 100).subscribe({
      next: (response) => {
        if (response.statusCode === WithdrawalManagementComponent.SUCCESS_CODE) {
          this.withdrawals = response.data?.content || [];
        } else {
          this.swal.toast(response.message || 'Failed to load withdrawals', 'error');
        }
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading withdrawals:', error);
        this.swal.toast('Error loading withdrawals', 'error');
        this.isLoading = false;
      }
    });
  }

  // Deep-links into whatever UPI app is installed (GPay/PhonePe/Paytm/etc) with
  // the amount and payee pre-filled - the admin still taps to confirm and send
  // from their own account, this just removes the manual copy-paste steps.
  // Only works from a device with a UPI app installed (i.e. a phone), not desktop.
  payViaUpi(row: WithdrawalRow): void {
    if (!row.upiId) return;
    const params = new URLSearchParams({
      pa: row.upiId,
      pn: row.ownerName,
      am: row.amount.toFixed(2),
      cu: 'INR',
      tn: `Nammaooru payout #${row.id}`
    });
    window.open(`upi://pay?${params.toString()}`, '_blank');
  }

  markPaid(row: WithdrawalRow): void {
    const reference = (row.referenceInput || '').trim();
    if (!reference) {
      this.swal.toast('Enter the UTR / transaction reference first', 'warning');
      return;
    }
    this.processingId = row.id;
    this.withdrawalService.markPaid(row.id, reference).subscribe({
      next: (response) => {
        this.processingId = null;
        if (response.statusCode === WithdrawalManagementComponent.SUCCESS_CODE) {
          this.swal.toast(`Marked ${row.ownerName}'s withdrawal as paid`, 'success');
          this.withdrawals = this.withdrawals.filter((w) => w.id !== row.id);
        } else {
          this.swal.toast(response.message || 'Failed to mark as paid', 'error');
        }
      },
      error: (error) => {
        this.processingId = null;
        console.error('Error marking withdrawal paid:', error);
        this.swal.toast('Error marking withdrawal as paid', 'error');
      }
    });
  }

  toggleReject(row: WithdrawalRow): void {
    row.showRejectInput = !row.showRejectInput;
  }

  confirmReject(row: WithdrawalRow): void {
    this.processingId = row.id;
    this.withdrawalService.reject(row.id, (row.rejectReasonInput || '').trim()).subscribe({
      next: (response) => {
        this.processingId = null;
        if (response.statusCode === WithdrawalManagementComponent.SUCCESS_CODE) {
          this.swal.toast(`Rejected ${row.ownerName}'s withdrawal`, 'success');
          this.withdrawals = this.withdrawals.filter((w) => w.id !== row.id);
        } else {
          this.swal.toast(response.message || 'Failed to reject', 'error');
        }
      },
      error: (error) => {
        this.processingId = null;
        console.error('Error rejecting withdrawal:', error);
        this.swal.toast('Error rejecting withdrawal', 'error');
      }
    });
  }

  ownerTypeLabel(type: string): string {
    return type === 'SHOP' ? 'Shop' : 'Delivery Partner';
  }
}
