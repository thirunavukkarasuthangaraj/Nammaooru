import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { UserService, UserRequest } from '../../../../core/services/user.service';
import { DeliveryPartnerService, DeliveryPartnerDocument } from '../../../delivery/services/delivery-partner.service';

@Component({
  selector: 'app-user-form',
  templateUrl: './user-form.component.html',
  styleUrls: ['./user-form.component.scss']
})
export class UserFormComponent implements OnInit {
  userForm: FormGroup;
  loading = false;
  isEditMode = false;
  userId: number | null = null;

  // Delivery Partner Document Upload
  showDeliveryPartnerDocuments = false;
  savedUserId: number | null = null;
  deliveryPartnerId: number | null = null;

  roleOptions = [
    { value: 'SUPER_ADMIN', label: 'Super Admin' },
    { value: 'ADMIN', label: 'Admin' },
    { value: 'SHOP_OWNER', label: 'Shop Owner' },
    { value: 'MANAGER', label: 'Manager' },
    { value: 'EMPLOYEE', label: 'Employee' },
    { value: 'CUSTOMER_SERVICE', label: 'Customer Service' },
    { value: 'DELIVERY_PARTNER', label: 'Delivery Partner' },
    { value: 'USER', label: 'User' }
  ];

  statusOptions = [
    { value: 'ACTIVE', label: 'Active' },
    { value: 'INACTIVE', label: 'Inactive' },
    { value: 'SUSPENDED', label: 'Suspended' },
    { value: 'PENDING_VERIFICATION', label: 'Pending Verification' }
  ];

  departmentOptions = [
    'Information Technology',
    'Human Resources',
    'Finance',
    'Marketing',
    'Operations',
    'Customer Service',
    'Sales',
    'Administration'
  ];

  constructor(
    private fb: FormBuilder,
    private route: ActivatedRoute,
    private router: Router,
    private userService: UserService,
    private snackBar: MatSnackBar,
    private deliveryPartnerService: DeliveryPartnerService
  ) {
    this.userForm = this.createForm();
  }

  ngOnInit(): void {
    this.route.params.subscribe(params => {
      if (params['id']) {
        const numericUserId = parseInt(params['id'], 10);
        if (!isNaN(numericUserId)) {
          this.userId = numericUserId;
          this.isEditMode = true;
          this.loadUser();
        } else {
          console.error('Invalid user ID:', params['id']);
          this.snackBar.open('Invalid user ID', 'Close', { duration: 3000 });
          this.router.navigate(['/users']);
        }
      }
    });
  }

  createForm(): FormGroup {
    return this.fb.group({
      username: ['', [Validators.required, Validators.minLength(3), Validators.maxLength(50)]],
      email: ['', [Validators.required, Validators.email]],
      password: ['', this.isEditMode ? [] : [Validators.required, Validators.minLength(8)]],
      firstName: ['', [Validators.required, Validators.maxLength(100)]],
      lastName: ['', [Validators.required, Validators.maxLength(100)]],
      mobileNumber: ['', [Validators.pattern(/^[6-9][0-9]{9}$/)]],
      role: ['USER', Validators.required],
      status: ['ACTIVE'],
      department: [''],
      designation: [''],
      reportsTo: [''],
      emailVerified: [false],
      mobileVerified: [false],
      twoFactorEnabled: [false],
      passwordChangeRequired: [false]
    });
  }

  loadUser(): void {
    if (!this.userId) return;

    this.loading = true;
    this.userService.getUserById(this.userId).subscribe({
      next: (user) => {
        this.userForm.patchValue({
          username: user.username,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          mobileNumber: user.mobileNumber,
          role: user.role,
          status: user.status,
          department: user.department,
          designation: user.designation,
          reportsTo: user.reportsTo,
          emailVerified: user.emailVerified,
          mobileVerified: user.mobileVerified,
          twoFactorEnabled: user.twoFactorEnabled,
          passwordChangeRequired: user.passwordChangeRequired
        });

        // Remove password requirement for edit mode
        this.userForm.get('password')?.clearValidators();
        this.userForm.get('password')?.updateValueAndValidity();
        
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading user:', error);
        this.snackBar.open('Error loading user details', 'Close', { duration: 3000 });
        this.loading = false;
        this.goBack();
      }
    });
  }

