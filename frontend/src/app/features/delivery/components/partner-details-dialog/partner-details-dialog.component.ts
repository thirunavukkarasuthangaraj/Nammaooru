import { Component, Inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';

export interface PartnerDetailsDialogData {
  partnerId: number;
  partnerData: any;
}

@Component({
  selector: 'app-partner-details-dialog',
  templateUrl: './partner-details-dialog.component.html',
  styleUrls: ['./partner-details-dialog.component.scss']
})
export class PartnerDetailsDialogComponent {
  constructor(
    public dialogRef: MatDialogRef<PartnerDetailsDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: PartnerDetailsDialogData
  ) {}

  onClose(): void {
    this.dialogRef.close();
  }
}