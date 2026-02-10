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
  private readonly apiUrl = `${environment.apiUrl}/assignments`;

  constructor(private http: HttpClient) {}

  // Assignment Management
  assignOrder(request: OrderAssignmentRequest): Observable<ApiResponse<OrderAssignment>> {
    return this.http.post<ApiResponse<OrderAssignment>>(this.apiUrl, request);
  }

  getAssignmentById(id: number): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/${id}`);
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

  // Partner Actions - POST with query params to match backend @RequestParam
  acceptAssignment(assignmentId: number, partnerId: number): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/${assignmentId}/accept?partnerId=${partnerId}`, {});
  }

  rejectAssignment(assignmentId: number, partnerId: number, reason: string): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/${assignmentId}/reject?partnerId=${partnerId}&reason=${encodeURIComponent(reason)}`, {});
  }

  markPickedUp(assignmentId: number, partnerId: number): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/${assignmentId}/pickup?partnerId=${partnerId}`, {});
  }

  markDelivered(assignmentId: number, partnerId: number, notes?: string): Observable<any> {
    let url = `${this.apiUrl}/${assignmentId}/deliver?partnerId=${partnerId}`;
    if (notes) {
      url += `&deliveryNotes=${encodeURIComponent(notes)}`;
    }
    return this.http.post<any>(url, {});
  }

  // Aliases for backward compatibility
  startDelivery(assignmentId: number, partnerId: number): Observable<any> {
    return this.markPickedUp(assignmentId, partnerId);
  }

  completeDelivery(assignmentId: number, partnerId: number, notes?: string): Observable<any> {
    return this.markDelivered(assignmentId, partnerId, notes);
  }

  // Admin Actions
  processExpiredAssignments(): Observable<ApiResponse<string>> {
    return this.http.post<ApiResponse<string>>(`${this.apiUrl}/process-expired`, {});
  }

  // Get available orders (ASSIGNED status) for a delivery partner
  getAvailableOrdersForPartner(partnerId: number): Observable<any> {
    return this.http.get<any>(`${environment.apiUrl}/mobile/delivery-partner/orders/${partnerId}/available`);
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

  // Get active orders for a delivery partner (ACCEPTED, PICKED_UP, IN_TRANSIT, etc.)
  getActiveOrdersForPartner(partnerId: number): Observable<any> {
    return this.http.get<any>(`${environment.apiUrl}/mobile/delivery-partner/orders/${partnerId}/active`);
  }

  updateOrderStatus(orderId: number, status: string): Observable<ApiResponse<OrderAssignment>> {
    return this.http.put<ApiResponse<OrderAssignment>>(`${this.apiUrl}/order/${orderId}/status`, { status });
  }
}