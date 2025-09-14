import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

export interface AssignmentRequest {
  orderId: number;
  assignedBy: number;
}

export interface AssignmentResponse {
  success: boolean;
  message: string;
  assignment?: {
    id: number;
    deliveryPartner: {
      id: number;
      name: string;
      email: string;
      mobileNumber: string;
    };
    order: {
      id: number;
      orderNumber: string;
      totalAmount: number;
    };
    status: string;
    assignedAt: string;
  };
}

@Injectable({
  providedIn: 'root'
})
export class AssignmentService {
  private readonly apiUrl = `${environment.apiUrl}/assignments`;

  constructor(private http: HttpClient) {}

  autoAssignOrder(orderId: number, assignedBy: number): Observable<AssignmentResponse> {
    return this.http.post<AssignmentResponse>(
      `${this.apiUrl}/orders/${orderId}/auto-assign`,
      {},
      { params: { assignedBy: assignedBy.toString() } }
    );
  }

  manualAssignOrder(orderId: number, deliveryPartnerId: number, assignedBy: number): Observable<AssignmentResponse> {
    return this.http.post<AssignmentResponse>(
      `${this.apiUrl}/orders/${orderId}/manual-assign`,
      {},
      {
        params: {
          deliveryPartnerId: deliveryPartnerId.toString(),
          assignedBy: assignedBy.toString()
        }
      }
    );
  }

  getAvailablePartners(): Observable<any> {
    return this.http.get(`${this.apiUrl}/available-partners`);
  }

  getOrderAssignments(orderId: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/orders/${orderId}`);
  }
}