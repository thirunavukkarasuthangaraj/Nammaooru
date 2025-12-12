import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatDialog } from '@angular/material/dialog';
import { AddressService, DeliveryLocation } from '../../services/address.service';
import { AddressDialogComponent } from '../address-dialog/address-dialog.component';
import Swal from 'sweetalert2';

interface Address {
  label: string;
  fullAddress: string;
  phone: string;
}

interface Preferences {
  emailNotifications: boolean;
  smsNotifications: boolean;
  marketing: boolean;
}

@Component({
  selector: 'app-customer-profile',
  templateUrl: './customer-profile.component.html',
  styleUrls: ['./customer-profile.component.scss']
})
export class CustomerProfileComponent implements OnInit {
  profileForm: FormGroup;
  addresses: DeliveryLocation[] = [];
  loading = false;
  preferences: Preferences = {
    emailNotifications: true,
    smsNotifications: true,
    marketing: false
  };

  constructor(
    private fb: FormBuilder,
    private snackBar: MatSnackBar,
    private dialog: MatDialog,
    private addressService: AddressService
  ) {
    this.profileForm = this.createForm();
  }

  ngOnInit(): void {
    this.loadProfile();
    this.loadAddresses();
  }

  createForm(): FormGroup {
    return this.fb.group({
      firstName: ['', [Validators.required]],
      lastName: ['', [Validators.required]],
      email: ['', [Validators.required, Validators.email]],
      phone: ['', [Validators.required]]
    });
  }

  loadProfile(): void {
    // Load user data from localStorage
    const user = JSON.parse(localStorage.getItem('shop_management_user') || localStorage.getItem('currentUser') || '{}');
    
    this.profileForm.patchValue({
      firstName: user.firstName || 'Test',
      lastName: user.lastName || 'Customer',
      email: user.email || 'customer1@test.com',
      phone: user.phone || '9876543210'
    });
  }

  loadAddresses(): void {
    this.loading = true;
    this.addressService.getAddresses().subscribe({
      next: (addresses) => {
        this.addresses = addresses;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading addresses:', error);
        this.loading = false;
        this.snackBar.open('Failed to load addresses', 'Close', { duration: 3000 });
      }
    });
  }

  saveProfile(): void {
    if (this.profileForm.valid) {
      // Save to localStorage for now
      const currentUser = JSON.parse(localStorage.getItem('shop_management_user') || localStorage.getItem('currentUser') || '{}');
      const updatedUser = {
        ...currentUser,
        ...this.profileForm.value
      };
      
      localStorage.setItem('shop_management_user', JSON.stringify(updatedUser));
      
      this.snackBar.open('Profile updated successfully!', 'Close', {
        duration: 3000,
        panelClass: ['success-snackbar']
      });
    }
  }

  addAddress(): void {
    const dialogRef = this.dialog.open(AddressDialogComponent, {
      width: '600px',
      data: null
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        console.log('Dialog closed with result:', result);
        this.addressService.addAddress(result).subscribe({
          next: (newAddress) => {
            console.log('Address saved successfully:', newAddress);
            this.addresses.push(newAddress);
            this.snackBar.open('Address added successfully!', 'Close', { duration: 3000 });
          },
          error: (error) => {
            console.error('Error adding address:', error);
            Swal.fire('Error', 'Failed to add address. Please try again.', 'error');
          }
        });
      }
    });
  }

  editAddress(index: number): void {
    const address = this.addresses[index];
    const dialogRef = this.dialog.open(AddressDialogComponent, {
      width: '600px',
      data: address
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result && address.id) {
        console.log('Updating address with ID:', address.id);
        console.log('Update data:', result);
        this.addressService.updateAddress(address.id, result).subscribe({
          next: (updatedAddress) => {
            console.log('Address updated successfully:', updatedAddress);
            this.addresses[index] = updatedAddress;
            this.snackBar.open('Address updated successfully!', 'Close', { duration: 3000 });
          },
          error: (error) => {
            console.error('Error updating address:', error);
            Swal.fire('Error', 'Failed to update address. Please try again.', 'error');
          }
        });
      }
    });
  }

  deleteAddress(index: number): void {
    const address = this.addresses[index];

    Swal.fire({
      title: 'Delete Address?',
      text: 'Are you sure you want to delete this address?',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, delete it!'
    }).then((result) => {
      if (result.isConfirmed && address.id) {
        this.addressService.deleteAddress(address.id).subscribe({
          next: () => {
            this.addresses.splice(index, 1);
            this.snackBar.open('Address deleted successfully', 'Close', { duration: 2000 });
          },
          error: (error) => {
            console.error('Error deleting address:', error);
            Swal.fire('Error', 'Failed to delete address. Please try again.', 'error');
          }
        });
      }
    });
  }

  savePreferences(): void {
    // Save preferences
    this.snackBar.open('Preferences saved!', 'Close', {
      duration: 3000,
      panelClass: ['success-snackbar']
    });
  }
}