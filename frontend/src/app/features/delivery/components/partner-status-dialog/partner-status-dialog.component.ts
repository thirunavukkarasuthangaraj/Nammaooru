import { Component, Inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';

export interface DialogData {
  partnerId: number;
  partnerName: string;
  currentStatus: string;
}

@Component({
  selector: 'app-partner-status-dialog',
  templateUrl: './partner-status-dialog.component.html',
  styleUrls: ['./partner-status-dialog.component.scss']
})
export class PartnerStatusDialogComponent {
  availableStatuses = [
    { value: 'PENDING', label: 'Pending Approval' },
    { value: 'APPROVED', label: 'Approved' },
    { value: 'ACTIVE', label: 'Active' },
    { value: 'INACTIVE', label: 'Inactive' },
    { value: 'SUSPENDED', label: 'Suspended' }
  ];

  selectedStatus: string;

  constructor(
    public dialogRef: MatDialogRef<PartnerStatusDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: DialogData
  ) {
    this.selectedStatus = data.currentStatus;
  }

  onCancel(): void {
    this.dialogRef.close();
  }

  onConfirm(): void {
    this.dialogRef.close({
      partnerId: this.data.partnerId,
      newStatus: this.selectedStatus
    });
  }
}