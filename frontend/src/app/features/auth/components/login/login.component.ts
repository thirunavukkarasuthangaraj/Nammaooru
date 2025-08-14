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
      <form [formGroup]="loginForm" (ngSubmit)="onSubmit()" class="login-form">
        <h2>Sign In</h2>
        
        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Username</mat-label>
          <input matInput formControlName="username" placeholder="Enter your username">
          <mat-error *ngIf="loginForm.get('username')?.hasError('required')">
            Username is required
          </mat-error>
        </mat-form-field>

        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Password</mat-label>
          <input matInput type="password" formControlName="password" placeholder="Enter your password">
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
          Sign In
        </button>

        <div class="auth-links">
          <p>Don't have an account? 
            <a routerLink="/auth/register" mat-button color="primary">Sign Up</a>
          </p>
        </div>
      </form>
    </div>
  `,
  styles: [`
    .login-container {
      padding: 30px;
    }

    .login-form {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .login-form h2 {
      text-align: center;
      color: #333;
      margin-bottom: 24px;
      font-weight: 500;
    }

    .login-button {
      height: 48px;
      margin-top: 16px;
      font-size: 16px;
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

    @media (max-width: 480px) {
      .login-container {
        padding: 20px;
      }
    }
  `]
})
export class LoginComponent implements OnInit {
  loginForm: FormGroup;
  isLoading = false;
  returnUrl = '/';

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
    // Get return url from route parameters or default to '/'
    this.returnUrl = this.route.snapshot.queryParams['returnUrl'] || '/';
    
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
          this.router.navigate(['/admin']);
          break;
        case UserRole.SHOP_OWNER:
          this.router.navigate(['/shop-owner']);
          break;
        default:
          this.router.navigate(['/shops']);
          break;
      }
    } else {
      this.router.navigate([this.returnUrl]);
    }
  }
}