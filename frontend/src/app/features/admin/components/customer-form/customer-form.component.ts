import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { CustomerService, Customer } from '../../../../core/services/customer.service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-customer-form',
  templateUrl: './customer-form.component.html',
  styleUrls: ['./customer-form.component.scss']
})
export class CustomerFormComponent implements OnInit {
  customerForm: FormGroup;
  isEditMode = false;
  customerId: number | null = null;
  isLoading = false;
  isSubmitting = false;
  
  genderOptions = [
    { value: 'MALE', label: 'Male' },
    { value: 'FEMALE', label: 'Female' },
    { value: 'OTHER', label: 'Other' },
    { value: 'PREFER_NOT_TO_SAY', label: 'Prefer not to say' }
  ];
  
  statusOptions = [
    { value: 'ACTIVE', label: 'Active' },
    { value: 'INACTIVE', label: 'Inactive' },
    { value: 'BLOCKED', label: 'Blocked' },
    { value: 'PENDING_VERIFICATION', label: 'Pending Verification' }
  ];

  constructor(
    private fb: FormBuilder,
    private customerService: CustomerService,
    private router: Router,
    private route: ActivatedRoute
  ) {
    this.customerForm = this.createForm();
  }

  ngOnInit(): void {
    this.route.params.subscribe(params => {
      if (params['id']) {
        this.isEditMode = true;
        this.customerId = +params['id'];
        this.loadCustomer();
      }
    });
  }

  createForm(): FormGroup {
    return this.fb.group({
      // Basic Information
      firstName: ['', [Validators.required, Validators.minLength(2)]],
      lastName: ['', [Validators.required, Validators.minLength(2)]],
      email: ['', [Validators.required, Validators.email]],
      mobileNumber: ['', [Validators.required, Validators.pattern(/^[6-9][0-9]{9}$/)]],
      alternateMobileNumber: ['', [Validators.pattern(/^[6-9][0-9]{9}$/)]],
      gender: [''],
      dateOfBirth: [''],
      
      // Address Information
      addressLine1: [''],
      addressLine2: [''],
      city: [''],
      state: [''],
      postalCode: ['', [Validators.pattern(/^[0-9]{6}$/)]],
      country: ['India'],
      
      // Preferences
      emailNotifications: [true],
      smsNotifications: [true],
      promotionalEmails: [false],
      preferredLanguage: ['English'],
      
      // Status
      status: ['ACTIVE'],
      isActive: [true],
      
      // Referral
      referredBy: [''],
      
      // Notes
      notes: ['']
    });
  }

  loadCustomer(): void {
    if (!this.customerId) return;
    
    this.isLoading = true;
    this.customerService.getCustomerById(this.customerId).subscribe({
      next: (customer) => {
        this.populateForm(customer);
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading customer:', error);
        this.isLoading = false;
        // Show error message
      }
    });
  }

  populateForm(customer: Customer): void {
    this.customerForm.patchValue({
      firstName: customer.firstName,
      lastName: customer.lastName,
      email: customer.email,
      mobileNumber: customer.mobileNumber,
      alternateMobileNumber: customer.alternateMobileNumber,
      gender: customer.gender,
      dateOfBirth: customer.dateOfBirth,
      addressLine1: customer.addressLine1,
      addressLine2: customer.addressLine2,
      city: customer.city,
      state: customer.state,
      postalCode: customer.postalCode,
      country: customer.country,
      emailNotifications: customer.emailNotifications,
      smsNotifications: customer.smsNotifications,
      promotionalEmails: customer.promotionalEmails,
      preferredLanguage: customer.preferredLanguage,
      status: customer.status,
      isActive: customer.isActive,
      referredBy: customer.referredBy,
      notes: customer.notes
    });
  }

  onSubmit(): void {
    if (this.customerForm.valid) {
      this.isSubmitting = true;
      const formValue = this.customerForm.value;
      
      if (this.isEditMode && this.customerId) {
        this.customerService.updateCustomer(this.customerId, formValue).subscribe({
          next: (result) => {
            Swal.fire('Success!', 'Customer updated successfully.', 'success').then(() => {
              this.router.navigate(['/admin/customers']);
            });
          },
          error: (error) => {
            console.error('Error updating customer:', error);
            this.isSubmitting = false;
            Swal.fire('Error!', 'Failed to update customer. Please try again.', 'error');
          }
        });
      } else {
        this.customerService.createCustomer(formValue).subscribe({
          next: (result) => {
            Swal.fire('Success!', 'Customer created successfully.', 'success').then(() => {
              this.router.navigate(['/admin/customers']);
            });
          },
          error: (error) => {
            console.error('Error creating customer:', error);
            this.isSubmitting = false;
            Swal.fire('Error!', 'Failed to create customer. Please try again.', 'error');
          }
        });
      }
    } else {
      this.markFormGroupTouched();
    }
  }

  onCancel(): void {
    this.router.navigate(['/admin/customers']);
  }

  private markFormGroupTouched(): void {
    Object.keys(this.customerForm.controls).forEach(key => {
      const control = this.customerForm.get(key);
      control?.markAsTouched();
    });
  }

  getErrorMessage(fieldName: string): string {
    const control = this.customerForm.get(fieldName);
    if (control?.hasError('required')) {
      return `${this.getFieldLabel(fieldName)} is required`;
    }
    if (control?.hasError('email')) {
      return 'Please enter a valid email address';
    }
    if (control?.hasError('pattern')) {
      if (fieldName === 'mobileNumber' || fieldName === 'alternateMobileNumber') {
        return 'Please enter a valid 10-digit mobile number';
      }
      if (fieldName === 'postalCode') {
        return 'Please enter a valid 6-digit postal code';
      }
    }
    if (control?.hasError('minlength')) {
      return `${this.getFieldLabel(fieldName)} must be at least ${control.errors?.['minlength'].requiredLength} characters`;
    }
    return '';
  }

  private getFieldLabel(fieldName: string): string {
    const labels: { [key: string]: string } = {
      firstName: 'First Name',
      lastName: 'Last Name',
      email: 'Email',
      mobileNumber: 'Mobile Number',
      alternateMobileNumber: 'Alternate Mobile Number',
      postalCode: 'Postal Code'
    };
    return labels[fieldName] || fieldName;
  }

  isFieldInvalid(fieldName: string): boolean {
    const control = this.customerForm.get(fieldName);
    return !!(control?.invalid && (control?.dirty || control?.touched));
  }
}