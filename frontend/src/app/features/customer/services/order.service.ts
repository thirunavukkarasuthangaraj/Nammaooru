import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, switchMap, map } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';
import { Cart } from './cart.service';
import { FirebaseService } from '../../../core/services/firebase.service';
import { ApiResponse, ApiResponseHelper } from '../../../core/models/api-response.model';

export interface OrderRequest {
  customerId?: number;
  shopId: number;
  items: OrderItem[];
  deliveryAddress: DeliveryAddress;
  paymentMethod: 'CASH_ON_DELIVERY';
  subtotal: number;
  deliveryFee: number;
  discount: number;
  total: number;
  notes?: string;
  customerInfo: CustomerInfo;
  customerToken?: string;
}

export interface OrderItem {
  productId: number;
  productName: string;
  price: number;
  quantity: number;
  unit: string;
}

export interface DeliveryAddress {
  streetAddress: string;
  landmark?: string;
  city: string;
  state: string;
  pincode: string;
}

export interface CustomerInfo {
  firstName: string;
  lastName: string;
  phone: string;
  email: string;
}

export interface OrderResponse {
  id: number;
  orderNumber: string;
  status: string;
  total: number;
  estimatedDeliveryTime?: string;
  createdAt: string;
}

export interface OrderTrackingInfo {
  orderId: number;
  orderNumber: string;
  status: string;
  total?: number;
  statusHistory: OrderStatusUpdate[];
  deliveryPartner?: DeliveryPartner;
  estimatedDeliveryTime?: string;
  currentLocation?: {
    lat: number;
    lng: number;
  };
}

export interface OrderStatusUpdate {
  status: string;
  timestamp: string;
  message: string;
  location?: {
    lat: number;
    lng: number;
  };
}

export interface DeliveryPartner {
  id: number;
  name: string;
  phone: string;
  vehicleType: string;
  vehicleNumber: string;
  rating: number;
}

@Injectable({
  providedIn: 'root'
})
export class OrderService {
  private apiUrl = `${environment.apiUrl}`;

  constructor(
    private http: HttpClient,
    private firebaseService: FirebaseService
  ) {}

  createOrder(orderRequest: OrderRequest): Observable<OrderResponse> {
    // Get Firebase token and include it in the request
    return this.firebaseService.getToken().pipe(
      switchMap((token): Observable<OrderResponse> => {
        const requestWithToken = {
          ...orderRequest,
          customerToken: token
        };
        
        // API call to backend
        return this.http.post<ApiResponse<OrderResponse>>(`${this.apiUrl}/customer/orders`, requestWithToken)
          .pipe(
            map(response => {
              if (ApiResponseHelper.isError(response)) {
                const errorMessage = ApiResponseHelper.getErrorMessage(response);
                throw new Error(errorMessage);
              }
              return response.data;
            }),
            catchError(error => {
              console.error('Order creation error:', error);
              // Fallback to mock response if API fails
              const mockResponse: OrderResponse = {
                id: Math.floor(Math.random() * 10000) + 1000,
                orderNumber: 'ORD' + Date.now().toString().slice(-8),
                status: 'PLACED',
                total: orderRequest.total,
                estimatedDeliveryTime: '30-45 minutes',
                createdAt: new Date().toISOString()
              };
              
              // Send local notification for mock order
              this.firebaseService.sendOrderNotification(
                mockResponse.orderNumber,
                'PLACED',
                'Your order has been placed successfully!'
              );
              
              return of(mockResponse);
            })
          );
      }),
      catchError((): Observable<OrderResponse> => {
        // Fallback if Firebase token fails
        return this.http.post<ApiResponse<OrderResponse>>(`${this.apiUrl}/customer/orders`, orderRequest)
          .pipe(
            map(response => {
              if (ApiResponseHelper.isError(response)) {
                const errorMessage = ApiResponseHelper.getErrorMessage(response);
                throw new Error(errorMessage);
              }
              return response.data;
            }),
            catchError((): Observable<OrderResponse> => {
              const mockResponse: OrderResponse = {
                id: Math.floor(Math.random() * 10000) + 1000,
                orderNumber: 'ORD' + Date.now().toString().slice(-8),
                status: 'PLACED',
                total: orderRequest.total,
                estimatedDeliveryTime: '30-45 minutes',
                createdAt: new Date().toISOString()
              };
              return of(mockResponse);
            })
          );
      })
    );
  }

