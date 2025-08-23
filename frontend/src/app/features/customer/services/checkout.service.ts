import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, switchMap, tap } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';
import { CartService } from './cart.service';
import { Router } from '@angular/router';
import Swal from 'sweetalert2';

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
  items: OrderItem[];
  deliveryAddress: DeliveryAddress;
  paymentMethod: string;
  paymentStatus?: string;
  notes?: string;
  subtotal: number;
  taxAmount: number;
  deliveryFee: number;
  discountAmount: number;
  totalAmount: number;
}

export interface OrderItem {
  shopProductId: number;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
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
  private apiUrl = `${environment.apiUrl}/orders`;

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

    const customerId = this.getCustomerId();
    if (!customerId) {
      Swal.fire('Error', 'Please login to place an order', 'error');
      this.router.navigate(['/auth/login']);
      return of(null as any);
    }

    const orderRequest: OrderRequest = {
      customerId: customerId,
      shopId: cart.shopId!,
      items: cart.items.map(item => ({
        shopProductId: item.productId,
        quantity: item.quantity,
        unitPrice: item.price,
        totalPrice: item.price * item.quantity,
        specialInstructions: ''
      })),
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod === 'CASH_ON_DELIVERY' ? 'PENDING' : 'PROCESSING',
      notes: notes || '',
      subtotal: cart.subtotal,
      taxAmount: cart.subtotal * 0.05, // 5% tax
      deliveryFee: cart.deliveryFee,
      discountAmount: cart.discount,
      totalAmount: cart.total
    };

    return this.http.post<OrderResponse>(`${this.apiUrl}/place`, orderRequest).pipe(
      tap(response => {
        if (response && response.id) {
          // Clear cart after successful order
          this.cartService.clearCart();
          
          // Show success message
          Swal.fire({
            title: 'Order Placed Successfully!',
            text: `Your order #${response.orderNumber} has been placed.`,
            icon: 'success',
            confirmButtonText: 'Track Order'
          }).then((result) => {
            if (result.isConfirmed) {
              this.router.navigate(['/customer/orders', response.id]);
            }
          });
        }
      }),
      catchError(error => {
        console.error('Error placing order:', error);
        Swal.fire('Error', 'Failed to place order. Please try again.', 'error');
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

    return this.http.get<DeliveryAddress[]>(`${environment.apiUrl}/customers/${customerId}/addresses`).pipe(
      catchError(() => of([]))
    );
  }

  saveAddress(address: DeliveryAddress): Observable<DeliveryAddress> {
    const customerId = this.getCustomerId();
    if (!customerId) {
      return of(null as any);
    }

    return this.http.post<DeliveryAddress>(`${environment.apiUrl}/customers/${customerId}/addresses`, address).pipe(
      catchError(() => of(address))
    );
  }

  processPayment(orderId: number, paymentMethod: string): Observable<any> {
    const paymentData = {
      orderId: orderId,
      paymentMethod: paymentMethod,
      amount: this.cartService.getTotalAmount()
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
    const user = localStorage.getItem('currentUser');
    if (user) {
      try {
        const userData = JSON.parse(user);
        return userData.customerId || userData.id || null;
      } catch {
        return null;
      }
    }
    return null;
  }

  calculateDeliveryTime(shopId: number): Observable<string> {
    return this.http.get<{estimatedTime: string}>(`${environment.apiUrl}/shops/${shopId}/delivery-time`).pipe(
      switchMap(response => of(response.estimatedTime)),
      catchError(() => of('30-45 minutes'))
    );
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