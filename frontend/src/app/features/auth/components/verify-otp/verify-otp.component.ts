import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { AuthService } from '@core/services/auth.service';
import { UserRole } from '@core/models/auth.model';

@Component({
  selector: 'app-verify-otp',
  templateUrl: './verify-otp.component.html',
  styleUrls: ['./verify-otp.component.scss']
})
export class VerifyOtpComponent implements OnInit {
  otpForm: FormGroup;
  isLoading = false;
  email: string = '';
  mobileNumber: string = '';
  resendCooldown = 0;
  private cooldownInterval: any;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router,
    private route: ActivatedRoute,
    private snackBar: MatSnackBar
  ) {
    this.otpForm = this.fb.group({
      otp: ['', [Validators.required, Validators.pattern(/^\d{6}$/)]]
    });
  }

  ngOnInit(): void {
    // Get email and mobile from query params
    this.route.queryParams.subscribe(params => {
      this.email = params['email'] || '';
      this.mobileNumber = params['mobile'] || '';

      if (!this.email && !this.mobileNumber) {
        this.snackBar.open('Invalid access. Please register again.', 'Close', {
          duration: 3000,
          panelClass: ['error-snackbar']
        });
        this.router.navigate(['/auth/register']);
      }
    });
  }

  onSubmit(): void {
    if (this.otpForm.valid) {
      this.isLoading = true;
      const otp = this.otpForm.value.otp;

      const verifyData = {
        email: this.email,
        mobileNumber: this.mobileNumber,
        otp: otp
      };

      this.authService.verifyOtp(verifyData).subscribe({
        next: (response) => {
          this.isLoading = false;
          this.snackBar.open('Email verified successfully! You can now login.', 'Close', {
            duration: 3000,
            horizontalPosition: 'end',
            verticalPosition: 'top',
            panelClass: ['success-snackbar']
          });

          // Redirect to login
          this.router.navigate(['/auth/login']);
        },
        error: (error) => {
          this.isLoading = false;

          let errorMessage = 'OTP verification failed. Please try again.';
          if (error.error && error.error.message) {
            errorMessage = error.error.message;
          }

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

  resendOtp(): void {
    if (this.resendCooldown > 0) {
      return;
    }

    const resendData = {
      email: this.email,
      mobileNumber: this.mobileNumber
    };

    this.authService.resendOtp(resendData).subscribe({
      next: () => {
        this.snackBar.open('OTP sent successfully!', 'Close', {
          duration: 3000,
          panelClass: ['success-snackbar']
        });
        this.startCooldown();
      },
      error: (error) => {
        let errorMessage = 'Failed to resend OTP. Please try again.';
        if (error.error && error.error.message) {
          errorMessage = error.error.message;
        }
        this.snackBar.open(errorMessage, 'Close', {
          duration: 5000,
          panelClass: ['error-snackbar']
        });
      }
    });
  }

  private startCooldown(): void {
    this.resendCooldown = 60;
    this.cooldownInterval = setInterval(() => {
      this.resendCooldown--;
      if (this.resendCooldown <= 0) {
        clearInterval(this.cooldownInterval);
      }
    }, 1000);
  }

  ngOnDestroy(): void {
    if (this.cooldownInterval) {
      clearInterval(this.cooldownInterval);
    }
  }
}
