import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, of, BehaviorSubject } from 'rxjs';
import { catchError, switchMap, tap } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';
import { FirebaseService } from '../../../core/services/firebase.service';
import Swal from 'sweetalert2';

export interface DeliveryAssignment {
  id: number;
  orderId: number;
  orderNumber: string;
  partnerId: number;
  partnerName: string;
  partnerPhone: string;
  status: string;
  assignmentType: string;
  pickupAddress: string;
  deliveryAddress: string;
  distance: number;
  estimatedTime: string;
  actualPickupTime?: string;
  actualDeliveryTime?: string;
  shopOTP?: string;
  customerOTP?: string;
  earnings: number;
  createdAt: string;
  updatedAt: string;
}

export interface DeliveryPartner {
  id: number;
  partnerId: string;
  name: string;
  phone: string;
  email: string;
  vehicleType: string;
  vehicleNumber: string;
  licenseNumber: string;
  isOnline: boolean;
  isAvailable: boolean;
  currentLocation?: {
    latitude: number;
    longitude: number;
  };
  rating: number;
  completedDeliveries: number;
  serviceAreas: string[];
}

export interface OTPVerificationRequest {
  assignmentId: number;
  otp: string;
  type: 'PICKUP' | 'DELIVERY';
}

export interface DeliveryProof {
  assignmentId: number;
  proofImage?: File;
  customerSignature?: string;
  notes?: string;
}

@Injectable({
  providedIn: 'root'
})
export class DeliveryAssignmentService {
  private apiUrl = `${environment.apiUrl}/delivery`;
  private currentAssignmentSubject = new BehaviorSubject<DeliveryAssignment | null>(null);
  public currentAssignment$ = this.currentAssignmentSubject.asObservable();

  constructor(
    private http: HttpClient,
    private firebaseService: FirebaseService
  ) {}

  // Get available delivery partners
  getAvailablePartners(orderId: number): Observable<DeliveryPartner[]> {
    return this.http.get<DeliveryPartner[]>(`${this.apiUrl}/partners/available`, {
      params: new HttpParams().set('orderId', orderId.toString())
    }).pipe(
      catchError(error => {
        console.error('Error fetching available partners:', error);
        return of([]);
      })
    );
  }

  // Auto-assign delivery partner
  autoAssignDeliveryPartner(orderId: number): Observable<DeliveryAssignment> {
    return this.http.post<DeliveryAssignment>(`${this.apiUrl}/orders/${orderId}/auto-assign`, {}).pipe(
      tap(assignment => {
        this.currentAssignmentSubject.next(assignment);
        
        // Send notification to delivery partner
        this.firebaseService.sendDeliveryNotification(
          assignment.partnerPhone,
          'New Delivery Assignment',
          `You have a new delivery for order #${assignment.orderNumber}`
        );
        
        Swal.fire({
          title: 'Partner Assigned!',
          text: `${assignment.partnerName} has been assigned to this order.`,
          icon: 'success',
          timer: 3000
        });
      }),
      catchError(error => {
        console.error('Error auto-assigning partner:', error);
        Swal.fire('Error', 'No delivery partners available. Please try manual assignment.', 'error');
        throw error;
      })
    );
  }

  // Manual assign delivery partner
  assignDeliveryPartner(orderId: number, partnerId: number): Observable<DeliveryAssignment> {
    return this.http.post<DeliveryAssignment>(`${this.apiUrl}/orders/${orderId}/assign`, { partnerId }).pipe(
      tap(assignment => {
        this.currentAssignmentSubject.next(assignment);
        
        // Send notification to delivery partner
        this.firebaseService.sendDeliveryNotification(
          assignment.partnerPhone,
          'New Delivery Assignment',
          `You have a new delivery for order #${assignment.orderNumber}`
        );
        
        Swal.fire({
          title: 'Partner Assigned!',
          text: `Delivery partner has been assigned to order #${assignment.orderNumber}.`,
          icon: 'success',
          timer: 3000
        });
      }),
      catchError(error => {
        console.error('Error assigning partner:', error);
        Swal.fire('Error', 'Failed to assign delivery partner', 'error');
        throw error;
      })
    );
  }

