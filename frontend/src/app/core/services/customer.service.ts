import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface Customer {
  id?: number;
  firstName: string;
  lastName: string;
  fullName?: string;
  email: string;
  mobileNumber: string;
  alternateMobileNumber?: string;
  gender?: 'MALE' | 'FEMALE' | 'OTHER' | 'PREFER_NOT_TO_SAY';
  dateOfBirth?: string;
  status?: 'ACTIVE' | 'INACTIVE' | 'BLOCKED' | 'PENDING_VERIFICATION';
  notes?: string;
  
  // Address Information
  addressLine1?: string;
  addressLine2?: string;
  city?: string;
  state?: string;
  postalCode?: string;
  country?: string;
  formattedAddress?: string;
  latitude?: number;
  longitude?: number;
  
  // Preferences
  emailNotifications?: boolean;
  smsNotifications?: boolean;
  promotionalEmails?: boolean;
  preferredLanguage?: string;
  
  // Customer Metrics
  totalOrders?: number;
  totalSpent?: number;
  lastOrderDate?: string;
  lastLoginDate?: string;
  
  // Account Information
  isVerified?: boolean;
  isActive?: boolean;
  emailVerified?: boolean;
  mobileVerified?: boolean;
  emailVerifiedAt?: string;
  mobileVerifiedAt?: string;
  referralCode?: string;
  referredBy?: string;
  referralCount?: number;
  
  // Timestamps
  createdBy?: string;
  updatedBy?: string;
  createdAt?: string;
  updatedAt?: string;
  
  // Helper fields for UI
  statusLabel?: string;
  genderLabel?: string;
  memberSince?: string;
  lastActivity?: string;
}

export interface CustomerAddress {
  id?: number;
  customerId: number;
  addressType: string;
  addressLabel?: string;
  addressLine1: string;
  addressLine2?: string;
  landmark?: string;
  city: string;
  state: string;
  postalCode: string;
  country?: string;
  fullAddress?: string;
  latitude?: number;
  longitude?: number;
  isDefault?: boolean;
  isActive?: boolean;
  contactPersonName?: string;
  contactMobileNumber?: string;
  deliveryInstructions?: string;
  displayLabel?: string;
  shortAddress?: string;
}

export interface CustomerStats {
  totalCustomers: number;
  activeCustomers: number;
  verifiedCustomers: number;
  totalSpending: number;
  averageOrdersPerCustomer: number;
}

export interface CustomerSearchParams {
  searchTerm?: string;
  status?: string;
  page?: number;
  size?: number;
  sortBy?: string;
  sortDirection?: string;
}

export interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
  first: boolean;
  last: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class CustomerService {
  private apiUrl = `${environment.apiUrl}/customers`;

  constructor(private http: HttpClient) {}

  // Create Customer
  createCustomer(customer: Customer): Observable<Customer> {
    return this.http.post<Customer>(this.apiUrl, customer);
  }

  // Get Customer by ID
  getCustomerById(id: number): Observable<Customer> {
    return this.http.get<Customer>(`${this.apiUrl}/${id}`);
  }

  // Get Customer by Email
  getCustomerByEmail(email: string): Observable<Customer> {
    return this.http.get<Customer>(`${this.apiUrl}/email/${email}`);
  }

  // Get Customer by Mobile Number
  getCustomerByMobileNumber(mobileNumber: string): Observable<Customer> {
    return this.http.get<Customer>(`${this.apiUrl}/mobile/${mobileNumber}`);
  }

  // Update Customer
  updateCustomer(id: number, customer: Customer): Observable<Customer> {
    return this.http.put<Customer>(`${this.apiUrl}/${id}`, customer);
  }

  // Delete Customer
  deleteCustomer(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }

  // Get All Customers with Pagination
  getAllCustomers(params: CustomerSearchParams = {}): Observable<PageResponse<Customer>> {
    let httpParams = new HttpParams();
    
    if (params.page !== undefined) httpParams = httpParams.set('page', params.page.toString());
    if (params.size !== undefined) httpParams = httpParams.set('size', params.size.toString());
    if (params.sortBy) httpParams = httpParams.set('sortBy', params.sortBy);
    if (params.sortDirection) httpParams = httpParams.set('sortDirection', params.sortDirection);

    return this.http.get<PageResponse<Customer>>(this.apiUrl, { params: httpParams });
  }

  // Search Customers
  searchCustomers(searchTerm: string, page = 0, size = 10): Observable<PageResponse<Customer>> {
    const params = new HttpParams()
      .set('searchTerm', searchTerm)
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<PageResponse<Customer>>(`${this.apiUrl}/search`, { params });
  }

  // Get Customers by Status
  getCustomersByStatus(status: string, page = 0, size = 10): Observable<PageResponse<Customer>> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<PageResponse<Customer>>(`${this.apiUrl}/status/${status}`, { params });
  }

  // Verify Email
  verifyEmail(customerId: number): Observable<Customer> {
    return this.http.post<Customer>(`${this.apiUrl}/${customerId}/verify-email`, {});
  }

  // Verify Mobile
  verifyMobile(customerId: number): Observable<Customer> {
    return this.http.post<Customer>(`${this.apiUrl}/${customerId}/verify-mobile`, {});
  }

  // Get Customer Statistics
  getCustomerStats(): Observable<CustomerStats> {
    return this.http.get<CustomerStats>(`${this.apiUrl}/stats`);
  }

  // Send Bulk Notification
  sendBulkNotification(customerIds: number[], subject: string, message: string, type: string): Observable<any> {
    const payload = { customerIds, subject, message, type };
    return this.http.post(`${this.apiUrl}/bulk/send-notification`, payload);
  }

  // Export Customers
  exportCustomers(format: string, customerIds?: number[], status?: string): Observable<any> {
    const payload = { format, customerIds, status };
    return this.http.post(`${this.apiUrl}/bulk/export`, payload);
  }

  // Customer Address methods
  getCustomerAddresses(customerId: number): Observable<CustomerAddress[]> {
    return this.http.get<CustomerAddress[]>(`${this.apiUrl}/${customerId}/addresses`);
  }

  createCustomerAddress(address: CustomerAddress): Observable<CustomerAddress> {
    return this.http.post<CustomerAddress>(`${this.apiUrl}/${address.customerId}/addresses`, address);
  }

  updateCustomerAddress(customerId: number, addressId: number, address: CustomerAddress): Observable<CustomerAddress> {
    return this.http.put<CustomerAddress>(`${this.apiUrl}/${customerId}/addresses/${addressId}`, address);
  }

  deleteCustomerAddress(customerId: number, addressId: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${customerId}/addresses/${addressId}`);
  }

  setDefaultAddress(customerId: number, addressId: number): Observable<CustomerAddress> {
    return this.http.post<CustomerAddress>(`${this.apiUrl}/${customerId}/addresses/${addressId}/set-default`, {});
  }

  // Utility methods
  getGenderOptions() {
    return [
      { value: 'MALE', label: 'Male' },
      { value: 'FEMALE', label: 'Female' },
      { value: 'OTHER', label: 'Other' },
      { value: 'PREFER_NOT_TO_SAY', label: 'Prefer not to say' }
    ];
  }

  getStatusOptions() {
    return [
      { value: 'ACTIVE', label: 'Active', class: 'status-active' },
      { value: 'INACTIVE', label: 'Inactive', class: 'status-inactive' },
      { value: 'BLOCKED', label: 'Blocked', class: 'status-blocked' },
      { value: 'PENDING_VERIFICATION', label: 'Pending Verification', class: 'status-pending' }
    ];
  }

  getAddressTypeOptions() {
    return [
      { value: 'HOME', label: 'Home' },
      { value: 'WORK', label: 'Work' },
      { value: 'OTHER', label: 'Other' }
    ];
  }

  // Format helpers
  formatCurrency(amount: number): string {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR'
    }).format(amount);
  }

  formatDate(dateString: string): string {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleDateString('en-IN', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  }

  formatDateTime(dateString: string): string {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleString('en-IN', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }
}