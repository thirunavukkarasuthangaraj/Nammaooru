import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, switchMap, map } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';
import { FirebaseService } from '../../../core/services/firebase.service';
import { AuthService } from '../../../core/services/auth.service';

export interface ShopOwnerOrder {
  id: number;
  orderNumber: string;
  customerName: string;
  customerPhone: string;
  customerEmail: string;
  customerAddress: string;
  deliveryAddress?: string;
  deliveryType?: 'HOME_DELIVERY' | 'SELF_PICKUP';
  items: OrderItem[];
  totalAmount: number;
  createdAt: string;
  status: 'PENDING' | 'CONFIRMED' | 'PREPARING' | 'READY_FOR_PICKUP' | 'OUT_FOR_DELIVERY' | 'DELIVERED' | 'CANCELLED' | 'SELF_PICKUP_COLLECTED' | 'RETURNING_TO_SHOP' | 'RETURNED_TO_SHOP';
  paymentStatus: 'PENDING' | 'PAID' | 'FAILED' | 'REFUNDED';
  paymentMethod: string;
  estimatedDeliveryTime?: string;
  notes?: string;
  customerId: number;
  shopId: number;
  couponCode?: string;
  discountAmount?: number;
  assignedToDeliveryPartner?: boolean;
  assignedDriver?: {
    id: number;
    name: string;
    driverId: string;
    phone: string;
    vehicleNumber: string;
  };
  driverVerified?: boolean;
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
  addedByShopOwner?: boolean; // True if item was added by shop owner after original order
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
    private firebaseService: FirebaseService,
    private authService: AuthService
  ) {}

  getShopOrders(shopId: string | number, page: number = 0, size: number = 20): Observable<ShopOwnerOrder[]> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    // Debug authentication state
    const token = this.authService.getToken();
    const isAuthenticated = this.authService.isAuthenticated();
    console.log('Making API request to:', `${this.apiUrl}/orders/shop/${shopId}`);
    console.log('Token from authService:', token);
    console.log('Full token value:', token ? token.substring(0, 20) + '...' : 'No token');
    console.log('Authentication status:', isAuthenticated);

    return this.http.get<{data: {content: ShopOwnerOrder[], totalItems: number, totalPages: number}}>(`${this.apiUrl}/orders/shop/${shopId}`, { params })
      .pipe(
        switchMap(response => {
          // Extract the actual orders from the paginated response
          const orders = response.data?.content || [];
          console.log('API Response received - Orders:', orders.length, 'Total items:', response.data?.totalItems);

          // Transform the API response to match our interface
          const transformedOrders = orders.map((order: any) => ({
            ...order,
            items: (order.orderItems || []).map((item: any) => ({
              id: item.id,
              name: item.productName,
              productName: item.productName,
              quantity: item.quantity,
              price: item.unitPrice,
              unitPrice: item.unitPrice,
              total: item.totalPrice,
              totalPrice: item.totalPrice,
              unit: 'pcs',
              image: item.productImageUrl,
              productImageUrl: item.productImageUrl,
              addedByShopOwner: item.addedByShopOwner || false
            })),
            customerName: order.customerName,
            customerPhone: order.customerPhone || order.deliveryPhone,
            customerEmail: order.customerEmail,
            customerAddress: order.fullDeliveryAddress || order.deliveryAddress,
            deliveryAddress: order.fullDeliveryAddress || order.deliveryAddress
          }));

          console.log('Transformed orders:', transformedOrders);
          return of(transformedOrders);
        }),
        catchError((error) => {
          // Log the error details for debugging
          console.error('API Error details:', error);
          console.error('Error status:', error.status);
          console.error('Error message:', error.message);
          return of([]);
        })
      );
  }

  acceptOrder(orderId: number, estimatedTime?: string, notes?: string): Observable<ShopOwnerOrder> {
    const requestBody = {
      estimatedPreparationTime: estimatedTime,
      notes: notes
    };

    return this.http.post<{data: any}>(`${this.apiUrl}/orders/${orderId}/accept`, requestBody)
      .pipe(
        switchMap(response => {
          // Transform the order to match our interface
          const transformedOrder = this.transformOrder(response.data);

          // Send Firebase notification
          this.firebaseService.sendOrderNotification(
            transformedOrder.orderNumber,
            'CONFIRMED',
            'Your order has been accepted and is being prepared'
          );
          return of(transformedOrder);
        }),
        catchError((error) => {
          console.error('Error accepting order:', error);
          throw error;
        })
      );
  }

  // Get single order by ID
  getOrderById(orderId: number): Observable<ShopOwnerOrder> {
    return this.http.get<{data: any}>(`${this.apiUrl}/orders/${orderId}`)
      .pipe(
        map((response: {data: any}) => this.transformOrder(response.data)),
        catchError((error) => {
          console.error('Error fetching order:', error);
          throw error;
        })
      );
  }

  rejectOrder(orderId: number, reason: string): Observable<ShopOwnerOrder> {
    const requestBody = { reason: reason };

    return this.http.post<{data: any}>(`${this.apiUrl}/orders/${orderId}/reject`, requestBody)
      .pipe(
        switchMap(response => {
          // Transform the order to match our interface
          const transformedOrder = this.transformOrder(response.data);

          // Send Firebase notification
          this.firebaseService.sendOrderNotification(
            transformedOrder.orderNumber,
            'CANCELLED',
            `Order cancelled: ${reason}`
          );
          return of(transformedOrder);
        }),
        catchError((error) => {
          console.error('Error rejecting order:', error);
          throw error;
        })
      );
  }

  updateOrderStatus(orderId: number, status: string): Observable<ShopOwnerOrder> {
    const params = new HttpParams().set('status', status);

    return this.http.put<{data: any}>(`${this.apiUrl}/orders/${orderId}/status`, null, { params })
      .pipe(
        switchMap(response => {
          // Transform the order to match our interface
          const transformedOrder = this.transformOrder(response.data);

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
              transformedOrder.orderNumber,
              status,
              message
            );
          }

          return of(transformedOrder);
        }),
        catchError((error) => {
          console.error('Error updating order status:', error);
          throw error;
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

  // Handover SELF_PICKUP order to customer
  handoverSelfPickup(orderId: number): Observable<any> {
    return this.http.post<any>(
      `${this.apiUrl}/orders/${orderId}/handover-self-pickup`,
      {}
    ).pipe(
      catchError((error) => {
        console.error('Error handing over self-pickup order:', error);
        throw error;
      })
    );
  }

  // Verify pickup OTP for HOME_DELIVERY order
  verifyPickupOTP(orderId: number, otp: string): Observable<any> {
    const body = { otp };
    return this.http.post<any>(
      `${this.apiUrl}/orders/${orderId}/verify-pickup-otp`,
      body
    ).pipe(
      catchError((error) => {
        console.error('Error verifying pickup OTP:', error);
        throw error;
      })
    );
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

  verifyDriverForPickup(orderId: number, otp: string): Observable<{ success: boolean; message: string }> {
    const body = { otp };

    return this.http.post<{ success: boolean; message: string }>(
      `${this.apiUrl}/orders/${orderId}/verify-pickup`,
      body
    ).pipe(
      catchError((error) => {
        console.error('Error verifying driver:', error);
        throw error;
      })
    );
  }

  cancelOrder(orderId: number, reason: string): Observable<ShopOwnerOrder> {
    const requestBody = { reason: reason };

    return this.http.post<{data: any}>(`${this.apiUrl}/orders/${orderId}/cancel`, requestBody)
      .pipe(
        switchMap(response => {
          // Transform the order to match our interface
          const transformedOrder = this.transformOrder(response.data);

          // Send Firebase notification
          this.firebaseService.sendOrderNotification(
            transformedOrder.orderNumber,
            'CANCELLED',
            `Order cancelled: ${reason}`
          );
          return of(transformedOrder);
        }),
        catchError((error) => {
          console.error('Error cancelling order:', error);
          throw error;
        })
      );
  }

  /**
   * Add item to existing order (only for PENDING, CONFIRMED, PREPARING orders)
   */
  addItemToOrder(orderId: number, shopProductId: number, quantity: number, specialInstructions?: string): Observable<ShopOwnerOrder> {
    const requestBody = {
      shopProductId: shopProductId,
      quantity: quantity,
      specialInstructions: specialInstructions
    };

    return this.http.post<{data: any}>(`${this.apiUrl}/orders/${orderId}/add-item`, requestBody)
      .pipe(
        map(response => this.transformOrder(response.data)),
        catchError((error) => {
          console.error('Error adding item to order:', error);
          throw error;
        })
      );
  }

  /**
   * Remove item from existing order (only for PENDING, CONFIRMED, PREPARING orders)
   */
  removeItemFromOrder(orderId: number, itemId: number): Observable<ShopOwnerOrder> {
    return this.http.delete<{data: any}>(`${this.apiUrl}/orders/${orderId}/items/${itemId}`)
      .pipe(
        map(response => this.transformOrder(response.data)),
        catchError((error) => {
          console.error('Error removing item from order:', error);
          throw error;
        })
      );
  }

  /**
   * Transform backend order response to match frontend interface
   */
  private transformOrder(order: any): ShopOwnerOrder {
    return {
      ...order,
      items: (order.orderItems || order.items || []).map((item: any) => ({
        id: item.id,
        name: item.productName,
        productName: item.productName,
        quantity: item.quantity,
        price: item.unitPrice,
        unitPrice: item.unitPrice,
        total: item.totalPrice,
        totalPrice: item.totalPrice,
        unit: 'pcs',
        image: item.productImageUrl,
        productImageUrl: item.productImageUrl,
        addedByShopOwner: item.addedByShopOwner || false
      })),
      customerName: order.customerName,
      customerPhone: order.customerPhone || order.deliveryPhone,
      customerEmail: order.customerEmail,
      customerAddress: order.fullDeliveryAddress || order.deliveryAddress,
      deliveryAddress: order.fullDeliveryAddress || order.deliveryAddress
    };
  }
}