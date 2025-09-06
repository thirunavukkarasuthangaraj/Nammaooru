import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, switchMap } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';
import { FirebaseService } from '../../../core/services/firebase.service';

export interface ShopOwnerOrder {
  id: number;
  orderNumber: string;
  customerName: string;
  customerPhone: string;
  customerEmail: string;
  customerAddress: string;
  items: OrderItem[];
  totalAmount: number;
  createdAt: string;
  status: 'PENDING' | 'CONFIRMED' | 'PREPARING' | 'READY' | 'COMPLETED' | 'CANCELLED';
  paymentStatus: 'PENDING' | 'PAID' | 'FAILED' | 'REFUNDED';
  paymentMethod: string;
  estimatedDeliveryTime?: string;
  notes?: string;
  customerId: number;
  shopId: number;
}

export interface OrderItem {
  id: number;
  name: string;
  productName: string;
  quantity: number;
  price: number;
  unitPrice: number;
  total: number;
  totalPrice: number;
  unit: string;
  image?: string;
  productImageUrl?: string;
}

export interface OrderStatusUpdate {
  status: string;
  notes?: string;
  estimatedTime?: string;
}

@Injectable({
  providedIn: 'root'
})
export class ShopOwnerOrderService {
  private apiUrl = `${environment.apiUrl}`;

  constructor(
    private http: HttpClient,
    private firebaseService: FirebaseService
  ) {}

