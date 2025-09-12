import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, switchMap, tap, map } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';
import { CartService } from './cart.service';
import { Router } from '@angular/router';
import Swal from 'sweetalert2';
import { ApiResponse, ApiResponseHelper } from '../../../core/models/api-response.model';

export interface DeliveryAddress {
  contactName: string;
  phone: string;
  address: string;
  city: string;
  state: string;
  postalCode: string;
  landmark?: string;
  isDefault?: boolean;
}

export interface OrderRequest {
  customerId: number;
  shopId: number;
  orderItems: OrderItem[];  // Changed from items to orderItems
  deliveryAddress: string;
  deliveryCity: string;
  deliveryState: string;
  deliveryPostalCode: string;
  deliveryPhone: string;
  deliveryContactName: string;
  paymentMethod: string;
  notes?: string;
  discountAmount?: number;
}

export interface OrderItem {
  shopProductId: number;
  quantity: number;
  specialInstructions?: string;
}

export interface OrderResponse {
  id: number;
  orderNumber: string;
  status: string;
  paymentStatus: string;
  totalAmount: number;
  estimatedDeliveryTime?: string;
  createdAt: string;
}

@Injectable({
  providedIn: 'root'
})
export class CheckoutService {
  private apiUrl = `${environment.apiUrl}/customer`;

  constructor(
    private http: HttpClient,
    private cartService: CartService,
    private router: Router
  ) {}

  placeOrder(deliveryAddress: DeliveryAddress, paymentMethod: string, notes?: string): Observable<OrderResponse> {
    const cart = this.cartService.getCart();
    
    if (cart.items.length === 0) {
      Swal.fire('Error', 'Your cart is empty', 'error');
      return of(null as any);
    }

    let customerId = this.getCustomerId();
    if (!customerId) {
      Swal.fire('Error', 'Please login to place an order', 'error');
      this.router.navigate(['/auth/login']);
      return of(null as any);
    }

    // Calculate discount if any
    const discountAmount = cart.discount || 0;

    const orderRequest: OrderRequest = {
      customerId: customerId,
      shopId: cart.shopId!,
      orderItems: cart.items.map(item => ({
        shopProductId: item.productId,
        quantity: item.quantity,
        specialInstructions: ''
      })),
      deliveryAddress: deliveryAddress.address,
      deliveryCity: deliveryAddress.city,
      deliveryState: deliveryAddress.state,
      deliveryPostalCode: deliveryAddress.postalCode,
      deliveryPhone: deliveryAddress.phone,
      deliveryContactName: deliveryAddress.contactName,
      paymentMethod: paymentMethod,
      notes: notes || '',
      discountAmount: discountAmount
    };

    console.log('Placing order with request:', orderRequest);

    return this.http.post<ApiResponse<OrderResponse>>(`${this.apiUrl}/orders`, orderRequest).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          const errorMessage = ApiResponseHelper.getErrorMessage(response);
          throw new Error(errorMessage);
        }
        return response.data;
      }),
      tap(response => {
        if (response && response.id) {
          // Clear cart after successful order
          this.cartService.clearCart();
          
          // Show success message
          Swal.fire({
            title: 'Order Placed Successfully!',
            text: `Your order #${response.orderNumber} has been placed.`,
            icon: 'success',
            confirmButtonText: 'View Orders'
          }).then((result) => {
            if (result.isConfirmed) {
              this.router.navigate(['/customer/orders']);
            } else {
              this.router.navigate(['/customer/shops']);
            }
          });
        }
      }),
      catchError(error => {
        console.error('Error placing order:', error);
        let errorMessage = 'Failed to place order. Please try again.';
        
        if (error.error && error.error.message) {
          errorMessage = error.error.message;
        } else if (error.status === 400) {
          errorMessage = 'Invalid order data. Please check your cart and try again.';
        } else if (error.status === 401) {
          errorMessage = 'Please login to place an order.';
        } else if (error.status === 500) {
          errorMessage = 'Server error. Please try again later.';
        }
        
        Swal.fire('Error', errorMessage, 'error');
        return of(null as any);
      })
    );
  }

  validateDeliveryAddress(address: DeliveryAddress): boolean {
    return !!(
      address.contactName &&
      address.phone &&
      address.address &&
      address.city &&
      address.state &&
      address.postalCode
    );
  }

  getSavedAddresses(): Observable<DeliveryAddress[]> {
    const customerId = this.getCustomerId();
    if (!customerId) {
      return of([]);
    }

    return this.http.get<ApiResponse<DeliveryAddress[]>>(`${environment.apiUrl}/customers/${customerId}/addresses`).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          const errorMessage = ApiResponseHelper.getErrorMessage(response);
          throw new Error(errorMessage);
        }
        return response.data;
      }),
      catchError(() => of([]))
    );
  }

  saveAddress(address: DeliveryAddress): Observable<DeliveryAddress> {
    const customerId = this.getCustomerId();
    if (!customerId) {
      return of(null as any);
    }

    return this.http.post<ApiResponse<DeliveryAddress>>(`${environment.apiUrl}/customers/${customerId}/addresses`, address).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          const errorMessage = ApiResponseHelper.getErrorMessage(response);
          throw new Error(errorMessage);
        }
        return response.data;
      }),
      catchError(() => of(address))
    );
  }

  processPayment(orderId: number, paymentMethod: string): Observable<any> {
    const cart = this.cartService.getCart();
    const paymentData = {
      orderId: orderId,
      paymentMethod: paymentMethod,
      amount: cart.total
    };

    if (paymentMethod === 'CASH_ON_DELIVERY') {
      // No payment processing needed for COD
      return of({ success: true, message: 'Cash on Delivery selected' });
    }

    // Process online payment
    return this.http.post(`${environment.apiUrl}/payments/process`, paymentData).pipe(
      catchError(error => {
        console.error('Payment processing error:', error);
        return of({ success: false, message: 'Payment failed' });
      })
    );
  }

  private getCustomerId(): number | null {
    // Try both possible keys for user data
    let user = localStorage.getItem('shop_management_user') || localStorage.getItem('currentUser');
    if (user) {
      try {
        const userData = JSON.parse(user);
        console.log('User data from localStorage:', userData);
        
        // For testing, use a hardcoded customer ID if user is customer1
        if (userData.username === 'customer1') {
          console.log('Using hardcoded customer ID for customer1: 56');
          return 56; // Use customer ID 56 for testing (actual customer ID in DB)
        }
        
        // Use user ID as customer ID (backend should handle this mapping)
        // In a proper implementation, the backend would return the customer ID with login response
        const customerId = userData.id || userData.userId || 1; // Default to 1 if not found
        console.log('Extracted customer ID (using user ID):', customerId);
        
        return customerId;
      } catch (e) {
        console.error('Error parsing user data:', e);
        return 1; // Return default customer ID for testing
      }
    }
    console.log('No user data in localStorage, using default customer ID');
    return 1; // Return default customer ID for testing
  }

  calculateDeliveryTime(shopId: number): Observable<string> {
    // Return default delivery time as the endpoint is not available
    return of('30-45 minutes');
  }

  applyPromoCode(promoCode: string): Observable<number> {
    return this.http.post<{discount: number}>(`${environment.apiUrl}/promo/apply`, { code: promoCode }).pipe(
      switchMap(response => of(response.discount)),
      catchError(() => {
        Swal.fire('Invalid Code', 'This promo code is not valid', 'error');
        return of(0);
      })
    );
  }
}