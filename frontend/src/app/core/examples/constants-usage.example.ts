/**
 * Example showing how to use the centralized constants in components
 * This file demonstrates best practices for consistent constant usage
 */

import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { 
  APP_CONSTANTS,
  API_ENDPOINTS,
  UI_MESSAGES,
  VALIDATION_MESSAGES,
  SHOP_STATUS,
  BUSINESS_TYPES,
  LOCAL_STORAGE_KEYS
} from '../constants/app.constants';
import { ConstantsService } from '../services/constants.service';
import { ShopService } from '../services/shop.service';
import Swal from 'sweetalert2';

// Example Component showing proper constants usage
@Component({
  selector: 'app-example-component',
  template: `
    <!-- Using constants for display values -->
    <div class="shop-status" [style.color]="getStatusColor(shop.status)">
      {{ getStatusDisplay(shop.status) }}
    </div>
    
    <!-- Using constants for form validation -->
    <form [formGroup]="shopForm" (ngSubmit)="onSubmit()">
      <input 
        formControlName="name" 
        [placeholder]="MESSAGES.INFO.LOADING"
        required>
      <div *ngIf="shopForm.get('name')?.invalid && shopForm.get('name')?.touched">
        {{ VALIDATION_MESSAGES.REQUIRED }}
      </div>
    </form>
    
    <!-- Using constants for conditional rendering -->
    <button 
      *ngIf="shop.status === SHOP_STATUS.PENDING"
      (click)="approveShop()">
      Approve
    </button>
  `
})
export class ExampleComponent implements OnInit {
  
  // ✅ CORRECT: Access constants through the service
  readonly SHOP_STATUS = this.constants.SHOP_STATUS;
  readonly BUSINESS_TYPES = this.constants.BUSINESS_TYPES;
  readonly MESSAGES = this.constants.MESSAGES;
  readonly VALIDATION_MESSAGES = VALIDATION_MESSAGES;
  
  // ✅ CORRECT: Use constants for component properties
  shopForm: FormGroup;
  shop: any = { status: SHOP_STATUS.PENDING };
  
  constructor(
    private fb: FormBuilder,
    private router: Router,
    private constants: ConstantsService,
    private shopService: ShopService
  ) {
    this.initializeForm();
  }
  
  ngOnInit(): void {
    this.loadShopData();
  }
  
  private initializeForm(): void {
    // ✅ CORRECT: Use validation constants
    this.shopForm = this.fb.group({
      name: ['', [Validators.required, Validators.minLength(2)]],
      email: ['', [Validators.required, Validators.email]],
      businessType: [BUSINESS_TYPES.GROCERY, Validators.required]
    });
  }
  
  private loadShopData(): void {
    // ✅ CORRECT: Use API endpoint constants
    this.shopService.getShops().subscribe({
      next: (response) => {
        // ✅ CORRECT: Use constants service for checking status
        if (this.constants.isApiSuccess('0000')) {
          this.showSuccess(this.constants.MESSAGES.SUCCESS.DATA_SAVED);
        }
      },
      error: (error) => {
        // ✅ CORRECT: Use constants for error handling
        this.showError(this.constants.getErrorMessage(error.statusCode));
      }
    });
  }
  
  onSubmit(): void {
    if (this.shopForm.valid) {
      const formData = this.shopForm.value;
      
      // ✅ CORRECT: Use constants for API calls
      this.shopService.createShop(formData).subscribe({
        next: () => {
          // ✅ CORRECT: Use constant for success message
          this.showSuccess(this.constants.getSuccessMessage('create_shop'));
          
          // ✅ CORRECT: Use route constants
          this.router.navigate([this.constants.ROUTES.SHOPS.LIST]);
        },
        error: (error) => {
          this.handleApiError(error);
        }
      });
    } else {
      // ✅ CORRECT: Use validation message constants
      this.showError(this.constants.MESSAGES.ERROR.FORM_INVALID);
    }
  }
  
