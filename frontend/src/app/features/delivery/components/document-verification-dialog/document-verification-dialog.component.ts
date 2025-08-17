import { Component, Inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';

export interface DocumentVerificationDialogData {
  partnerId: number;
  documents: any[];
}

@Component({
  selector: 'app-document-verification-dialog',
  templateUrl: './document-verification-dialog.component.html',
  styleUrls: ['./document-verification-dialog.component.scss']
})
export class DocumentVerificationDialogComponent {
  constructor(
    public dialogRef: MatDialogRef<DocumentVerificationDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: DocumentVerificationDialogData
  ) {}

  onApprove(): void {
    this.dialogRef.close({ action: 'approve' });
  }

  onReject(): void {
    this.dialogRef.close({ action: 'reject' });
  }

  onClose(): void {
    this.dialogRef.close();
  }
}