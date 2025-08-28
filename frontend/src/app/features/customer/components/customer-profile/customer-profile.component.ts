import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';

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
  addresses: Address[] = [];
  preferences: Preferences = {
    emailNotifications: true,
    smsNotifications: true,
    marketing: false
  };

  constructor(
    private fb: FormBuilder,
    private snackBar: MatSnackBar
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
    // Mock addresses
    this.addresses = [
      {
        label: 'Home',
        fullAddress: '123 Test Street, Chennai, Tamil Nadu - 600001',
        phone: '9876543210'
      }
    ];
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
    // For now, just add a mock address
    const newAddress: Address = {
      label: `Address ${this.addresses.length + 1}`,
      fullAddress: 'New address to be added',
      phone: '9876543210'
    };
    
    this.addresses.push(newAddress);
    
    this.snackBar.open('Address added! (Mock data)', 'Close', {
      duration: 3000
    });
  }

  editAddress(index: number): void {
    this.snackBar.open('Edit functionality coming soon!', 'Close', {
      duration: 2000
    });
  }

  deleteAddress(index: number): void {
    this.addresses.splice(index, 1);
    this.snackBar.open('Address deleted', 'Close', {
      duration: 2000
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