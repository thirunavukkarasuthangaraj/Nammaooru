import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, BehaviorSubject } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ApiResponse, ApiResponseHelper } from '../../../core/models/api-response.model';
import { environment } from '../../../../environments/environment';

export interface DeliveryPartner {
  id: number;
  partnerId: string;
  fullName: string;
  phoneNumber: string;
  alternatePhone?: string;
  email: string;
  dateOfBirth?: Date;
  gender?: 'MALE' | 'FEMALE' | 'OTHER';
  
  // Address Information
  addressLine1: string;
  addressLine2?: string;
  city: string;
  state: string;
  postalCode: string;
  country: string;
  
  // Vehicle Information
  vehicleType: 'BIKE' | 'SCOOTER' | 'BICYCLE' | 'CAR' | 'AUTO';
  vehicleNumber: string;
  vehicleModel?: string;
  vehicleColor?: string;
  licenseNumber: string;
  licenseExpiryDate: Date;
  
  // Bank Information
  bankAccountNumber?: string;
  bankIfscCode?: string;
  bankName?: string;
  accountHolderName?: string;
  
  // Service Information
  maxDeliveryRadius: number;
  status: 'PENDING' | 'APPROVED' | 'SUSPENDED' | 'BLOCKED' | 'ACTIVE';
  verificationStatus: 'PENDING' | 'VERIFIED' | 'REJECTED';
  isOnline: boolean;
  isAvailable: boolean;
  
  // Performance Metrics
  rating: number;
  totalDeliveries: number;
  successfulDeliveries: number;
  totalEarnings: number;
  successRate: number;
  
  // Current Location
  currentLatitude?: number;
  currentLongitude?: number;
  lastLocationUpdate?: Date;
  
  // Emergency Contact
  emergencyContactName?: string;
  emergencyContactPhone?: string;
  profileImageUrl?: string;
  
  // Audit Information
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
  updatedBy: string;
  
  // Document Verification
  totalDocuments: number;
  verifiedDocuments: number;
  allDocumentsVerified: boolean;
}

export interface PartnerRegistrationRequest {
  // Personal Information
  fullName: string;
  phoneNumber: string;
  alternatePhone?: string;
  email: string;
  dateOfBirth: Date;
  gender: 'MALE' | 'FEMALE' | 'OTHER';
  
  // Address Information
  addressLine1: string;
  addressLine2?: string;
  city: string;
  state: string;
  postalCode: string;
  country: string;
  
  // Vehicle Information
  vehicleType: 'BIKE' | 'SCOOTER' | 'BICYCLE' | 'CAR' | 'AUTO';
  vehicleNumber: string;
  vehicleModel?: string;
  vehicleColor?: string;
  licenseNumber: string;
  licenseExpiryDate: Date;
  
  // Bank Information
  bankAccountNumber?: string;
  bankIfscCode?: string;
  bankName?: string;
  accountHolderName?: string;
  
  // Service Information
  maxDeliveryRadius: number;
  emergencyContactName?: string;
  emergencyContactPhone?: string;
  
  // User Account
  username: string;
  password: string;
}

@Injectable({
  providedIn: 'root'
})
export class DeliveryPartnerService {
  private readonly apiUrl = `${environment.apiUrl}/delivery/partners`;
  
  private currentPartnerSubject = new BehaviorSubject<DeliveryPartner | null>(null);
  public currentPartner$ = this.currentPartnerSubject.asObservable();

  constructor(private http: HttpClient) {}

  // Partner Registration
  registerPartner(request: PartnerRegistrationRequest): Observable<ApiResponse<DeliveryPartner>> {
    return this.http.post<ApiResponse<DeliveryPartner>>(`${this.apiUrl}/register`, request);
  }

  // Get Partner Information
  getPartnerById(id: number): Observable<ApiResponse<DeliveryPartner>> {
    return this.http.get<ApiResponse<DeliveryPartner>>(`${this.apiUrl}/${id}`);
  }

  getPartnerByPartnerId(partnerId: string): Observable<ApiResponse<DeliveryPartner>> {
    return this.http.get<ApiResponse<DeliveryPartner>>(`${this.apiUrl}/partner-id/${partnerId}`);
  }

  getPartnerByUserId(userId: number): Observable<ApiResponse<DeliveryPartner>> {
    return this.http.get<ApiResponse<DeliveryPartner>>(`${this.apiUrl}/user/${userId}`)
      .pipe(
        tap(response => {
          if (ApiResponseHelper.isSuccess(response) && response.data) {
            this.currentPartnerSubject.next(response.data);
          }
        })
      );
  }