  approveShop(): void {
    // ✅ CORRECT: Use confirmation message constants
    Swal.fire({
      title: 'Confirm Approval',
      text: this.constants.MESSAGES.CONFIRMATION.APPROVE_SHOP,
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Yes, approve',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.processApproval();
      }
    });
  }
  
  private processApproval(): void {
    this.shopService.approveShop(this.shop.id).subscribe({
      next: () => {
        // ✅ CORRECT: Update status using constants
        this.shop.status = this.constants.SHOP_STATUS.APPROVED;
        this.showSuccess(this.constants.MESSAGES.SUCCESS.SHOP_APPROVED);
      },
      error: (error) => {
        this.handleApiError(error);
      }
    });
  }
  
  // ✅ CORRECT: Use constants service methods
  getStatusDisplay(status: string): string {
    return this.constants.getShopStatusDisplay(status);
  }
  
  getStatusColor(status: string): string {
    return this.constants.getShopStatusColor(status);
  }
  
  // ✅ CORRECT: Centralized error handling using constants
  private handleApiError(error: any): void {
    const statusCode = error.statusCode;
    
    if (this.constants.isAuthError(statusCode)) {
      // Handle authentication errors
      this.router.navigate([this.constants.ROUTES.LOGIN]);
      return;
    }
    
    if (this.constants.isValidationError(statusCode)) {
      // Handle validation errors
      this.showError(this.constants.MESSAGES.ERROR.FORM_INVALID);
      return;
    }
    
    // General error handling
    this.showError(this.constants.getErrorMessage(statusCode));
  }
  
  private showSuccess(message: string): void {
    Swal.fire({
      icon: 'success',
      title: 'Success',
      text: message,
      confirmButtonColor: '#28a745'
    });
  }
  
  private showError(message: string): void {
    Swal.fire({
      icon: 'error',
      title: 'Error',
      text: message,
      confirmButtonColor: '#dc3545'
    });
  }
  
  // ✅ CORRECT: Use storage constants
  saveUserPreference(key: string, value: any): void {
    this.constants.setStorageItem('USER' as keyof typeof LOCAL_STORAGE_KEYS, { [key]: value });
  }
  
  getUserPreference(key: string): any {
    const userData = this.constants.getStorageItem('USER' as keyof typeof LOCAL_STORAGE_KEYS);
    return userData?.[key];
  }
}

/**
 * ❌ AVOID: Don't use hardcoded values
 */
class BadExampleComponent {
  
  // ❌ BAD: Hardcoded values
  shop = { status: 'PENDING' };
  
  checkStatus() {
    // ❌ BAD: Magic strings
    if (this.shop.status === 'PENDING') {
      console.log('Shop is pending');
    }
  }
  
  showMessage() {
    // ❌ BAD: Hardcoded messages
    alert('Shop created successfully');
  }
  
  makeApiCall() {
    // ❌ BAD: Hardcoded URLs
    return fetch('http://localhost:8082/api/shops');
  }
}

/**
 * ✅ CORRECT: Usage patterns
 */
export class GoodExampleComponent {
  
  // ✅ GOOD: Use constants
  readonly STATUS = SHOP_STATUS;
  readonly MESSAGES = UI_MESSAGES;
  
  constructor(private constants: ConstantsService) {}
  
  checkStatus() {
    // ✅ GOOD: Use constants
    if (this.shop.status === this.STATUS.PENDING) {
      console.log(this.MESSAGES.INFO.PROCESSING);
    }
  }
  
  showMessage() {
    // ✅ GOOD: Use constant messages
    Swal.fire({
      icon: 'success',
      text: this.constants.getSuccessMessage('create_shop')
    });
  }
  
  makeApiCall() {
    // ✅ GOOD: Use endpoint constants
    const url = API_ENDPOINTS.BASE_URL + API_ENDPOINTS.SHOPS.BASE;
    return fetch(url);
  }
  
  shop: any = { status: this.STATUS.PENDING };
}