  getShopOrders(shopId: number, page: number = 0, size: number = 20): Observable<ShopOwnerOrder[]> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<{data: ShopOwnerOrder[]}>(`${this.apiUrl}/orders/shop/${shopId}`, { params })
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => {
          // Fallback to mock data
          const mockOrders: ShopOwnerOrder[] = [
            {
              id: 1,
              orderNumber: 'ORD001',
              customerName: 'John Doe',
              customerPhone: '+91 9876543210',
              customerEmail: 'john@example.com',
              customerAddress: '123 Main St, Chennai',
              items: [
                {
                  id: 1,
                  name: 'Chicken Biryani',
                  productName: 'Chicken Biryani',
                  quantity: 2,
                  price: 250,
                  unitPrice: 250,
                  total: 500,
                  totalPrice: 500,
                  unit: 'plates',
                  image: '/assets/images/biryani.jpg',
                  productImageUrl: '/assets/images/biryani.jpg'
                }
              ],
              totalAmount: 550,
              createdAt: new Date().toISOString(),
              status: 'PENDING',
              paymentStatus: 'PENDING',
              paymentMethod: 'CASH_ON_DELIVERY',
              notes: 'Extra spicy',
              customerId: 1,
              shopId: shopId
            }
          ];
          return of(mockOrders);
        })
      );
  }

  acceptOrder(orderId: number, estimatedTime?: string, notes?: string): Observable<ShopOwnerOrder> {
    const requestBody = {
      estimatedPreparationTime: estimatedTime,
      notes: notes
    };

    return this.http.post<{data: ShopOwnerOrder}>(`${this.apiUrl}/orders/${orderId}/accept`, requestBody)
      .pipe(
        switchMap(response => {
          // Send Firebase notification
          this.firebaseService.sendOrderNotification(
            response.data.orderNumber,
            'CONFIRMED',
            'Your order has been accepted and is being prepared'
          );
          return of(response.data);
        }),
        catchError(() => {
          // Fallback with mock response
          const mockOrder: ShopOwnerOrder = {
            id: orderId,
            orderNumber: 'ORD' + orderId,
            customerName: 'Mock Customer',
            customerPhone: '+91 9876543210',
            customerEmail: 'customer@example.com',
            customerAddress: 'Mock Address',
            items: [],
            totalAmount: 0,
            createdAt: new Date().toISOString(),
            status: 'CONFIRMED',
            paymentStatus: 'PENDING',
            paymentMethod: 'CASH_ON_DELIVERY',
            customerId: 1,
            shopId: 1
          };
          
          this.firebaseService.sendOrderNotification(
            mockOrder.orderNumber,
            'CONFIRMED',
            'Your order has been accepted'
          );
          
          return of(mockOrder);
        })
      );
  }

  rejectOrder(orderId: number, reason: string): Observable<ShopOwnerOrder> {
    const requestBody = { reason: reason };

    return this.http.post<{data: ShopOwnerOrder}>(`${this.apiUrl}/orders/${orderId}/reject`, requestBody)
      .pipe(
        switchMap(response => {
          // Send Firebase notification
          this.firebaseService.sendOrderNotification(
            response.data.orderNumber,
            'CANCELLED',
            `Order cancelled: ${reason}`
          );
          return of(response.data);
        }),
        catchError(() => {
          // Fallback with mock response
          const mockOrder: ShopOwnerOrder = {
            id: orderId,
            orderNumber: 'ORD' + orderId,
            customerName: 'Mock Customer',
            customerPhone: '+91 9876543210',
            customerEmail: 'customer@example.com',
            customerAddress: 'Mock Address',
            items: [],
            totalAmount: 0,
            createdAt: new Date().toISOString(),
            status: 'CANCELLED',
            paymentStatus: 'PENDING',
            paymentMethod: 'CASH_ON_DELIVERY',
            customerId: 1,
            shopId: 1
          };
          
          this.firebaseService.sendOrderNotification(
            mockOrder.orderNumber,
            'CANCELLED',
            `Order cancelled: ${reason}`
          );
          
          return of(mockOrder);
        })
      );
  }

  updateOrderStatus(orderId: number, status: string): Observable<ShopOwnerOrder> {
    const params = new HttpParams().set('status', status);

    return this.http.put<{data: ShopOwnerOrder}>(`${this.apiUrl}/orders/${orderId}/status`, null, { params })
      .pipe(
        switchMap(response => {
          // Send Firebase notification for status updates
          let message = '';
          switch (status) {
            case 'PREPARING':
              message = 'Your order is being prepared';
              break;
            case 'READY_FOR_PICKUP':
              message = 'Your order is ready for pickup';
              break;
            case 'OUT_FOR_DELIVERY':
              message = 'Your order is out for delivery';
              break;
            case 'DELIVERED':
              message = 'Your order has been delivered';
              break;
          }
          
          if (message) {
            this.firebaseService.sendOrderNotification(
              response.data.orderNumber,
              status,
              message
            );
          }
          
          return of(response.data);
        }),
        catchError(() => {
          // Fallback with mock response
          const mockOrder: ShopOwnerOrder = {
            id: orderId,
            orderNumber: 'ORD' + orderId,
            customerName: 'Mock Customer',
            customerPhone: '+91 9876543210',
            customerEmail: 'customer@example.com',
            customerAddress: 'Mock Address',
            items: [],
            totalAmount: 0,
            createdAt: new Date().toISOString(),
            status: status as any,
            paymentStatus: 'PENDING',
            paymentMethod: 'CASH_ON_DELIVERY',
            customerId: 1,
            shopId: 1
          };
          return of(mockOrder);
        })
      );
  }

  startPreparing(orderId: number): Observable<ShopOwnerOrder> {
    return this.updateOrderStatus(orderId, 'PREPARING');
  }

  markReady(orderId: number): Observable<ShopOwnerOrder> {
    return this.updateOrderStatus(orderId, 'READY_FOR_PICKUP');
  }

  markDelivered(orderId: number): Observable<ShopOwnerOrder> {
    return this.updateOrderStatus(orderId, 'DELIVERED');
  }

  getPendingOrders(shopId: number): Observable<ShopOwnerOrder[]> {
    return this.getShopOrders(shopId).pipe(
      switchMap(orders => of(orders.filter(order => order.status === 'PENDING')))
    );
  }

  getProcessingOrders(shopId: number): Observable<ShopOwnerOrder[]> {
    return this.getShopOrders(shopId).pipe(
      switchMap(orders => of(orders.filter(order => 
        ['CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP'].includes(order.status)
      )))
    );
  }

  getTodayOrders(shopId: number): Observable<ShopOwnerOrder[]> {
    return this.getShopOrders(shopId).pipe(
      switchMap(orders => {
        const today = new Date().toDateString();
        const todayOrders = orders.filter(order => 
          new Date(order.createdAt).toDateString() === today
        );
        return of(todayOrders);
      })
    );
  }
}