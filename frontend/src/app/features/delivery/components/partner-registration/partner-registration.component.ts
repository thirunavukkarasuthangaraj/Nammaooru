import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { DeliveryPartnerService } from '../../services/delivery-partner.service';

@Component({
  selector: 'app-partner-registration',
  templateUrl: './partner-registration.component.html',
  styleUrls: ['./partner-registration.component.scss']
})
export class PartnerRegistrationComponent implements OnInit {
  registrationForm: FormGroup;
  isLoading = false;
  vehicleTypes = ['BIKE', 'SCOOTER', 'CAR', 'BICYCLE'];

  constructor(
    private fb: FormBuilder,
    public router: Router,
    private snackBar: MatSnackBar,
    private deliveryPartnerService: DeliveryPartnerService
  ) {
    this.registrationForm = this.fb.group({
      name: ['', [Validators.required, Validators.minLength(2)]],
      email: ['', [Validators.required, Validators.email]],
      phone: ['', [Validators.required, Validators.pattern(/^\d{10}$/)]],
      address: ['', [Validators.required]],
      vehicleType: ['', [Validators.required]],
      vehicleNumber: ['', [Validators.required]],
      licenseNumber: ['', [Validators.required]],
      aadharNumber: ['', [Validators.required, Validators.pattern(/^\d{12}$/)]],
      bankAccountNumber: ['', [Validators.required]],
      ifscCode: ['', [Validators.required]]
    });
  }

  ngOnInit(): void {}

  onSubmit(): void {
    if (this.registrationForm.valid) {
      this.isLoading = true;
      this.deliveryPartnerService.registerPartner(this.registrationForm.value).subscribe({
        next: (response) => {
          this.snackBar.open('Registration submitted successfully!', 'Close', { duration: 3000 });
          this.router.navigate(['/delivery/partner/dashboard']);
          this.isLoading = false;
        },
        error: (error) => {
          this.snackBar.open('Registration failed. Please try again.', 'Close', { duration: 3000 });
          this.isLoading = false;
        }
      });
    }
  }
}