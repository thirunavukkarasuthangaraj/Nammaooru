import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ApiResponse } from '../../../core/models/api-response.model';
import { environment } from '../../../../environments/environment';

export interface OrderAssignment {
  id: number;
  orderId: number;
  orderNumber: string;
  partnerId: number;
  partnerName: string;
  partnerPhone: string;
  
  assignedAt: Date;
  assignedBy?: number;
  assignedByName?: string;
  assignmentType: 'AUTO' | 'MANUAL';
  
  status: 'ASSIGNED' | 'ACCEPTED' | 'REJECTED' | 'PICKED_UP' | 'IN_TRANSIT' | 'DELIVERED' | 'FAILED' | 'CANCELLED' | 'RETURNED';
  acceptedAt?: Date;
  pickupTime?: Date;
  deliveryTime?: Date;
  
  pickupLatitude?: number;
  pickupLongitude?: number;
  deliveryLatitude?: number;
  deliveryLongitude?: number;
  
  deliveryFee: number;
  partnerCommission: number;
  
  rejectionReason?: string;
  deliveryNotes?: string;
  customerRating?: number;
  customerFeedback?: string;
  
  currentLatitude?: number;
  currentLongitude?: number;
  lastLocationUpdate?: Date;
  distanceToDestination?: number;
  estimatedArrivalTime?: Date;
  
  totalTimeMinutes?: number;
  deliveryTimeMinutes?: number;
  isDelayed: boolean;
  
  createdAt: Date;
  updatedAt: Date;

  // Additional properties for display
  shopName?: string;
  customerName?: string;
  customerPhone?: string;
  deliveryAddress?: string;
  distance?: number;
  estimatedTime?: number;
  timeRemaining?: number;
}

export interface OrderAssignmentRequest {
  orderId: number;
  partnerId?: number;
  assignmentType: 'AUTO' | 'MANUAL';
  deliveryFee: number;
  partnerCommission?: number;
  pickupLatitude?: number;
  pickupLongitude?: number;
  deliveryLatitude?: number;
  deliveryLongitude?: number;
  notes?: string;
}

@Injectable({
  providedIn: 'root'
})
export class OrderAssignmentService {
  private readonly apiUrl = `${environment.apiUrl}/delivery/assignments`;

  constructor(private http: HttpClient) {}

  // Assignment Management
  assignOrder(request: OrderAssignmentRequest): Observable<ApiResponse<OrderAssignment>> {
    return this.http.post<ApiResponse<OrderAssignment>>(this.apiUrl, request);
  }

  getAssignmentById(id: number): Observable<ApiResponse<OrderAssignment>> {
    // Mock data for testing
    const mockAssignment: OrderAssignment = {
      id: id,
      orderId: 12345,
      orderNumber: 'ORD-2025-001',
      partnerId: 1,
      partnerName: 'Raj Kumar',
      partnerPhone: '+91 9876543210',
      assignedAt: new Date(),
      assignmentType: 'AUTO',
      status: 'IN_TRANSIT',
      acceptedAt: new Date(Date.now() - 1800000), // 30 minutes ago
      pickupTime: new Date(Date.now() - 1200000), // 20 minutes ago
      deliveryLatitude: 12.9716,
      deliveryLongitude: 77.5946,
      deliveryFee: 45.00,
      partnerCommission: 25.00,
      currentLatitude: 12.9700,
      currentLongitude: 77.5930,
      lastLocationUpdate: new Date(Date.now() - 120000), // 2 minutes ago
      distanceToDestination: 2.5,
      estimatedArrivalTime: new Date(Date.now() + 900000), // 15 minutes from now
      totalTimeMinutes: 45,
      deliveryTimeMinutes: 25,
      isDelayed: false,
      createdAt: new Date(),
      updatedAt: new Date(),
      shopName: 'Raj Electronics',
      customerName: 'Priya Sharma',
      customerPhone: '+91 9123456789',
      deliveryAddress: '123, MG Road, Bangalore, Karnataka 560001',
      distance: 5.2,
      estimatedTime: 15,
      timeRemaining: 15
    };

    return new Observable(observer => {
      setTimeout(() => {
        observer.next({
          statusCode: 'SUCCESS',
          message: 'Assignment retrieved successfully',
          data: mockAssignment,
          timestamp: new Date().toISOString()
        });
        observer.complete();
      }, 500); // Simulate network delay
    });
  }

  getAssignmentsByOrder(orderId: number): Observable<ApiResponse<OrderAssignment[]>> {
    return this.http.get<ApiResponse<OrderAssignment[]>>(`${this.apiUrl}/order/${orderId}`);
  }

