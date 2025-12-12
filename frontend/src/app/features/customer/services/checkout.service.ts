import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, switchMap, tap, map } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';
import { CartService } from './cart.service';
import { Router } from '@angular/router';
import Swal from 'sweetalert2';
import { ApiResponse, ApiResponseHelper } from '../../../core/models/api-response.model';
import { AddressService, DeliveryLocation } from './address.service';

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
  deliveryType?: string;
  items: OrderItem[];
  deliveryAddress: DeliveryAddressRequest;
  paymentMethod: string;
  subtotal?: number;
  deliveryFee?: number;
  discount?: number;
  total?: number;
  notes?: string;
  customerInfo?: CustomerInfo;
  customerToken?: string;
}

export interface DeliveryAddressRequest {
  streetAddress: string;
  landmark?: string;
  city: string;
  state: string;
  pincode: string;
}

export interface CustomerInfo {
  customerId?: number;
  firstName: string;
  lastName: string;
  phone: string;
  email?: string;
}

export interface OrderItem {
  productId: number;  // Changed from shopProductId to match backend DTO
  productName: string;
  price: number;
  quantity: number;
  unit?: string;
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
    private router: Router,
    private addressService: AddressService
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

    // Calculate totals
    const discount = cart.discount || 0;
    const deliveryFee = 40;

    const orderRequest: OrderRequest = {
      customerId: customerId,
      shopId: cart.shopId!,
      deliveryType: 'HOME_DELIVERY',
      items: cart.items.map(item => ({
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        quantity: item.quantity,
        unit: item.unit || 'unit'
      })),
      deliveryAddress: {
        streetAddress: deliveryAddress.address,
        landmark: deliveryAddress.landmark || '',
        city: deliveryAddress.city,
        state: deliveryAddress.state,
        pincode: deliveryAddress.postalCode
      },
      paymentMethod: paymentMethod,
      subtotal: cart.subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      total: cart.total,
      notes: notes || '',
      customerInfo: {
        customerId: customerId,
        firstName: deliveryAddress.contactName.split(' ')[0] || '',
        lastName: deliveryAddress.contactName.split(' ').slice(1).join(' ') || '',
        phone: deliveryAddress.phone,
        email: ''
      }
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
          // Don't show SweetAlert or navigate here - let the component handle it
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
    // Use AddressService to get delivery locations and convert to DeliveryAddress format
    return this.addressService.getAddresses().pipe(
      map(locations => this.convertToDeliveryAddresses(locations)),
      catchError(() => of([]))
    );
  }

  /**
   * Convert DeliveryLocation to DeliveryAddress format for checkout
   */
  private convertToDeliveryAddresses(locations: DeliveryLocation[]): DeliveryAddress[] {
    return locations.map(location => ({
      contactName: location.contactPersonName,
      phone: location.contactMobileNumber,
      address: this.buildFullAddress(location),
      city: location.city,
      state: location.state,
      postalCode: location.pincode,
      landmark: location.landmark,
      isDefault: location.isDefault
    }));
  }

  /**
   * Build full address string from DeliveryLocation
   */
  private buildFullAddress(location: DeliveryLocation): string {
    const parts = [];

    if (location.flatHouse) parts.push(location.flatHouse);
    if (location.floor) parts.push(`Floor ${location.floor}`);
    if (location.street) parts.push(location.street);
    if (location.area) parts.push(location.area);
    if (location.village) parts.push(location.village);

    return parts.join(', ');
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

        // Use user ID as a placeholder (backend will determine actual customer ID from auth token)
        // The backend ignores the customerId sent in the request and uses the authenticated user's customer record
        const customerId = userData.id || userData.userId || 1;
        console.log('Using user ID as customer ID placeholder:', customerId);

        return customerId;
      } catch (e) {
        console.error('Error parsing user data:', e);
        return 1;
      }
    }
    console.log('No user data in localStorage, using default customer ID');
    return 1;
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

  /**
   * Place order with delivery type (HOME_DELIVERY or SELF_PICKUP)
   */
  placeOrderWithDeliveryType(
    deliveryType: 'HOME_DELIVERY' | 'SELF_PICKUP',
    deliveryAddress: DeliveryAddress | null,
    paymentMethod: string,
    notes?: string
  ): Observable<OrderResponse> {
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

    // Calculate delivery fee based on delivery type
    const deliveryFee = deliveryType === 'SELF_PICKUP' ? 0 : 50;
    const discount = cart.discount || 0;

    const orderRequest: OrderRequest = {
      customerId: customerId,
      shopId: cart.shopId!,
      deliveryType: deliveryType,
      items: cart.items.map(item => ({
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        quantity: item.quantity,
        unit: item.unit || 'unit'
      })),
      deliveryAddress: deliveryType === 'HOME_DELIVERY' && deliveryAddress ? {
        streetAddress: deliveryAddress.address,
        landmark: deliveryAddress.landmark || '',
        city: deliveryAddress.city,
        state: deliveryAddress.state,
        pincode: deliveryAddress.postalCode
      } : {
        streetAddress: 'SELF_PICKUP',
        city: 'N/A',
        state: 'N/A',
        pincode: '000000'
      },
      paymentMethod: paymentMethod,
      subtotal: cart.subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      total: cart.total,
      notes: notes || '',
      customerInfo: deliveryAddress ? {
        customerId: customerId,
        firstName: deliveryAddress.contactName.split(' ')[0] || '',
        lastName: deliveryAddress.contactName.split(' ').slice(1).join(' ') || '',
        phone: deliveryAddress.phone,
        email: ''
      } : undefined
    };

    console.log('Placing order with delivery type:', deliveryType);
    console.log('Order request:', orderRequest);

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
          // Don't show SweetAlert or navigate here - let the component handle it
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
}