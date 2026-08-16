import { Component, OnInit, OnDestroy } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../../../core/services/auth.service';
import { SwalService } from '../../../../core/services/swal.service';

@Component({
  selector: 'app-forgot-password',
  templateUrl: './forgot-password.component.html',
  styleUrls: ['./forgot-password.component.scss']
})
export class ForgotPasswordComponent implements OnInit, OnDestroy {
  // Step 1: Email input, Step 2: OTP input, Step 3: New password
  currentStep: 'email' | 'otp' | 'password' = 'email';
  
  emailForm: FormGroup;
  otpForm: FormGroup;
  passwordForm: FormGroup;
  
  isLoading = false;
  email = '';
  
  // Password visibility toggles
  hideNewPassword = true;
  hideConfirmPassword = true;
  
  // Timer for resend OTP
  resendTimer = 0;
  resendInterval: any;

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private swal: SwalService,
    private authService: AuthService
  ) {
    this.emailForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]]
    });
    
    this.otpForm = this.fb.group({
      otp: ['', [Validators.required, Validators.pattern(/^\d{6}$/)]]
    });
    
    this.passwordForm = this.fb.group({
      newPassword: ['', [Validators.required, Validators.minLength(8)]],
      confirmPassword: ['', [Validators.required]]
    }, { validators: this.passwordMatchValidator });
  }

  ngOnInit(): void {}

  ngOnDestroy(): void {
    if (this.resendInterval) {
      clearInterval(this.resendInterval);
    }
  }

  passwordMatchValidator(form: any) {
    const newPassword = form.get('newPassword');
    const confirmPassword = form.get('confirmPassword');
    return newPassword && confirmPassword && newPassword.value !== confirmPassword.value 
      ? { passwordMismatch: true } : null;
  }

  onEmailSubmit(): void {
    if (this.emailForm.valid) {
      this.isLoading = true;
      this.email = this.emailForm.value.email;

      this.authService.sendPasswordResetOtp(this.email)
        .subscribe({
          next: (response: any) => {
            this.isLoading = false;
            this.currentStep = 'otp';
            this.startResendTimer();
            
            this.swal.toast('OTP sent to your email!', 'success');
          },
          error: (error: any) => {
            this.isLoading = false;
            this.showErrorMessage(error.message || 'Failed to send OTP');
          }
        });
    }
  }

  onOtpSubmit(): void {
    if (this.otpForm.valid) {
      this.isLoading = true;
      const otp = this.otpForm.value.otp;

      this.authService.verifyPasswordResetOtp(this.email, otp)
        .subscribe({
          next: (response: any) => {
            this.isLoading = false;
            this.currentStep = 'password';
            
            this.swal.toast('OTP verified successfully!', 'success');
          },
          error: (error: any) => {
            this.isLoading = false;
            this.showErrorMessage(error.message || 'Invalid OTP');
          }
        });
    }
  }

  onPasswordSubmit(): void {
    if (this.passwordForm.valid) {
      this.isLoading = true;
      const otp = this.otpForm.value.otp;
      const newPassword = this.passwordForm.value.newPassword;

      this.authService.resetPasswordWithOtp(this.email, otp, newPassword)
        .subscribe({
          next: (response: any) => {
            this.isLoading = false;
            
            this.swal.toast('Password updated successfully! Redirecting to login...', 'success');
            
            // Redirect to login after a delay
            setTimeout(() => {
              this.router.navigate(['/auth/login']);
            }, 3000);
          },
          error: (error: any) => {
            this.isLoading = false;
            this.showErrorMessage(error.message || 'Failed to reset password');
          }
        });
    }
  }

  resendOtp(): void {
    if (this.resendTimer > 0) return;
    
    this.isLoading = true;
    
    this.authService.resendPasswordResetOtp(this.email)
      .subscribe({
        next: (response: any) => {
          this.isLoading = false;
          this.startResendTimer();
          
          this.swal.toast('OTP resent successfully!', 'success');
        },
        error: (error: any) => {
          this.isLoading = false;
          this.showErrorMessage(error.message || 'Failed to resend OTP');
        }
      });
  }

  goBack(): void {
    switch (this.currentStep) {
      case 'otp':
        this.currentStep = 'email';
        this.clearResendTimer();
        break;
      case 'password':
        this.currentStep = 'otp';
        break;
    }
  }

  private startResendTimer(): void {
    this.resendTimer = 60; // 60 seconds
    this.resendInterval = setInterval(() => {
      this.resendTimer--;
      if (this.resendTimer <= 0) {
        clearInterval(this.resendInterval);
      }
    }, 1000);
  }

  private clearResendTimer(): void {
    if (this.resendInterval) {
      clearInterval(this.resendInterval);
    }
    this.resendTimer = 0;
  }

  private showErrorMessage(message: string): void {
    this.swal.toast(message, 'error');
  }
}