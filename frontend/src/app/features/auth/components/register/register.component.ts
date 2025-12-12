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
      firstName: ['', [Validators.required, Validators.minLength(2)]],
      lastName: ['', [Validators.required, Validators.minLength(2)]],
      email: ['', [Validators.required, Validators.email]],
      mobile: ['', [Validators.required, Validators.pattern(/^[+]?[\d\s\-()]{10,}$/)]],
      password: ['', [Validators.required, Validators.minLength(8)]]
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
      const formData = this.registerForm.value;
      const registerData: RegisterRequest = {
        username: `${formData.firstName} ${formData.lastName}`, // Combine first + last name for username
        firstName: formData.firstName,
        lastName: formData.lastName,
        email: formData.email,
        mobileNumber: formData.mobile,
        password: formData.password,
        role: UserRole.CUSTOMER
      };

      this.authService.register(registerData).subscribe({
        next: (response) => {
          this.isLoading = false;
          this.snackBar.open('Registration successful! Please verify your email with the OTP sent.', 'Close', {
            duration: 5000,
            horizontalPosition: 'end',
            verticalPosition: 'top',
            panelClass: ['success-snackbar']
          });

          // Navigate to OTP verification screen
          this.router.navigate(['/auth/verify-otp'], {
            queryParams: {
              email: formData.email,
              mobile: formData.mobile
            }
          });
        },
        error: (error) => {
          this.isLoading = false;

          // SIMPLE ERROR HANDLING - NO BULLSHIT
          let errorMessage = 'Registration failed. Please try again.';

          // Get the error message from backend
          if (error.error && error.error.message) {
            const msg = error.error.message;

            // Check for specific errors and show user-friendly messages
            if (msg.includes('Mobile number already exists')) {
              errorMessage = 'This mobile number is already registered. Please try with a different number.';
            } else if (msg.includes('Email already exists')) {
              errorMessage = 'This email is already registered. Please use a different email.';
            } else {
              errorMessage = msg; // Just show the server message
            }
          }

          // Show the error message
          this.snackBar.open(errorMessage, 'Close', {
            duration: 5000,
            horizontalPosition: 'center',
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