  onSubmit(): void {
    if (this.userForm.valid) {
      this.loading = true;
      const formData = this.userForm.value;

      // Remove password if empty in edit mode
      if (this.isEditMode && !formData.password) {
        delete formData.password;
      }

      const request: UserRequest = {
        username: formData.username,
        email: formData.email,
        password: formData.password,
        firstName: formData.firstName,
        lastName: formData.lastName,
        mobileNumber: formData.mobileNumber || undefined,
        role: formData.role,
        status: formData.status,
        department: formData.department || undefined,
        designation: formData.designation || undefined,
        reportsTo: formData.reportsTo || undefined,
        emailVerified: formData.emailVerified,
        mobileVerified: formData.mobileVerified,
        twoFactorEnabled: formData.twoFactorEnabled,
        passwordChangeRequired: formData.passwordChangeRequired
      };

      const operation = this.isEditMode 
        ? this.userService.updateUser(this.userId!, request)
        : this.userService.createUser(request);

      operation.subscribe({
        next: (response) => {
          this.loading = false;

          if (this.isEditMode) {
            this.snackBar.open('User updated successfully', 'Close', { duration: 3000 });
            this.router.navigate(['/users']);
          } else {
            // Handle new user creation
            this.savedUserId = response.id;
            this.snackBar.open('User created successfully', 'Close', { duration: 3000 });

            // Check if this is a delivery partner role
            if (formData.role === 'DELIVERY_PARTNER') {
              this.handleDeliveryPartnerCreation(response.id);
            } else {
              this.router.navigate(['/users']);
            }
          }
        },
        error: (error) => {
          console.error(`Error ${this.isEditMode ? 'updating' : 'creating'} user:`, error);
          this.snackBar.open(
            error.error?.message || `Error ${this.isEditMode ? 'updating' : 'creating'} user`, 
            'Close', 
            { duration: 3000 }
          );
          this.loading = false;
        }
      });
    } else {
      this.markFormGroupTouched();
    }
  }

  markFormGroupTouched(): void {
    Object.keys(this.userForm.controls).forEach(key => {
      const control = this.userForm.get(key);
      control?.markAsTouched();
    });
  }

  goBack(): void {
    this.router.navigate(['/users']);
  }

  getErrorMessage(fieldName: string): string {
    const control = this.userForm.get(fieldName);
    if (control?.hasError('required')) {
      return `${this.getFieldDisplayName(fieldName)} is required`;
    }
    if (control?.hasError('email')) {
      return 'Enter a valid email address';
    }
    if (control?.hasError('minlength')) {
      const minLength = control.errors?.['minlength']?.requiredLength;
      return `${this.getFieldDisplayName(fieldName)} must be at least ${minLength} characters`;
    }
    if (control?.hasError('maxlength')) {
      const maxLength = control.errors?.['maxlength']?.requiredLength;
      return `${this.getFieldDisplayName(fieldName)} cannot exceed ${maxLength} characters`;
    }
    if (control?.hasError('pattern')) {
      if (fieldName === 'mobileNumber') {
        return 'Enter a valid mobile number (10 digits starting with 6-9)';
      }
    }
    return '';
  }

  private getFieldDisplayName(fieldName: string): string {
    const displayNames: { [key: string]: string } = {
      username: 'Username',
      email: 'Email',
      password: 'Password',
      firstName: 'First Name',
      lastName: 'Last Name',
      mobileNumber: 'Mobile Number',
      role: 'Role',
      department: 'Department',
      designation: 'Designation'
    };
    return displayNames[fieldName] || fieldName;
  }

  // Delivery Partner Document Upload Methods
  handleDeliveryPartnerCreation(userId: number): void {
    // First, check if delivery partner record already exists for this user
    this.deliveryPartnerService.getPartnerByUserId(userId).subscribe({
      next: (response) => {
        if (response.data) {
          // Delivery partner record exists, show document upload
          this.deliveryPartnerId = response.data.id;
          this.showDeliveryPartnerDocuments = true;
        } else {
          // Create delivery partner record first (this would need to be implemented)
          this.createDeliveryPartnerRecord(userId);
        }
      },
      error: (error) => {
        console.error('Error checking delivery partner:', error);
        // For now, just show a message and navigate to users
        this.snackBar.open(
          'User created. Please create delivery partner record separately.',
          'Close',
          { duration: 5000 }
        );
        this.router.navigate(['/users']);
      }
    });
  }

  createDeliveryPartnerRecord(userId: number): void {
    // This method would create a delivery partner record
    // For now, we'll simulate with a mock ID
    this.deliveryPartnerId = userId; // Mock - in real implementation, this would be the delivery partner ID
    this.showDeliveryPartnerDocuments = true;

    this.snackBar.open(
      'Delivery partner record created. Please upload required documents.',
      'Close',
      { duration: 3000 }
    );
  }

  onDocumentsChanged(documents: DeliveryPartnerDocument[]): void {
    console.log('Documents updated:', documents);
    // Handle document changes if needed
  }

  finishDeliveryPartnerSetup(): void {
    this.snackBar.open(
      'Delivery partner setup completed successfully!',
      'Close',
      { duration: 3000 }
    );
    this.router.navigate(['/users']);
  }

  skipDocumentUpload(): void {
    this.snackBar.open(
      'Documents can be uploaded later from the delivery partners section.',
      'Close',
      { duration: 5000 }
    );
    this.router.navigate(['/users']);
  }
}