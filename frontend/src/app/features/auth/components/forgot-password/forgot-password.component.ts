import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpClient } from '@angular/common/http';

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

      <!-- Form -->
      <form [formGroup]="forgotPasswordForm" (ngSubmit)="onSubmit()" class="forgot-form">
        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Username or Email</mat-label>
          <mat-icon matPrefix>person</mat-icon>
          <input matInput 
                 formControlName="usernameOrEmail" 
                 placeholder="Enter your username or email address">
          <mat-error *ngIf="forgotPasswordForm.get('usernameOrEmail')?.hasError('required')">
            Username or email is required
          </mat-error>
        </mat-form-field>

        <button 
          mat-raised-button 
          color="primary" 
          type="submit" 
          class="full-width reset-button"
          [disabled]="forgotPasswordForm.invalid || isLoading">
          <mat-spinner *ngIf="isLoading" diameter="20" style="margin-right: 8px;"></mat-spinner>
          <mat-icon *ngIf="!isLoading" style="margin-right: 8px;">send</mat-icon>
          Send Reset Link
        </button>

        <!-- Success Message -->
        <div class="success-message" *ngIf="emailSent">
          <mat-icon>check_circle</mat-icon>
          <h3>Reset Link Sent!</h3>
          <p>If an account exists with that username or email, we've sent a password reset link. Please check your email and follow the instructions.</p>
          <p><small>Don't see the email? Check your spam folder.</small></p>
        </div>

        <!-- Back to Login -->
        <div class="auth-links">
          <p>Remember your password? 
            <a routerLink="/auth/login" mat-button color="primary">Back to Login</a>
          </p>
        </div>
      </form>

      <!-- Help Section -->
      <div class="help-section" *ngIf="!emailSent">
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
export class ForgotPasswordComponent implements OnInit {
  forgotPasswordForm: FormGroup;
  isLoading = false;
  emailSent = false;

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private snackBar: MatSnackBar,
    private http: HttpClient
  ) {
    this.forgotPasswordForm = this.fb.group({
      usernameOrEmail: ['', [Validators.required]]
    });
  }

  ngOnInit(): void {}

  onSubmit(): void {
    if (this.forgotPasswordForm.valid) {
      this.isLoading = true;
      const formData = this.forgotPasswordForm.value;

      this.http.post('http://localhost:8082/api/auth/password/forgot', formData)
        .subscribe({
          next: (response: any) => {
            this.isLoading = false;
            this.emailSent = true;
            
            this.snackBar.open('Password reset instructions sent!', 'Close', {
              duration: 5000,
              horizontalPosition: 'end',
              verticalPosition: 'top',
              panelClass: ['success-snackbar']
            });
          },
          error: (error) => {
            this.isLoading = false;
            this.emailSent = true; // Show success even on error for security
            
            // Log error but show success message to prevent user enumeration
            console.error('Forgot password error:', error);
          }
        });
    }
  }
}