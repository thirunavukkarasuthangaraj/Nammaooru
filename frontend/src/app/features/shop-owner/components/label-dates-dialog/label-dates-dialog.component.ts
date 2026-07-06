import { Component, Inject } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';

export interface LabelDatesDialogData {
  productName?: string;
  packedDate?: string;  // ISO yyyy-mm-dd
  expiryDate?: string;  // ISO yyyy-mm-dd
}

export interface LabelDatesDialogResult {
  packedDate: string;
  expiryDate: string;   // '' = no expiry printed
}

/**
 * Asked every time "Print Label" is clicked: pack date (defaults to today) and
 * expiry date, with quick buttons that add a period to the pack date.
 * Returns the dates on "Print", or undefined when cancelled.
 */
@Component({
  selector: 'app-label-dates-dialog',
  template: `
    <h2 mat-dialog-title>
      <mat-icon>event_busy</mat-icon>
      Label Dates
    </h2>
    <mat-dialog-content>
      <p class="product-name" *ngIf="data?.productName">{{ data.productName }}</p>

      <div class="date-row">
        <mat-form-field appearance="outline">
          <mat-label>Pack Date</mat-label>
          <input matInput type="date" [(ngModel)]="packedDate">
        </mat-form-field>
        <mat-form-field appearance="outline">
          <mat-label>Expiry Date</mat-label>
          <input matInput type="date" [(ngModel)]="expiryDate" [min]="packedDate || today">
        </mat-form-field>
      </div>

      <div class="quick">
        <span class="quick-title">Expiry from pack date:</span>
        <div class="quick-buttons">
          <button mat-stroked-button *ngFor="let q of quickOptions" (click)="applyQuick(q)">
            {{ q.label }}
          </button>
          <button mat-stroked-button color="warn" (click)="expiryDate = ''">No expiry</button>
        </div>
      </div>
    </mat-dialog-content>
    <mat-dialog-actions align="end">
      <button mat-button (click)="cancel()">Cancel</button>
      <button mat-raised-button color="primary" (click)="print()">
        <mat-icon>print</mat-icon> Print
      </button>
    </mat-dialog-actions>
  `,
  styles: [`
    h2 { display: flex; align-items: center; gap: 8px; }
    .product-name { margin: 0 0 12px; font-weight: 600; color: #444; }
    .date-row { display: flex; gap: 12px; flex-wrap: wrap; }
    .date-row mat-form-field { flex: 1 1 160px; }
    .quick-title { font-size: 12px; color: #777; display: block; margin-bottom: 6px; }
    .quick-buttons { display: flex; gap: 6px; flex-wrap: wrap; }
    .quick-buttons button { line-height: 30px; padding: 0 10px; }
  `]
})
export class LabelDatesDialogComponent {

  today = this.toIso(new Date());
  packedDate: string;
  expiryDate: string;

  quickOptions: { label: string; days?: number; months?: number }[] = [
    { label: '1 Week', days: 7 },
    { label: '15 Days', days: 15 },
    { label: '1 Month', months: 1 },
    { label: '3 Months', months: 3 },
    { label: '6 Months', months: 6 },
    { label: '1 Year', months: 12 }
  ];

  constructor(
    private dialogRef: MatDialogRef<LabelDatesDialogComponent, LabelDatesDialogResult>,
    @Inject(MAT_DIALOG_DATA) public data: LabelDatesDialogData
  ) {
    this.packedDate = data?.packedDate || this.today;
    this.expiryDate = data?.expiryDate || '';
  }

  /** Set expiry = pack date (today by default) + the chosen period. */
  applyQuick(q: { days?: number; months?: number }): void {
    const base = this.parseIso(this.packedDate) || new Date();
    if (q.days) {
      base.setDate(base.getDate() + q.days);
    }
    if (q.months) {
      base.setMonth(base.getMonth() + q.months);
    }
    this.expiryDate = this.toIso(base);
  }

  print(): void {
    this.dialogRef.close({ packedDate: this.packedDate || '', expiryDate: this.expiryDate || '' });
  }

  cancel(): void {
    this.dialogRef.close();
  }

  private toIso(d: Date): string {
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${d.getFullYear()}-${m}-${day}`;
  }

  private parseIso(value?: string): Date | null {
    if (!value) {
      return null;
    }
    const m = value.match(/^(\d{4})-(\d{2})-(\d{2})$/);
    return m ? new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3])) : null;
  }
}
