import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { DeliveryPartnerService } from '../../services/delivery-partner.service';
import { SwalService } from '../../../../core/services/swal.service';

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
    private swal: SwalService,
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
          this.swal.toast('Registration submitted successfully!', 'success');
          this.router.navigate(['/delivery/partner/dashboard']);
          this.isLoading = false;
        },
        error: (error) => {
          this.swal.toast('Registration failed. Please try again.', 'error');
          this.isLoading = false;
        }
      });
    }
  }
}