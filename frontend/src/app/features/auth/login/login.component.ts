import { Component, OnInit, OnDestroy } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, ActivatedRoute, RouterModule } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { CommonModule } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatCardModule } from '@angular/material/card';

import { AuthService } from '../../../core/services/auth.service';
import { LoginRequest, UserRole } from '../../../core/models/auth.model';
import { VersionService } from '../../../core/services/version.service';
import { PwaInstallBannerComponent } from '../../../shared/components/pwa-install-banner/pwa-install-banner.component';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule,
    MatIconModule,
    MatButtonModule,
    MatCheckboxModule,
    MatProgressSpinnerModule,
    MatInputModule,
    MatFormFieldModule,
    MatCardModule,
    PwaInstallBannerComponent
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
  versionInfo: any = null;
  
  private destroy$ = new Subject<void>();

  constructor(
    private formBuilder: FormBuilder,
    private authService: AuthService,
    private router: Router,
    private route: ActivatedRoute,
    public versionService: VersionService
  ) {
    this.initializeForm();
  }

  ngOnInit(): void {
    this.returnUrl = this.route.snapshot.queryParams['returnUrl'] || '/dashboard';
    
    // Load version info
    this.loadVersionInfo();
    
    // Check if already authenticated
    if (this.authService.isAuthenticated()) {
      this.redirectAfterLogin();
    }
  }

  private loadVersionInfo(): void {
    this.versionService.getVersionInfo().subscribe(info => {
      this.versionInfo = info;
    });
  }

  getClientVersion(): string {
    return this.versionService.getVersion().replace('v', '');
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private initializeForm(): void {
    this.loginForm = this.formBuilder.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]]
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
    
    if (this.returnUrl && this.returnUrl !== '/dashboard' && this.returnUrl !== '/shop-owner/dashboard') {
      this.router.navigate([this.returnUrl]);
      return;
    }

    // Redirect based on user role
    switch (user?.role) {
      case UserRole.SUPER_ADMIN:
        this.router.navigate(['/analytics']);
        break;
      case UserRole.ADMIN:
        this.router.navigate(['/shops']);
        break;
      case UserRole.SHOP_OWNER:
        this.router.navigate(['/shop-owner/dashboard']);
        break;
      default:
        this.router.navigate(['/shops']);
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
      if (field.errors['email']) {
        return `Please enter a valid email address`;
      }
    }
    
    return null;
  }

  private getFieldLabel(fieldName: string): string {
    const labels: { [key: string]: string } = {
      email: 'Email',
      password: 'Password'
    };
    return labels[fieldName] || fieldName;
  }

  hasFieldError(fieldName: string): boolean {
    const field = this.loginForm.get(fieldName);
    return !!(field?.errors && field.touched);
  }
}