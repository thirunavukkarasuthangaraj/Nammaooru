import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { AuthService } from '@core/services/auth.service';
import { LoginRequest, UserRole } from '@core/models/auth.model';

@Component({
  selector: 'app-login',
  template: `
    <div class="login-container">
      <!-- App Header -->
      <div class="login-header">
        <mat-icon class="login-icon">storefront</mat-icon>
        <h1>NammaOoru</h1>
        <p>Shop Management System</p>
      </div>

      <form [formGroup]="loginForm" (ngSubmit)="onSubmit()" class="login-form">
        <h2>Sign In</h2>
        <p class="login-subtitle">Access your dashboard</p>
        
        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Username</mat-label>
          <mat-icon matPrefix>person</mat-icon>
          <input matInput formControlName="username" placeholder="Enter your username">
          <mat-error *ngIf="loginForm.get('username')?.hasError('required')">
            Username is required
          </mat-error>
        </mat-form-field>

        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Password</mat-label>
          <mat-icon matPrefix>lock</mat-icon>
          <input matInput [type]="hidePassword ? 'password' : 'text'" formControlName="password" placeholder="Enter your password">
          <mat-icon matSuffix (click)="hidePassword = !hidePassword" class="password-toggle">
            {{hidePassword ? 'visibility' : 'visibility_off'}}
          </mat-icon>
          <mat-error *ngIf="loginForm.get('password')?.hasError('required')">
            Password is required
          </mat-error>
        </mat-form-field>

        <button 
          mat-raised-button 
          color="primary" 
          type="submit" 
          class="full-width login-button"
          [disabled]="loginForm.invalid || isLoading">
          <mat-spinner *ngIf="isLoading" diameter="20" style="margin-right: 8px;"></mat-spinner>
          <mat-icon *ngIf="!isLoading" style="margin-right: 8px;">login</mat-icon>
          Sign In
        </button>

        <div class="auth-links">
          <p>Don't have an account? 
            <a routerLink="/auth/register" mat-button color="primary">Sign Up</a>
          </p>
          <p class="forgot-link">
            <a routerLink="/auth/forgot-password" mat-button color="accent">Forgot Password?</a>
          </p>
          <p class="help-text">Need help? 
            <a routerLink="/contact" mat-button color="primary">Contact Support</a>
          </p>
        </div>
      </form>
    </div>
  `,
  styles: [`
    .login-container {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      padding: 30px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      color: white;
    }

    .login-header {
      text-align: center;
      margin-bottom: 30px;
      color: white;
    }

    .login-header .login-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      background: rgba(255, 255, 255, 0.2);
      border-radius: 50%;
      padding: 16px;
      margin-bottom: 16px;
    }

    .login-header h1 {
      font-size: 2.5rem;
      font-weight: 300;
      margin: 0 0 8px 0;
      text-shadow: 0 2px 4px rgba(0,0,0,0.3);
    }

    .login-header p {
      font-size: 1.1rem;
      opacity: 0.9;
      margin: 0;
      font-weight: 300;
    }

    .login-form {
      display: flex;
      flex-direction: column;
      gap: 16px;
      background: white;
      padding: 40px;
      border-radius: 16px;
      box-shadow: 0 20px 40px rgba(0,0,0,0.1);
      color: #333;
      width: 100%;
      max-width: 400px;
    }

    .login-form h2 {
      text-align: center;
      color: #333;
      margin-bottom: 8px;
      font-weight: 500;
      font-size: 1.8rem;
    }

    .login-subtitle {
      text-align: center;
      color: #666;
      margin: 0 0 24px 0;
      font-size: 0.95rem;
    }

    .full-width {
      width: 100%;
    }

    .login-button {
      height: 56px;
      margin-top: 16px;
      font-size: 16px;
      font-weight: 500;
      background: linear-gradient(45deg, #667eea, #764ba2);
    }

    .auth-links {
      text-align: center;
      margin-top: 16px;
    }

    .auth-links p {
      color: #666;
      font-size: 14px;
      margin: 8px 0;
    }

    .auth-links a {
      text-decoration: none;
      font-weight: 500;
    }

    .help-text {
      color: #999 !important;
      font-size: 0.9rem !important;
    }

    .password-toggle {
      cursor: pointer;
      color: #666;
      transition: color 0.3s ease;
    }

    .password-toggle:hover {
      color: #333;
    }

    @media (max-width: 768px) {
      .login-container {
        padding: 16px;
      }

      .login-header h1 {
        font-size: 2rem;
      }

      .login-form {
        padding: 24px;
      }
    }

    @media (max-width: 480px) {
      .login-container {
        padding: 20px;
      }

      .login-header h1 {
        font-size: 1.8rem;
      }

      .login-form {
        padding: 20px;
      }
    }
  `]
})
export class LoginComponent implements OnInit {
  loginForm: FormGroup;
  isLoading = false;
  returnUrl = '/';
  hidePassword = true;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router,
    private route: ActivatedRoute,
    private snackBar: MatSnackBar
  ) {
    this.loginForm = this.fb.group({
      username: ['', [Validators.required]],
      password: ['', [Validators.required]]
    });
  }

  ngOnInit(): void {
    // Get return url from route parameters or default to dashboard
    this.returnUrl = this.route.snapshot.queryParams['returnUrl'] || '/dashboard';
    
    // If already authenticated, redirect
    if (this.authService.isAuthenticated()) {
      this.redirectBasedOnRole();
    }
  }

  onSubmit(): void {
    if (this.loginForm.valid) {
      this.isLoading = true;
      const loginData: LoginRequest = this.loginForm.value;

      this.authService.login(loginData).subscribe({
        next: (response) => {
          this.isLoading = false;
          
          // Check if password change is required
          if (response.passwordChangeRequired || response.isTemporaryPassword) {
            this.router.navigate(['/auth/change-password']);
            return;
          }
          
          this.snackBar.open('Login successful!', 'Close', {
            duration: 3000,
            horizontalPosition: 'end',
            verticalPosition: 'top',
            panelClass: ['success-snackbar']
          });
          this.redirectBasedOnRole();
        },
        error: (error) => {
          this.isLoading = false;
          const errorMessage = error.error?.message || 'Login failed. Please try again.';
          this.snackBar.open(errorMessage, 'Close', {
            duration: 5000,
            horizontalPosition: 'end',
            verticalPosition: 'top',
            panelClass: ['error-snackbar']
          });
        }
      });
    }
  }

  private redirectBasedOnRole(): void {
    const user = this.authService.getCurrentUser();
    if (user) {
      switch (user.role) {
        case UserRole.ADMIN:
          this.router.navigate(['/dashboard']);
          break;
        case UserRole.SHOP_OWNER:
          this.router.navigate(['/shop-owner']);
          break;
        case UserRole.USER:
        default:
          this.router.navigate(['/dashboard']);
          break;
      }
    } else {
      this.router.navigate([this.returnUrl]);
    }
  }
}