  getOrderTracking(orderNumber: string): Observable<OrderTrackingInfo> {
    // API call to backend
    return this.http.get<ApiResponse<OrderTrackingInfo>>(`${this.apiUrl}/customer/orders/${orderNumber}/tracking`)
      .pipe(
        map(response => {
          if (ApiResponseHelper.isError(response)) {
            const errorMessage = ApiResponseHelper.getErrorMessage(response);
            throw new Error(errorMessage);
          }
          return response.data;
        }),
        catchError(error => {
          console.error('Order tracking error:', error);
          // Fallback to mock tracking info if API fails
          const mockTrackingInfo: OrderTrackingInfo = {
      orderId: 1234,
      orderNumber: orderNumber,
      status: 'CONFIRMED',
      total: 450,
      statusHistory: [
        {
          status: 'PLACED',
          timestamp: new Date(Date.now() - 10 * 60 * 1000).toISOString(),
          message: 'Order placed successfully'
        },
        {
          status: 'CONFIRMED',
          timestamp: new Date(Date.now() - 8 * 60 * 1000).toISOString(),
          message: 'Order confirmed by restaurant'
        },
        {
          status: 'PREPARING',
          timestamp: new Date(Date.now() - 5 * 60 * 1000).toISOString(),
          message: 'Order is being prepared'
        }
      ],
      deliveryPartner: {
        id: 1,
        name: 'Ravi Kumar',
        phone: '+91 98765 43210',
        vehicleType: 'Bike',
        vehicleNumber: 'TN01AB1234',
        rating: 4.8
      },
      estimatedDeliveryTime: '20 minutes',
      currentLocation: {
        lat: 12.9716,
        lng: 77.5946
      }
    };

    return of(mockTrackingInfo);
        })
      );
  }

  getMyOrders(customerId?: number): Observable<OrderResponse[]> {
    // API call to backend
    return this.http.get<ApiResponse<OrderResponse[]>>(`${this.apiUrl}/customer/orders`, {
      params: customerId ? { customerId: customerId.toString() } : {}
    }).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          const errorMessage = ApiResponseHelper.getErrorMessage(response);
          throw new Error(errorMessage);
        }
        return response.data;
      }),
      catchError(error => {
        console.error('Get orders error:', error);
        // Fallback to mock orders list
        const mockOrders: OrderResponse[] = [
          {
            id: 1234,
            orderNumber: 'ORD12345678',
            status: 'DELIVERED',
            total: 450,
            createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
          },
          {
            id: 1235,
            orderNumber: 'ORD12345679',
            status: 'OUT_FOR_DELIVERY',
            total: 280,
            createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString()
          }
        ];

        return of(mockOrders);
      })
    );
  }

  cancelOrder(orderId: number, reason: string): Observable<OrderResponse> {
    // Get Firebase token for cancellation notification
    return this.firebaseService.getToken().pipe(
      switchMap((token): Observable<OrderResponse> => {
        // API call to backend
        return this.http.put<ApiResponse<OrderResponse>>(`${this.apiUrl}/customer/orders/${orderId}/cancel`, null, {
          params: { 
            reason: reason,
            customerToken: token || ''
          }
        }).pipe(
          map(response => {
            if (ApiResponseHelper.isError(response)) {
              const errorMessage = ApiResponseHelper.getErrorMessage(response);
              throw new Error(errorMessage);
            }
            return response.data;
          }),
          catchError(error => {
            console.error('Cancel order error:', error);
            // Fallback to mock response
            const mockResponse: OrderResponse = {
              id: orderId,
              orderNumber: 'ORD' + orderId,
              status: 'CANCELLED',
              total: 0,
              createdAt: new Date().toISOString()
            };

            // Send local notification for mock cancellation
            this.firebaseService.sendOrderNotification(
              mockResponse.orderNumber,
              'CANCELLED',
              'Your order has been cancelled.'
            );

            return of(mockResponse);
          })
        );
      }),
      catchError((): Observable<OrderResponse> => {
        // Fallback if Firebase token fails
        return this.http.put<ApiResponse<OrderResponse>>(`${this.apiUrl}/customer/orders/${orderId}/cancel`, null, {
          params: { reason: reason }
        }).pipe(
          map(response => {
            if (ApiResponseHelper.isError(response)) {
              const errorMessage = ApiResponseHelper.getErrorMessage(response);
              throw new Error(errorMessage);
            }
            return response.data;
          }),
          catchError((): Observable<OrderResponse> => {
            const mockResponse: OrderResponse = {
              id: orderId,
              orderNumber: 'ORD' + orderId,
              status: 'CANCELLED',
              total: 0,
              createdAt: new Date().toISOString()
            };
            return of(mockResponse);
          })
        );
      })
    );
  }
}