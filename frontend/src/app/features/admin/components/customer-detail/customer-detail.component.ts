import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { CustomerService, Customer } from '../../../../core/services/customer.service';

@Component({
  selector: 'app-customer-detail',
  templateUrl: './customer-detail.component.html',
  styleUrls: ['./customer-detail.component.scss']
})
export class CustomerDetailComponent implements OnInit {
  customer: Customer | null = null;
  isLoading = true;
  customerId: number;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private customerService: CustomerService
  ) {
    this.customerId = +this.route.snapshot.params['id'];
  }

  ngOnInit(): void {
    this.loadCustomer();
  }

  loadCustomer(): void {
    this.isLoading = true;
    this.customerService.getCustomerById(this.customerId).subscribe({
      next: (customer) => {
        this.customer = customer;
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading customer:', error);
        this.isLoading = false;
        this.router.navigate(['/admin/customers']);
      }
    });
  }

  editCustomer(): void {
    this.router.navigate(['/admin/customers', this.customerId, 'edit']);
  }

  goBack(): void {
    this.router.navigate(['/admin/customers']);
  }

  formatCurrency(amount: number): string {
    return this.customerService.formatCurrency(amount || 0);
  }

  formatDate(dateString: string): string {
    return this.customerService.formatDate(dateString);
  }

  formatDateTime(dateString: string): string {
    return this.customerService.formatDateTime(dateString);
  }

  getStatusClass(status: string): string {
    switch (status) {
      case 'ACTIVE': return 'status-active';
      case 'INACTIVE': return 'status-inactive';
      case 'BLOCKED': return 'status-blocked';
      case 'PENDING_VERIFICATION': return 'status-pending';
      default: return '';
    }
  }

  getGenderLabel(gender: string): string {
    switch (gender) {
      case 'MALE': return 'Male';
      case 'FEMALE': return 'Female';
      case 'OTHER': return 'Other';
      case 'PREFER_NOT_TO_SAY': return 'Prefer not to say';
      default: return 'Not specified';
    }
  }
}