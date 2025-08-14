import { Component, OnInit, OnDestroy } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { CommonModule } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';

import { AuthService } from '../../../core/services/auth.service';
import { LoginRequest, UserRole } from '../../../core/models/auth.model';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [
    CommonModule, 
    ReactiveFormsModule, 
    MatIconModule, 
    MatButtonModule, 
    MatCheckboxModule, 
    MatProgressSpinnerModule,
    MatInputModule,
    MatFormFieldModule
  ],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent implements OnInit, OnDestroy {
  loginForm!: FormGroup;
  hidePassword = true;
  isLoading = false;
  error: string | null = null;
  returnUrl: string = '/dashboard';
  
  private destroy$ = new Subject<void>();

  constructor(
    private formBuilder: FormBuilder,
    private authService: AuthService,
    private router: Router,
    private route: ActivatedRoute
  ) {
    this.initializeForm();
  }

  ngOnInit(): void {
    this.returnUrl = this.route.snapshot.queryParams['returnUrl'] || '/dashboard';
    
    // Check if already authenticated
    if (this.authService.isAuthenticated()) {
      this.redirectAfterLogin();
    }
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private initializeForm(): void {
    this.loginForm = this.formBuilder.group({
      username: ['admin', [Validators.required]], // Default admin username
      password: ['admin123', [Validators.required, Validators.minLength(6)]]
    });
  }

  onSubmit(): void {
    if (this.loginForm.valid) {
      this.isLoading = true;
      this.error = null;
      
      const credentials: LoginRequest = this.loginForm.value;
      
      this.authService.login(credentials)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (response) => {
            this.isLoading = false;
            this.redirectAfterLogin();
          },
          error: (error) => {
            this.isLoading = false;
            this.error = error.message || 'Login failed. Please try again.';
            console.error('Login error:', error);
          }
        });
    } else {
      this.markFormGroupTouched();
    }
  }

  private redirectAfterLogin(): void {
    const user = this.authService.getCurrentUser();
    
    if (this.returnUrl && this.returnUrl !== '/dashboard') {
      this.router.navigate([this.returnUrl]);
      return;
    }

    // Redirect based on user role
    switch (user?.role) {
      case UserRole.ADMIN:
        this.router.navigate(['/dashboard']);
        break;
      case UserRole.SHOP_OWNER:
        this.router.navigate(['/shops']);
        break;
      default:
        this.router.navigate(['/dashboard']);
    }
  }

  private markFormGroupTouched(): void {
    Object.keys(this.loginForm.controls).forEach(key => {
      const control = this.loginForm.get(key);
      control?.markAsTouched();
    });
  }

  getFieldError(fieldName: string): string | null {
    const field = this.loginForm.get(fieldName);
    
    if (field?.errors && field.touched) {
      if (field.errors['required']) {
        return `${this.getFieldLabel(fieldName)} is required`;
      }
      if (field.errors['minlength']) {
        return `${this.getFieldLabel(fieldName)} must be at least ${field.errors['minlength'].requiredLength} characters`;
      }
    }
    
    return null;
  }

  private getFieldLabel(fieldName: string): string {
    const labels: { [key: string]: string } = {
      username: 'Username',
      password: 'Password'
    };
    return labels[fieldName] || fieldName;
  }

  hasFieldError(fieldName: string): boolean {
    const field = this.loginForm.get(fieldName);
    return !!(field?.errors && field.touched);
  }

  // Demo login method for testing
  loginAsAdmin(): void {
    this.loginForm.patchValue({
      username: 'admin',
      password: 'admin123'
    });
    this.onSubmit();
  }
}