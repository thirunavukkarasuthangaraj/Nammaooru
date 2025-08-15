import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../../../core/services/auth.service';
import { MatSnackBar } from '@angular/material/snack-bar';

@Component({
  selector: 'app-change-password',
  templateUrl: './change-password.component.html',
  styleUrls: ['./change-password.component.scss']
})
export class ChangePasswordComponent implements OnInit {
  changePasswordForm!: FormGroup;
  loading = false;
  hideCurrentPassword = true;
  hideNewPassword = true;
  hideConfirmPassword = true;
  isTemporaryPassword = false;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.initializeForm();
    this.checkPasswordStatus();
  }

  private initializeForm(): void {
    this.changePasswordForm = this.fb.group({
      currentPassword: ['', Validators.required],
      newPassword: ['', [
        Validators.required,
        Validators.minLength(8),
        Validators.pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
      ]],
      confirmPassword: ['', Validators.required]
    }, { validators: this.passwordMatchValidator });
  }

  private checkPasswordStatus(): void {
    this.authService.getPasswordStatus().subscribe({
      next: (status) => {
        this.isTemporaryPassword = status.isTemporaryPassword;
        if (this.isTemporaryPassword) {
          this.changePasswordForm.get('currentPassword')?.clearValidators();
          this.changePasswordForm.get('currentPassword')?.updateValueAndValidity();
        }
      },
      error: (error) => {
        console.error('Error checking password status:', error);
      }
    });
  }

  private passwordMatchValidator(form: FormGroup) {
    const newPassword = form.get('newPassword');
    const confirmPassword = form.get('confirmPassword');
    
    if (newPassword && confirmPassword && newPassword.value !== confirmPassword.value) {
      return { passwordMismatch: true };
    }
    return null;
  }

  onSubmit(): void {
    if (this.changePasswordForm.valid) {
      this.loading = true;
      const formValue = this.changePasswordForm.value;
      
      const request = {
        currentPassword: this.isTemporaryPassword ? '' : formValue.currentPassword,
        newPassword: formValue.newPassword,
        confirmPassword: formValue.confirmPassword
      };

      this.authService.changePassword(request).subscribe({
        next: () => {
          this.snackBar.open('Password changed successfully!', 'Close', {
            duration: 3000,
            panelClass: ['success-snackbar']
          });
          this.router.navigate(['/dashboard']);
        },
        error: (error) => {
          this.loading = false;
          const errorMessage = error.error?.message || 'Failed to change password';
          this.snackBar.open(errorMessage, 'Close', {
            duration: 5000,
            panelClass: ['error-snackbar']
          });
        }
      });
    }
  }

  getErrorMessage(fieldName: string): string {
    const field = this.changePasswordForm.get(fieldName);
    
    if (field?.hasError('required')) {
      return `${fieldName.replace(/([A-Z])/g, ' $1').toLowerCase()} is required`;
    }
    
    if (fieldName === 'newPassword') {
      if (field?.hasError('minlength')) {
        return 'Password must be at least 8 characters long';
      }
      if (field?.hasError('pattern')) {
        return 'Password must contain at least one uppercase letter, lowercase letter, number, and special character';
      }
    }
    
    if (fieldName === 'confirmPassword' && this.changePasswordForm.hasError('passwordMismatch')) {
      return 'Passwords do not match';
    }
    
    return '';
  }

  hasLowercase(): boolean {
    const password = this.changePasswordForm.get('newPassword')?.value || '';
    return /[a-z]/.test(password);
  }

  hasUppercase(): boolean {
    const password = this.changePasswordForm.get('newPassword')?.value || '';
    return /[A-Z]/.test(password);
  }

  hasNumber(): boolean {
    const password = this.changePasswordForm.get('newPassword')?.value || '';
    return /\d/.test(password);
  }

  hasSpecialChar(): boolean {
    const password = this.changePasswordForm.get('newPassword')?.value || '';
    return /[@$!%*?&]/.test(password);
  }

  hasMinLength(): boolean {
    const password = this.changePasswordForm.get('newPassword')?.value || '';
    return password.length >= 8;
  }
}
