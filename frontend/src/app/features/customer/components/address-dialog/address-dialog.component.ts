import { Component, Inject, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { DeliveryLocation } from '../../services/address.service';

@Component({
  selector: 'app-address-dialog',
  templateUrl: './address-dialog.component.html',
  styleUrls: ['./address-dialog.component.scss']
})
export class AddressDialogComponent implements OnInit {
  addressForm!: FormGroup;
  isEditMode = false;
  dialogTitle = 'Add New Address';

  addressTypes = [
    { value: 'Home', label: 'Home' },
    { value: 'Work', label: 'Work' },
    { value: 'Other', label: 'Other' }
  ];

  constructor(
    private fb: FormBuilder,
    public dialogRef: MatDialogRef<AddressDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: DeliveryLocation | null
  ) {}

  ngOnInit(): void {
    this.isEditMode = !!this.data?.id;
    this.dialogTitle = this.isEditMode ? 'Edit Address' : 'Add New Address';

    this.addressForm = this.fb.group({
      addressType: [this.data?.addressType || 'Home', Validators.required],
      contactPersonName: [this.data?.contactPersonName || '', Validators.required],
      contactMobileNumber: [
        this.data?.contactMobileNumber || '',
        [Validators.required, Validators.pattern(/^[6-9]\d{9}$/)]
      ],
      flatHouse: [this.data?.flatHouse || ''],
      floor: [this.data?.floor || ''],
      street: [this.data?.street || ''],
      area: [this.data?.area || '', Validators.required],
      village: [this.data?.village || ''],
      landmark: [this.data?.landmark || ''],
      city: [this.data?.city || '', Validators.required],
      state: [this.data?.state || '', Validators.required],
      pincode: [
        this.data?.pincode || '',
        [Validators.required, Validators.pattern(/^\d{6}$/)]
      ],
      isDefault: [this.data?.isDefault || false],
      latitude: [this.data?.latitude || 0],
      longitude: [this.data?.longitude || 0]
    });
  }

  onCancel(): void {
    this.dialogRef.close();
  }

  onSave(): void {
    if (this.addressForm.valid) {
      const formValue = this.addressForm.value;

      const addressData: DeliveryLocation = {
        ...formValue,
        id: this.data?.id
      };

      this.dialogRef.close(addressData);
    } else {
      // Mark all fields as touched to show validation errors
      Object.keys(this.addressForm.controls).forEach(key => {
        this.addressForm.get(key)?.markAsTouched();
      });
    }
  }

  getErrorMessage(fieldName: string): string {
    const control = this.addressForm.get(fieldName);

    if (control?.hasError('required')) {
      return 'This field is required';
    }

    if (fieldName === 'contactMobileNumber' && control?.hasError('pattern')) {
      return 'Enter a valid 10-digit mobile number';
    }

    if (fieldName === 'pincode' && control?.hasError('pattern')) {
      return 'Enter a valid 6-digit pincode';
    }

    return '';
  }
}
