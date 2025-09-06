import { Component, OnInit, OnDestroy } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { AuthService } from '../../../../core/services/auth.service';

@Component({
  selector: 'app-forgot-password',
  template: `
    <div class="forgot-password-container">
      <!-- Header -->
      <div class="forgot-header">
        <mat-icon class="forgot-icon">lock_reset</mat-icon>
        <h1>Forgot Password?</h1>
        <p>No worries! Enter your username or email and we'll send you a reset link.</p>
      </div>

      <!-- Step 1: Email Form -->
      <form [formGroup]="emailForm" (ngSubmit)="onEmailSubmit()" class="forgot-form" *ngIf="currentStep === 'email'">
        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Email Address</mat-label>
          <mat-icon matPrefix>email</mat-icon>
          <input matInput 
                 formControlName="email" 
                 type="email"
                 placeholder="Enter your email address">
          <mat-error *ngIf="emailForm.get('email')?.hasError('required')">
            Email is required
          </mat-error>
          <mat-error *ngIf="emailForm.get('email')?.hasError('email')">
            Please enter a valid email address
          </mat-error>
        </mat-form-field>

        <button 
          mat-raised-button 
          color="primary" 
          type="submit" 
          class="full-width reset-button"
          [disabled]="emailForm.invalid || isLoading">
          <mat-spinner *ngIf="isLoading" diameter="20" style="margin-right: 8px;"></mat-spinner>
          <mat-icon *ngIf="!isLoading" style="margin-right: 8px;">send</mat-icon>
          Send OTP
        </button>

        <!-- Back to Login -->
        <div class="auth-links">
          <p>Remember your password? 
            <a routerLink="/auth/login" mat-button color="primary">Back to Login</a>
          </p>
        </div>
      </form>

      <!-- Step 2: OTP Form -->
      <form [formGroup]="otpForm" (ngSubmit)="onOtpSubmit()" class="forgot-form" *ngIf="currentStep === 'otp'">
        <div class="step-info">
          <p>We've sent a 6-digit OTP to <strong>{{email}}</strong></p>
        </div>

        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Enter OTP</mat-label>
          <mat-icon matPrefix>security</mat-icon>
          <input matInput 
                 formControlName="otp" 
                 placeholder="Enter 6-digit OTP"
                 maxlength="6"
                 type="text"
                 style="text-align: center; font-size: 18px; letter-spacing: 2px;">
          <mat-error *ngIf="otpForm.get('otp')?.hasError('required')">
            OTP is required
          </mat-error>
          <mat-error *ngIf="otpForm.get('otp')?.hasError('pattern')">
            Please enter a valid 6-digit OTP
          </mat-error>
        </mat-form-field>

        <button 
          mat-raised-button 
          color="primary" 
          type="submit" 
          class="full-width reset-button"
          [disabled]="otpForm.invalid || isLoading">
          <mat-spinner *ngIf="isLoading" diameter="20" style="margin-right: 8px;"></mat-spinner>
          <mat-icon *ngIf="!isLoading" style="margin-right: 8px;">verified_user</mat-icon>
          Verify OTP
        </button>

        <!-- Resend OTP -->
        <div class="resend-section">
          <button 
            mat-button 
            type="button"
            [disabled]="resendTimer > 0 || isLoading"
            (click)="resendOtp()">
            <mat-icon style="margin-right: 4px;">refresh</mat-icon>
            <span *ngIf="resendTimer > 0">Resend in {{resendTimer}}s</span>
            <span *ngIf="resendTimer <= 0">Resend OTP</span>
          </button>
        </div>

        <!-- Back Button -->
        <div class="auth-links">
          <button mat-button type="button" (click)="goBack()">
            <mat-icon style="margin-right: 4px;">arrow_back</mat-icon>
            Change Email
          </button>
        </div>
      </form>

      <!-- Step 3: New Password Form -->
      <form [formGroup]="passwordForm" (ngSubmit)="onPasswordSubmit()" class="forgot-form" *ngIf="currentStep === 'password'">
        <div class="step-info">
          <p>Create your new password</p>
        </div>

        <mat-form-field appearance="outline" class="full-width">
          <mat-label>New Password</mat-label>
          <mat-icon matPrefix>lock</mat-icon>
          <input matInput 
                 formControlName="newPassword" 
                 type="password"
                 placeholder="Enter new password">
          <mat-error *ngIf="passwordForm.get('newPassword')?.hasError('required')">
            New password is required
          </mat-error>
          <mat-error *ngIf="passwordForm.get('newPassword')?.hasError('minlength')">
            Password must be at least 8 characters long
          </mat-error>
        </mat-form-field>

        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Confirm Password</mat-label>
          <mat-icon matPrefix>lock_outline</mat-icon>
          <input matInput 
                 formControlName="confirmPassword" 
                 type="password"
                 placeholder="Confirm new password">
          <mat-error *ngIf="passwordForm.get('confirmPassword')?.hasError('required')">
            Please confirm your password
          </mat-error>
          <mat-error *ngIf="passwordForm.hasError('passwordMismatch') && !passwordForm.get('confirmPassword')?.hasError('required')">
            Passwords do not match
          </mat-error>
        </mat-form-field>

        <button 
          mat-raised-button 
          color="primary" 
          type="submit" 
          class="full-width reset-button"
          [disabled]="passwordForm.invalid || isLoading">
          <mat-spinner *ngIf="isLoading" diameter="20" style="margin-right: 8px;"></mat-spinner>
          <mat-icon *ngIf="!isLoading" style="margin-right: 8px;">save</mat-icon>
          Reset Password
        </button>

        <!-- Back Button -->
        <div class="auth-links">
          <button mat-button type="button" (click)="goBack()">
            <mat-icon style="margin-right: 4px;">arrow_back</mat-icon>
            Back to OTP
          </button>
        </div>
      </form>

      <!-- Help Section -->
      <div class="help-section" *ngIf="currentStep === 'email'">
        <h3>Need Help?</h3>
        <div class="help-content">
          <div class="help-item">
            <mat-icon>email</mat-icon>
            <div>
              <strong>Email not working?</strong>
              <p>Make sure you enter the email associated with your account</p>
            </div>
          </div>
          <div class="help-item">
            <mat-icon>schedule</mat-icon>
            <div>
              <strong>Reset link expires</strong>
              <p>Password reset links expire in 30 minutes for security</p>
            </div>
          </div>
          <div class="help-item">
            <mat-icon>support</mat-icon>
            <div>
              <strong>Still need help?</strong>
              <p>Contact our support team for assistance</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .forgot-password-container {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      padding: 30px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      color: white;
    }

    .forgot-header {
      text-align: center;
      margin-bottom: 30px;
      color: white;
    }

    .forgot-header .forgot-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      background: rgba(255, 255, 255, 0.2);
      border-radius: 50%;
      padding: 16px;
      margin-bottom: 16px;
    }

    .forgot-header h1 {
      font-size: 2.5rem;
      font-weight: 300;
      margin: 0 0 12px 0;
      text-shadow: 0 2px 4px rgba(0,0,0,0.3);
    }

    .forgot-header p {
      font-size: 1.1rem;
      opacity: 0.9;
      margin: 0;
      font-weight: 300;
      max-width: 400px;
    }

    .forgot-form {
      background: white;
      padding: 40px;
      border-radius: 16px;
      box-shadow: 0 20px 40px rgba(0,0,0,0.1);
      color: #333;
      width: 100%;
      max-width: 450px;
      display: flex;
      flex-direction: column;
      gap: 20px;
    }

    .full-width {
      width: 100%;
    }

    .reset-button {
      height: 56px;
      font-size: 16px;
      font-weight: 500;
      background: linear-gradient(45deg, #667eea, #764ba2);
      margin-top: 8px;
    }

    .success-message {
      text-align: center;
      padding: 24px;
      background: #e8f5e8;
      border-radius: 12px;
      border: 2px solid #4caf50;
      margin: 16px 0;
    }

    .success-message mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      color: #4caf50;
      margin-bottom: 16px;
    }

    .success-message h3 {
      margin: 0 0 12px 0;
      color: #4caf50;
      font-weight: 600;
    }

    .success-message p {
      margin: 8px 0;
      color: #333;
      line-height: 1.5;
    }

    .success-message small {
      color: #666;
      font-style: italic;
    }

    .auth-links {
      text-align: center;
      margin-top: 16px;
    }

    .auth-links p {
      color: #666;
      font-size: 14px;
      margin: 0;
    }

    .auth-links a {
      text-decoration: none;
      font-weight: 500;
    }

    .step-info {
      text-align: center;
      margin-bottom: 20px;
      padding: 12px;
      background: #f5f5f5;
      border-radius: 8px;
    }

    .step-info p {
      margin: 0;
      color: #666;
      font-size: 14px;
    }

    .resend-section {
      text-align: center;
      margin: 16px 0;
    }

    .resend-section button {
      color: #667eea;
    }

    .resend-section button:disabled {
      color: #ccc;
    }

    .help-section {
      background: rgba(255, 255, 255, 0.1);
      border-radius: 12px;
      padding: 24px;
      margin-top: 20px;
      width: 100%;
      max-width: 450px;
      backdrop-filter: blur(10px);
    }

    .help-section h3 {
      margin: 0 0 20px 0;
      font-weight: 400;
      text-align: center;
    }

    .help-content {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .help-item {
      display: flex;
      align-items: flex-start;
      gap: 12px;
    }

    .help-item mat-icon {
      font-size: 24px;
      width: 24px;
      height: 24px;
      margin-top: 2px;
      opacity: 0.9;
    }

    .help-item strong {
      display: block;
      margin-bottom: 4px;
      font-size: 0.95rem;
    }

    .help-item p {
      margin: 0;
      font-size: 0.85rem;
      opacity: 0.8;
      line-height: 1.4;
    }

    /* Mobile Responsive */
    @media (max-width: 768px) {
      .forgot-password-container {
        padding: 16px;
      }

      .forgot-header h1 {
        font-size: 2rem;
      }

      .forgot-form {
        padding: 24px;
      }

      .help-section {
        margin-top: 16px;
      }
    }

    @media (max-width: 480px) {
      .forgot-header h1 {
        font-size: 1.8rem;
      }

      .forgot-form {
        padding: 20px;
      }

      .help-item {
        flex-direction: column;
        gap: 8px;
      }

      .help-item mat-icon {
        align-self: center;
      }
    }
  `]
})
export class ForgotPasswordComponent implements OnInit, OnDestroy {
  // Step 1: Email input, Step 2: OTP input, Step 3: New password
  currentStep: 'email' | 'otp' | 'password' = 'email';
  
  emailForm: FormGroup;
  otpForm: FormGroup;
  passwordForm: FormGroup;
  
  isLoading = false;
  email = '';
  
  // Timer for resend OTP
  resendTimer = 0;
  resendInterval: any;

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private snackBar: MatSnackBar,
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
            
            this.snackBar.open('OTP sent to your email!', 'Close', {
              duration: 5000,
              panelClass: ['success-snackbar']
            });
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
            
            this.snackBar.open('OTP verified successfully!', 'Close', {
              duration: 3000,
              panelClass: ['success-snackbar']
            });
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
            
            this.snackBar.open('Password updated successfully! Redirecting to login...', 'Close', {
              duration: 3000,
              panelClass: ['success-snackbar']
            });
            
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
          
          this.snackBar.open('OTP resent successfully!', 'Close', {
            duration: 3000,
            panelClass: ['success-snackbar']
          });
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
    this.snackBar.open(message, 'Close', {
      duration: 5000,
      panelClass: ['error-snackbar']
    });
  }
}