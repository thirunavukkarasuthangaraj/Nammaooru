import { Component, Inject, OnInit } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';

export interface AssignmentDialogData {
  orderId: number;
  partners: any[];
}

@Component({
  selector: 'app-order-assignment-dialog',
  templateUrl: './order-assignment-dialog.component.html',
  styleUrls: ['./order-assignment-dialog.component.scss']
})
export class OrderAssignmentDialogComponent implements OnInit {
  assignmentForm: FormGroup;

  constructor(
    public dialogRef: MatDialogRef<OrderAssignmentDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: AssignmentDialogData,
    private fb: FormBuilder
  ) {
    this.assignmentForm = this.fb.group({
      partnerId: ['', Validators.required],
      estimatedDeliveryTime: ['', Validators.required],
      notes: ['']
    });
  }

  ngOnInit(): void {}

  onCancel(): void {
    this.dialogRef.close();
  }

  onAssign(): void {
    if (this.assignmentForm.valid) {
      this.dialogRef.close({
        orderId: this.data.orderId,
        ...this.assignmentForm.value
      });
    }
  }
}