  // Get assignment details
  getAssignment(assignmentId: number): Observable<DeliveryAssignment> {
    return this.http.get<DeliveryAssignment>(`${this.apiUrl}/assignments/${assignmentId}`).pipe(
      tap(assignment => this.currentAssignmentSubject.next(assignment)),
      catchError(error => {
        console.error('Error fetching assignment:', error);
        throw error;
      })
    );
  }

  // Get assignments for a delivery partner
  getPartnerAssignments(partnerId: number, status?: string): Observable<DeliveryAssignment[]> {
    let params = new HttpParams();
    if (status) {
      params = params.set('status', status);
    }

    return this.http.get<DeliveryAssignment[]>(`${this.apiUrl}/partners/${partnerId}/assignments`, { params }).pipe(
      catchError(error => {
        console.error('Error fetching partner assignments:', error);
        return of([]);
      })
    );
  }

  // Accept delivery assignment
  acceptAssignment(assignmentId: number): Observable<DeliveryAssignment> {
    return this.http.post<DeliveryAssignment>(`${this.apiUrl}/assignments/${assignmentId}/accept`, {}).pipe(
      tap(assignment => {
        this.currentAssignmentSubject.next(assignment);
        
        Swal.fire({
          title: 'Assignment Accepted!',
          text: 'You have accepted this delivery assignment.',
          icon: 'success',
          timer: 2000
        });
      }),
      catchError(error => {
        console.error('Error accepting assignment:', error);
        Swal.fire('Error', 'Failed to accept assignment', 'error');
        throw error;
      })
    );
  }