  // Partner Management
  getAllPartners(page: number = 0, size: number = 10): Observable<ApiResponse<any>> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());
    
    return this.http.get<ApiResponse<any>>(`${this.apiUrl}`, { params });
  }

  searchPartners(searchTerm: string, page: number = 0, size: number = 10): Observable<ApiResponse<any>> {
    const params = new HttpParams()
      .set('term', searchTerm)
      .set('page', page.toString())
      .set('size', size.toString());
    
    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/search`, { params });
  }

  getPartnersByStatus(status: string): Observable<ApiResponse<DeliveryPartner[]>> {
    return this.http.get<ApiResponse<DeliveryPartner[]>>(`${this.apiUrl}/status/${status}`);
  }

  getAvailablePartners(): Observable<ApiResponse<DeliveryPartner[]>> {
    return this.http.get<ApiResponse<DeliveryPartner[]>>(`${this.apiUrl}/available`);
  }

  getNearbyPartners(latitude: number, longitude: number): Observable<ApiResponse<DeliveryPartner[]>> {
    const params = new HttpParams()
      .set('latitude', latitude.toString())
      .set('longitude', longitude.toString());
    
    return this.http.get<ApiResponse<DeliveryPartner[]>>(`${this.apiUrl}/nearby`, { params });
  }

  // Status Updates
  updatePartnerStatus(id: number, status: string): Observable<ApiResponse<DeliveryPartner>> {
    return this.http.put<ApiResponse<DeliveryPartner>>(`${this.apiUrl}/${id}/status`, { status });
  }

  updateVerificationStatus(id: number, verificationStatus: string): Observable<ApiResponse<DeliveryPartner>> {
    return this.http.put<ApiResponse<DeliveryPartner>>(`${this.apiUrl}/${id}/verification-status`, { verificationStatus });
  }

  updateOnlineStatus(id: number, isOnline: boolean): Observable<ApiResponse<DeliveryPartner>> {
    return this.http.put<ApiResponse<DeliveryPartner>>(`${this.apiUrl}/${id}/online-status`, { isOnline })
      .pipe(
        tap(response => {
          if (ApiResponseHelper.isSuccess(response) && response.data) {
            this.currentPartnerSubject.next(response.data);
          }
        })
      );
  }

  updateAvailability(id: number, isAvailable: boolean): Observable<ApiResponse<DeliveryPartner>> {
    return this.http.put<ApiResponse<DeliveryPartner>>(`${this.apiUrl}/${id}/availability`, { isAvailable })
      .pipe(
        tap(response => {
          if (ApiResponseHelper.isSuccess(response) && response.data) {
            this.currentPartnerSubject.next(response.data);
          }
        })
      );
  }

  updateLocation(id: number, latitude: number, longitude: number): Observable<ApiResponse<DeliveryPartner>> {
    return this.http.put<ApiResponse<DeliveryPartner>>(`${this.apiUrl}/${id}/location`, { latitude, longitude });
  }

  // Statistics
  getPartnerCounts(): Observable<ApiResponse<{ [key: string]: number }>> {
    return this.http.get<ApiResponse<{ [key: string]: number }>>(`${this.apiUrl}/stats/counts`);
  }

  getPartnersWithExpiringLicenses(days: number = 30): Observable<ApiResponse<DeliveryPartner[]>> {
    const params = new HttpParams().set('days', days.toString());
    return this.http.get<ApiResponse<DeliveryPartner[]>>(`${this.apiUrl}/expiring-licenses`, { params });
  }

  // Utility Methods
  getCurrentPartner(): DeliveryPartner | null {
    return this.currentPartnerSubject.value;
  }

  setCurrentPartner(partner: DeliveryPartner): void {
    this.currentPartnerSubject.next(partner);
  }

  clearCurrentPartner(): void {
    this.currentPartnerSubject.next(null);
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'ACTIVE': return 'green';
      case 'PENDING': return 'orange';
      case 'SUSPENDED': return 'red';
      case 'BLOCKED': return 'red';
      default: return 'gray';
    }
  }

  getStatusIcon(status: string): string {
    switch (status) {
      case 'ACTIVE': return 'check_circle';
      case 'PENDING': return 'pending';
      case 'SUSPENDED': return 'pause_circle';
      case 'BLOCKED': return 'block';
      default: return 'help';
    }
  }

  getVehicleIcon(vehicleType: string): string {
    switch (vehicleType) {
      case 'BIKE': return 'motorcycle';
      case 'SCOOTER': return 'electric_scooter';
      case 'BICYCLE': return 'pedal_bike';
      case 'CAR': return 'directions_car';
      case 'AUTO': return 'local_taxi';
      default: return 'directions';
    }
  }
}