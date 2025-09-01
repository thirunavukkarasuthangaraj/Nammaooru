import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { AuthService } from '@core/services/auth.service';
import { RegisterRequest, UserRole } from '@core/models/auth.model';
import { VersionService } from '@core/services/version.service';

@Component({
  selector: 'app-register',
  templateUrl: './register.component.html',
  styleUrls: ['./register.component.scss']
})
export class RegisterComponent implements OnInit {
  registerForm: FormGroup;
  isLoading = false;
  hidePassword = true;
  versionInfo: any = null;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router,
    private snackBar: MatSnackBar,
    public versionService: VersionService
  ) {
    this.registerForm = this.fb.group({
      username: ['', [Validators.required, Validators.minLength(3)]],
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]]
    });
  }

  ngOnInit(): void {
    // Load version info
    this.loadVersionInfo();
    
    // If already authenticated, redirect
    if (this.authService.isAuthenticated()) {
      this.redirectBasedOnRole();
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

  onSubmit(): void {
    if (this.registerForm.valid) {
      this.isLoading = true;
      const registerData: RegisterRequest = {
        ...this.registerForm.value,
        role: 'USER'
      };

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
        case UserRole.CUSTOMER:
        case 'CUSTOMER':
          this.router.navigate(['/shops']);
          break;
        default:
          this.router.navigate(['/shops']);
          break;
      }
    }
  }

}