  getAssignmentsByPartner(partnerId: number, page: number = 0, size: number = 10): Observable<ApiResponse<any>> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());
    
    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/partner/${partnerId}`, { params });
  }

  getActiveAssignmentsByPartner(partnerId: number): Observable<ApiResponse<OrderAssignment[]>> {
    return this.http.get<ApiResponse<OrderAssignment[]>>(`${this.apiUrl}/partner/${partnerId}/active`);
  }

  getAssignmentsByStatus(status: string): Observable<ApiResponse<OrderAssignment[]>> {
    return this.http.get<ApiResponse<OrderAssignment[]>>(`${this.apiUrl}/status/${status}`);
  }

  // Partner Actions
  acceptAssignment(assignmentId: number, partnerId: number): Observable<ApiResponse<OrderAssignment>> {
    return this.http.put<ApiResponse<OrderAssignment>>(`${this.apiUrl}/${assignmentId}/accept`, { partnerId });
  }

  rejectAssignment(assignmentId: number, partnerId: number, reason: string): Observable<ApiResponse<OrderAssignment>> {
    return this.http.put<ApiResponse<OrderAssignment>>(`${this.apiUrl}/${assignmentId}/reject`, { 
      partnerId, 
      reason 
    });
  }

  markPickedUp(assignmentId: number, partnerId: number): Observable<ApiResponse<OrderAssignment>> {
    return this.http.put<ApiResponse<OrderAssignment>>(`${this.apiUrl}/${assignmentId}/pickup`, { partnerId });
  }

  startDelivery(assignmentId: number, partnerId: number): Observable<ApiResponse<OrderAssignment>> {
    return this.http.put<ApiResponse<OrderAssignment>>(`${this.apiUrl}/${assignmentId}/start-delivery`, { partnerId });
  }

  completeDelivery(assignmentId: number, partnerId: number, notes?: string): Observable<ApiResponse<OrderAssignment>> {
    return this.http.put<ApiResponse<OrderAssignment>>(`${this.apiUrl}/${assignmentId}/complete`, { 
      partnerId, 
      notes 
    });
  }

  markFailed(assignmentId: number, partnerId: number, reason: string): Observable<ApiResponse<OrderAssignment>> {
    return this.http.put<ApiResponse<OrderAssignment>>(`${this.apiUrl}/${assignmentId}/fail`, { 
      partnerId, 
      reason 
    });
  }

  // Admin Actions
  processExpiredAssignments(): Observable<ApiResponse<string>> {
    return this.http.post<ApiResponse<string>>(`${this.apiUrl}/process-expired`, {});
  }

  // Mock method for available orders (to be replaced with actual API)
  getAvailableOrders(): Observable<ApiResponse<OrderAssignment[]>> {
    // This should be replaced with actual API call to get available orders
    // For now, returning empty array
    return new Observable(observer => {
      observer.next({
        statusCode: 'SUCCESS',
        message: 'Available orders retrieved',
        data: [],
        timestamp: new Date().toISOString()
      });
      observer.complete();
    });
  }

  // Utility Methods
  getStatusColor(status: string): string {
    switch (status) {
      case 'ASSIGNED': return 'primary';
      case 'ACCEPTED': return 'accent';
      case 'PICKED_UP': return 'primary';
      case 'IN_TRANSIT': return 'accent';
      case 'DELIVERED': return 'primary';
      case 'REJECTED': return 'warn';
      case 'FAILED': return 'warn';
      case 'CANCELLED': return 'warn';
      default: return 'basic';
    }
  }

  getStatusIcon(status: string): string {
    switch (status) {
      case 'ASSIGNED': return 'assignment';
      case 'ACCEPTED': return 'check_circle';
      case 'PICKED_UP': return 'shopping_cart';
      case 'IN_TRANSIT': return 'local_shipping';
      case 'DELIVERED': return 'check_circle_outline';
      case 'REJECTED': return 'cancel';
      case 'FAILED': return 'error';
      case 'CANCELLED': return 'cancel';
      default: return 'help';
    }
  }

  formatTimeRemaining(assignedAt: Date): number {
    const now = new Date();
    const assigned = new Date(assignedAt);
    const diffMinutes = Math.floor((now.getTime() - assigned.getTime()) / (1000 * 60));
    const timeoutMinutes = 15; // 15 minutes to accept
    return Math.max(0, timeoutMinutes - diffMinutes);
  }

  isAssignmentExpired(assignedAt: Date): boolean {
    return this.formatTimeRemaining(assignedAt) === 0;
  }

  canAcceptAssignment(assignment: OrderAssignment): boolean {
    return assignment.status === 'ASSIGNED' && !this.isAssignmentExpired(assignment.assignedAt);
  }

  canRejectAssignment(assignment: OrderAssignment): boolean {
    return assignment.status === 'ASSIGNED';
  }

  canMarkPickedUp(assignment: OrderAssignment): boolean {
    return assignment.status === 'ACCEPTED';
  }

  canStartDelivery(assignment: OrderAssignment): boolean {
    return assignment.status === 'PICKED_UP';
  }

  canCompleteDelivery(assignment: OrderAssignment): boolean {
    return assignment.status === 'IN_TRANSIT';
  }

  // Additional methods for partner orders component
  getPartnerOrders(): Observable<OrderAssignment[]> {
    // Mock implementation - replace with actual API call
    return new Observable(observer => {
      observer.next([]);
      observer.complete();
    });
  }

  updateOrderStatus(orderId: number, status: string): Observable<ApiResponse<OrderAssignment>> {
    return this.http.put<ApiResponse<OrderAssignment>>(`${this.apiUrl}/order/${orderId}/status`, { status });
  }
}