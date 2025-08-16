import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface OrderResponse {
  id: number;
  orderNumber: string;
  status: string;
  paymentStatus: string;
  paymentMethod: string;
  customerId: number;
  customerName: string;
  customerEmail: string;
  customerPhone: string;
  shopId: number;
  shopName: string;
  shopAddress: string;
  subtotal: number;
  taxAmount: number;
  deliveryFee: number;
  discountAmount: number;
  totalAmount: number;
  notes: string;
  cancellationReason: string;
  deliveryAddress: string;
  deliveryCity: string;
  deliveryState: string;
  deliveryPostalCode: string;
  deliveryPhone: string;
  deliveryContactName: string;
  fullDeliveryAddress: string;
  estimatedDeliveryTime: string;
  actualDeliveryTime: string;
  orderItems: OrderItemResponse[];
  createdAt: string;
  updatedAt: string;
  createdBy: string;
  updatedBy: string;
  statusLabel: string;
  paymentStatusLabel: string;
  paymentMethodLabel: string;
  canBeCancelled: boolean;
  isDelivered: boolean;
  isPaid: boolean;
  orderAge: string;
  itemCount: number;
}

export interface OrderItemResponse {
  id: number;
  shopProductId: number;
  productName: string;
  productDescription: string;
  productSku: string;
  productImageUrl: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
  specialInstructions: string;
}

export interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
}

@Injectable({
  providedIn: 'root'
})
export class OrderService {
  private apiUrl = `${environment.apiUrl}/orders`;

  constructor(private http: HttpClient) {}

  getAllOrders(page: number = 0, size: number = 10, sortBy: string = 'createdAt', sortDirection: string = 'desc'): Observable<PageResponse<OrderResponse>> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString())
      .set('sortBy', sortBy)
      .set('sortDirection', sortDirection);

    return this.http.get<PageResponse<OrderResponse>>(this.apiUrl, { params });
  }

  getOrderById(id: number): Observable<OrderResponse> {
    return this.http.get<OrderResponse>(`${this.apiUrl}/${id}`);
  }

  getOrderByNumber(orderNumber: string): Observable<OrderResponse> {
    return this.http.get<OrderResponse>(`${this.apiUrl}/number/${orderNumber}`);
  }

  updateOrderStatus(orderId: number, status: string): Observable<OrderResponse> {
    const params = new HttpParams().set('status', status);
    return this.http.put<OrderResponse>(`${this.apiUrl}/${orderId}/status`, {}, { params });
  }

  cancelOrder(orderId: number, reason: string): Observable<OrderResponse> {
    const params = new HttpParams().set('reason', reason);
    return this.http.put<OrderResponse>(`${this.apiUrl}/${orderId}/cancel`, {}, { params });
  }

  getOrdersByShop(shopId: number, page: number = 0, size: number = 10): Observable<PageResponse<OrderResponse>> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<PageResponse<OrderResponse>>(`${this.apiUrl}/shop/${shopId}`, { params });
  }

  getOrdersByCustomer(customerId: number, page: number = 0, size: number = 10): Observable<PageResponse<OrderResponse>> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<PageResponse<OrderResponse>>(`${this.apiUrl}/customer/${customerId}`, { params });
  }

  getOrdersByStatus(status: string, page: number = 0, size: number = 10): Observable<PageResponse<OrderResponse>> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<PageResponse<OrderResponse>>(`${this.apiUrl}/status/${status}`, { params });
  }

  searchOrders(searchTerm: string, page: number = 0, size: number = 10): Observable<PageResponse<OrderResponse>> {
    const params = new HttpParams()
      .set('searchTerm', searchTerm)
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<PageResponse<OrderResponse>>(`${this.apiUrl}/search`, { params });
  }

  getOrderStatuses(): Observable<any> {
    return this.http.get(`${this.apiUrl}/statuses`);
  }
}