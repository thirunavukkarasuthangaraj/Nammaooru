import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { AuthService } from '@core/services/auth.service';
import { RegisterRequest, UserRole } from '@core/models/auth.model';

@Component({
  selector: 'app-register',
  template: `
    <div class="register-container">
      <form [formGroup]="registerForm" (ngSubmit)="onSubmit()" class="register-form">
        <h2>Sign Up</h2>
        
        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Username</mat-label>
          <input matInput formControlName="username" placeholder="Enter username">
          <mat-error *ngIf="registerForm.get('username')?.hasError('required')">
            Username is required
          </mat-error>
          <mat-error *ngIf="registerForm.get('username')?.hasError('minlength')">
            Username must be at least 3 characters
          </mat-error>
        </mat-form-field>

        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Email</mat-label>
          <input matInput type="email" formControlName="email" placeholder="Enter email address">
          <mat-error *ngIf="registerForm.get('email')?.hasError('required')">
            Email is required
          </mat-error>
          <mat-error *ngIf="registerForm.get('email')?.hasError('email')">
            Please enter a valid email address
          </mat-error>
        </mat-form-field>

        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Password</mat-label>
          <input matInput type="password" formControlName="password" placeholder="Enter password">
          <mat-error *ngIf="registerForm.get('password')?.hasError('required')">
            Password is required
          </mat-error>
          <mat-error *ngIf="registerForm.get('password')?.hasError('minlength')">
            Password must be at least 6 characters
          </mat-error>
        </mat-form-field>

        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Role</mat-label>
          <mat-select formControlName="role">
            <mat-option value="USER">User</mat-option>
            <mat-option value="SHOP_OWNER">Shop Owner</mat-option>
          </mat-select>
          <mat-error *ngIf="registerForm.get('role')?.hasError('required')">
            Please select a role
          </mat-error>
        </mat-form-field>

        <button 
          mat-raised-button 
          color="primary" 
          type="submit" 
          class="full-width register-button"
          [disabled]="registerForm.invalid || isLoading">
          <mat-spinner *ngIf="isLoading" diameter="20" style="margin-right: 8px;"></mat-spinner>
          Sign Up
        </button>

        <div class="auth-links">
          <p>Already have an account? 
            <a routerLink="/auth/login" mat-button color="primary">Sign In</a>
          </p>
        </div>
      </form>
    </div>
  `,
  styles: [`
    .register-container {
      padding: 30px;
    }

    .register-form {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .register-form h2 {
      text-align: center;
      color: #333;
      margin-bottom: 24px;
      font-weight: 500;
    }

    .register-button {
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
      .register-container {
        padding: 20px;
      }
    }
  `]
})
export class RegisterComponent implements OnInit {
  registerForm: FormGroup;
  isLoading = false;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router,
    private snackBar: MatSnackBar
  ) {
    this.registerForm = this.fb.group({
      username: ['', [Validators.required, Validators.minLength(3)]],
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]],
      role: ['USER', [Validators.required]]
    });
  }

  ngOnInit(): void {
    // If already authenticated, redirect
    if (this.authService.isAuthenticated()) {
      this.redirectBasedOnRole();
    }
  }

  onSubmit(): void {
    if (this.registerForm.valid) {
      this.isLoading = true;
      const registerData: RegisterRequest = this.registerForm.value;

      this.authService.register(registerData).subscribe({
        next: (response) => {
          this.isLoading = false;
          this.snackBar.open('Registration successful!', 'Close', {
            duration: 3000,
            horizontalPosition: 'end',
            verticalPosition: 'top',
            panelClass: ['success-snackbar']
          });
          this.redirectBasedOnRole();
        },
        error: (error) => {
          this.isLoading = false;
          const errorMessage = error.error?.message || 'Registration failed. Please try again.';
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
    }
  }
}