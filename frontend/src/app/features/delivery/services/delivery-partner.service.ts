import { Injectable } from '@angular/core';
import { HttpClient, HttpParams, HttpEvent, HttpEventType, HttpRequest } from '@angular/common/http';
import { Observable, BehaviorSubject } from 'rxjs';
import { tap, map } from 'rxjs/operators';
import { ApiResponse, ApiResponseHelper } from '../../../core/models/api-response.model';
import { environment } from '../../../../environments/environment';

// Document related interfaces
export enum DeliveryPartnerDocumentType {
  DRIVER_PHOTO = 'DRIVER_PHOTO',
  DRIVING_LICENSE = 'DRIVING_LICENSE',
  LICENSE_FRONT = 'LICENSE_FRONT',
  LICENSE_BACK = 'LICENSE_BACK',
  VEHICLE_PHOTO = 'VEHICLE_PHOTO',
  RC_BOOK = 'RC_BOOK'
}

export enum DocumentVerificationStatus {
  PENDING = 'PENDING',
  VERIFIED = 'VERIFIED',
  REJECTED = 'REJECTED',
  EXPIRED = 'EXPIRED'
}

export interface DeliveryPartnerDocument {
  id?: number;
  partnerId: number;
  documentType: DeliveryPartnerDocumentType;
  documentName: string;
  originalFilename: string;
  filePath: string;
  fileSize: number;
  fileType?: string;
  verificationStatus: DocumentVerificationStatus;
  verificationNotes?: string;
  verifiedBy?: string;
  verifiedAt?: Date;
  licenseNumber?: string;
  vehicleNumber?: string;
  expiryDate?: Date;
  downloadUrl?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface DocumentUploadResult {
  type: 'progress' | 'complete';
  progress?: number;
  document?: DeliveryPartnerDocument;
}

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
    return this.http.get<any>(`${environment.apiUrl}/assignments/available-partners`)
      .pipe(
        map(response => ({
          success: response.success,
          data: response.partners,
          message: response.message,
          statusCode: response.statusCode || 200,
          timestamp: response.timestamp || new Date().toISOString()
        }))
      );
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

  // Document Management Methods
  getPartnerDocuments(partnerId: number): Observable<ApiResponse<DeliveryPartnerDocument[]>> {
    return this.http.get<ApiResponse<DeliveryPartnerDocument[]>>(`${this.apiUrl}/${partnerId}/documents`);
  }

  downloadPartnerDocument(partnerId: number, documentId: number): Observable<Blob> {
    return this.http.get(`${this.apiUrl}/${partnerId}/documents/${documentId}/download`, {
      responseType: 'blob'
    });
  }

  verifyPartnerDocument(
    partnerId: number,
    documentId: number,
    status: DocumentVerificationStatus,
    notes?: string
  ): Observable<ApiResponse<DeliveryPartnerDocument>> {
    return this.http.put<ApiResponse<DeliveryPartnerDocument>>(
      `${this.apiUrl}/${partnerId}/documents/${documentId}/verify`,
      { verificationStatus: status, verificationNotes: notes }
    );
  }

  uploadPartnerDocument(
    partnerId: number,
    documentType: DeliveryPartnerDocumentType,
    documentName: string,
    file: File,
    metadata?: { licenseNumber?: string; vehicleNumber?: string }
  ): Observable<DocumentUploadResult> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('documentType', documentType);
    formData.append('documentName', documentName);

    // Add metadata as separate form fields (matching backend controller)
    if (metadata?.licenseNumber) {
      formData.append('licenseNumber', metadata.licenseNumber);
    }
    if (metadata?.vehicleNumber) {
      formData.append('vehicleNumber', metadata.vehicleNumber);
    }

    const uploadRequest = new HttpRequest(
      'POST',
      `${this.apiUrl}/${partnerId}/documents/upload`,
      formData,
      {
        reportProgress: true,
        responseType: 'json'
      }
    );

    return this.http.request(uploadRequest).pipe(
      map((event: HttpEvent<any>) => {
        if (event.type === HttpEventType.UploadProgress) {
          const progress = Math.round(100 * event.loaded / (event.total || 1));
          return { type: 'progress' as const, progress };
        } else if (event.type === HttpEventType.Response) {
          return { type: 'complete' as const, document: event.body?.data };
        }
        return { type: 'progress' as const, progress: 0 };
      })
    );
  }

  deletePartnerDocument(partnerId: number, documentId: number): Observable<ApiResponse<void>> {
    return this.http.delete<ApiResponse<void>>(`${this.apiUrl}/${partnerId}/documents/${documentId}`);
  }

  getRequiredDocumentTypes(): DeliveryPartnerDocumentType[] {
    return [
      DeliveryPartnerDocumentType.DRIVER_PHOTO,
      DeliveryPartnerDocumentType.DRIVING_LICENSE,
      DeliveryPartnerDocumentType.VEHICLE_PHOTO,
      DeliveryPartnerDocumentType.RC_BOOK
    ];
  }

  getDocumentDisplayName(documentType: DeliveryPartnerDocumentType): string {
    switch (documentType) {
      case DeliveryPartnerDocumentType.DRIVER_PHOTO:
        return 'Driver Photo';
      case DeliveryPartnerDocumentType.DRIVING_LICENSE:
        return 'Driving License';
      case DeliveryPartnerDocumentType.LICENSE_FRONT:
        return 'License Front';
      case DeliveryPartnerDocumentType.LICENSE_BACK:
        return 'License Back';
      case DeliveryPartnerDocumentType.VEHICLE_PHOTO:
        return 'Vehicle Photo';
      case DeliveryPartnerDocumentType.RC_BOOK:
        return 'RC Book';
      default:
        return documentType;
    }
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