  // Reject delivery assignment
  rejectAssignment(assignmentId: number, reason: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/assignments/${assignmentId}/reject`, { reason }).pipe(
      tap(() => {
        this.currentAssignmentSubject.next(null);
        
        Swal.fire({
          title: 'Assignment Rejected',
          text: 'The assignment has been rejected.',
          icon: 'info',
          timer: 2000
        });
      }),
      catchError(error => {
        console.error('Error rejecting assignment:', error);
        Swal.fire('Error', 'Failed to reject assignment', 'error');
        throw error;
      })
    );
  }

  // Start pickup (heading to shop)
  startPickup(assignmentId: number): Observable<DeliveryAssignment> {
    return this.http.post<DeliveryAssignment>(`${this.apiUrl}/assignments/${assignmentId}/start-pickup`, {}).pipe(
      tap(assignment => {
        this.currentAssignmentSubject.next(assignment);
        
        Swal.fire({
          title: 'Pickup Started',
          text: 'Heading to pickup location...',
          icon: 'info',
          timer: 2000
        });
      }),
      catchError(error => {
        console.error('Error starting pickup:', error);
        Swal.fire('Error', 'Failed to start pickup', 'error');
        throw error;
      })
    );
  }

  // Verify shop OTP and complete pickup
  verifyPickupOTP(assignmentId: number, otp: string): Observable<DeliveryAssignment> {
    const request: OTPVerificationRequest = {
      assignmentId: assignmentId,
      otp: otp,
      type: 'PICKUP'
    };

    return this.http.post<DeliveryAssignment>(`${this.apiUrl}/assignments/${assignmentId}/verify-pickup`, request).pipe(
      tap(assignment => {
        this.currentAssignmentSubject.next(assignment);
        
        // Send notification to customer
        this.firebaseService.sendOrderNotification(
          assignment.orderNumber,
          'OUT_FOR_DELIVERY',
          'Your order is out for delivery!'
        );
        
        Swal.fire({
          title: 'Pickup Completed!',
          text: 'Order picked up successfully. Heading to delivery location.',
          icon: 'success',
          timer: 3000
        });
      }),
      catchError(error => {
        console.error('Error verifying pickup OTP:', error);
        Swal.fire('Error', 'Invalid OTP. Please try again.', 'error');
        throw error;
      })
    );
  }

  // Start delivery (heading to customer)
  startDelivery(assignmentId: number): Observable<DeliveryAssignment> {
    return this.http.post<DeliveryAssignment>(`${this.apiUrl}/assignments/${assignmentId}/start-delivery`, {}).pipe(
      tap(assignment => {
        this.currentAssignmentSubject.next(assignment);
        
        Swal.fire({
          title: 'Delivery Started',
          text: 'Heading to delivery location...',
          icon: 'info',
          timer: 2000
        });
      }),
      catchError(error => {
        console.error('Error starting delivery:', error);
        Swal.fire('Error', 'Failed to start delivery', 'error');
        throw error;
      })
    );
  }

  // Verify customer OTP and complete delivery
  verifyDeliveryOTP(assignmentId: number, otp: string, proofImage?: File): Observable<DeliveryAssignment> {
    const formData = new FormData();
    formData.append('assignmentId', assignmentId.toString());
    formData.append('otp', otp);
    formData.append('type', 'DELIVERY');
    
    if (proofImage) {
      formData.append('proofImage', proofImage);
    }

    return this.http.post<DeliveryAssignment>(`${this.apiUrl}/assignments/${assignmentId}/verify-delivery`, formData).pipe(
      tap(assignment => {
        this.currentAssignmentSubject.next(assignment);
        
        // Send notification to customer
        this.firebaseService.sendOrderNotification(
          assignment.orderNumber,
          'DELIVERED',
          'Your order has been delivered successfully!'
        );
        
        Swal.fire({
          title: 'Delivery Completed!',
          html: `
            <div>
              <p>Order delivered successfully!</p>
              <p><strong>Earnings: ₹${assignment.earnings}</strong></p>
            </div>
          `,
          icon: 'success',
          confirmButtonText: 'Great!'
        });
      }),
      catchError(error => {
        console.error('Error verifying delivery OTP:', error);
        Swal.fire('Error', 'Invalid OTP. Please try again.', 'error');
        throw error;
      })
    );
  }

  // Update delivery location
  updateLocation(partnerId: number, latitude: number, longitude: number): Observable<any> {
    return this.http.post(`${this.apiUrl}/partners/${partnerId}/location`, { latitude, longitude }).pipe(
      catchError(error => {
        console.error('Error updating location:', error);
        return of(null);
      })
    );
  }

  // Get delivery tracking info
  getTrackingInfo(assignmentId: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/assignments/${assignmentId}/tracking`).pipe(
      catchError(error => {
        console.error('Error fetching tracking info:', error);
        return of({
          partnerLocation: null,
          estimatedTime: 'Calculating...',
          status: 'UNKNOWN'
        });
      })
    );
  }

  // Toggle partner online status
  toggleOnlineStatus(partnerId: number, isOnline: boolean): Observable<any> {
    return this.http.post(`${this.apiUrl}/partners/${partnerId}/status`, { isOnline }).pipe(
      tap(() => {
        Swal.fire({
          title: isOnline ? 'You are Online!' : 'You are Offline',
          text: isOnline ? 'You will receive delivery requests.' : 'You will not receive new requests.',
          icon: 'info',
          timer: 2000
        });
      }),
      catchError(error => {
        console.error('Error toggling online status:', error);
        Swal.fire('Error', 'Failed to update status', 'error');
        throw error;
      })
    );
  }

  // Get partner earnings
  getPartnerEarnings(partnerId: number, period: string = 'today'): Observable<any> {
    return this.http.get(`${this.apiUrl}/partners/${partnerId}/earnings`, {
      params: new HttpParams().set('period', period)
    }).pipe(
      catchError(() => {
        // Return mock data on error
        return of({
          totalEarnings: 0,
          completedDeliveries: 0,
          pendingEarnings: 0,
          averageRating: 0
        });
      })
    );
  }

  // Report issue
  reportIssue(assignmentId: number, issue: string, description: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/assignments/${assignmentId}/report-issue`, { issue, description }).pipe(
      tap(() => {
        Swal.fire({
          title: 'Issue Reported',
          text: 'Your issue has been reported to support.',
          icon: 'info',
          timer: 3000
        });
      }),
      catchError(error => {
        console.error('Error reporting issue:', error);
        Swal.fire('Error', 'Failed to report issue', 'error');
        throw error;
      })
    );
  }
}