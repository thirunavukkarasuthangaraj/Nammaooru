import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface OrderAssignment {
  id: number;
  orderId: number;
  deliveryPartnerId: number;
  status: 'ASSIGNED' | 'ACCEPTED' | 'PICKED_UP' | 'DELIVERED' | 'CANCELLED';
  assignedAt: string;
  acceptedAt?: string;
  pickedUpAt?: string;
  deliveredAt?: string;
  notes?: string;
}

export interface AssignmentRequest {
  orderId: number;
  deliveryPartnerId: number;
  notes?: string;
}

@Injectable({
  providedIn: 'root'
})
export class OrderAssignmentService {
  private apiUrl = `${environment.apiUrl}/delivery/assignments`;

  constructor(private http: HttpClient) {}

  assignOrder(request: AssignmentRequest): Observable<any> {
    return this.http.post<any>(this.apiUrl, request);
  }

  getOrderAssignments(orderId: number): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/order/${orderId}`);
  }

  getPartnerAssignments(partnerId: number): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/partner/${partnerId}`);
  }

  getActiveAssignments(partnerId: number): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/partner/${partnerId}/active`);
  }

  acceptAssignment(assignmentId: number, partnerId: number): Observable<any> {
    return this.http.put<any>(`${this.apiUrl}/${assignmentId}/accept`, { partnerId });
  }

  rejectAssignment(assignmentId: number, partnerId: number, reason: string): Observable<any> {
    return this.http.put<any>(`${this.apiUrl}/${assignmentId}/reject`, { partnerId, reason });
  }

  markPickedUp(assignmentId: number, partnerId: number): Observable<any> {
    return this.http.put<any>(`${this.apiUrl}/${assignmentId}/pickup`, { partnerId });
  }

  markDelivered(assignmentId: number, partnerId: number, notes?: string): Observable<any> {
    return this.http.put<any>(`${this.apiUrl}/${assignmentId}/complete`, { partnerId, notes });
  }
}