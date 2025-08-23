import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, switchMap, tap } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';
import { FirebaseService } from '../../../core/services/firebase.service';
import Swal from 'sweetalert2';

export interface ShopOrder {
  id: number;
  orderNumber: string;
  status: string;
  customerId: number;
  customerName: string;
  customerPhone: string;
  customerEmail: string;
  items: ShopOrderItem[];
  totalAmount: number;
  paymentMethod: string;
  paymentStatus: string;
  deliveryAddress: string;
  notes: string;
  estimatedPreparationTime?: string;
  createdAt: string;
  updatedAt: string;
}

export interface ShopOrderItem {
  id: number;
  productId: number;
  productName: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
  specialInstructions?: string;
}

export interface OrderAcceptRequest {
  orderId: number;
  estimatedPreparationTime: string;
  notes?: string;
}

export interface OrderRejectRequest {
  orderId: number;
  reason: string;
  suggestAlternative?: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class ShopOrderService {
  private apiUrl = `${environment.apiUrl}/shop-owner`;

  constructor(
    private http: HttpClient,
    private firebaseService: FirebaseService
  ) {}

  getShopOrders(shopId: number, status?: string): Observable<ShopOrder[]> {
    let params = new HttpParams();
    if (status) {
      params = params.set('status', status);
    }

    return this.http.get<ShopOrder[]>(`${this.apiUrl}/shops/${shopId}/orders`, { params }).pipe(
      catchError(error => {
        console.error('Error loading shop orders:', error);
        return of([]);
      })
    );
  }

  getPendingOrders(shopId: number): Observable<ShopOrder[]> {
    return this.getShopOrders(shopId, 'PENDING');
  }

  getActiveOrders(shopId: number): Observable<ShopOrder[]> {
    return this.http.get<ShopOrder[]>(`${this.apiUrl}/shops/${shopId}/orders/active`).pipe(
      catchError(error => {
        console.error('Error loading active orders:', error);
        return of([]);
      })
    );
  }

  acceptOrder(orderId: number, estimatedTime: string): Observable<ShopOrder> {
    const request: OrderAcceptRequest = {
      orderId: orderId,
      estimatedPreparationTime: estimatedTime
    };

    return this.http.post<ShopOrder>(`${this.apiUrl}/orders/${orderId}/accept`, request).pipe(
      tap(order => {
        // Send notification to customer
        this.firebaseService.sendOrderNotification(
          order.orderNumber,
          'CONFIRMED',
          `Your order has been accepted! Estimated time: ${estimatedTime}`
        );
        
        Swal.fire({
          title: 'Order Accepted!',
          text: `Order #${order.orderNumber} has been accepted.`,
          icon: 'success',
          timer: 3000
        });
      }),
      catchError(error => {
        console.error('Error accepting order:', error);
        Swal.fire('Error', 'Failed to accept order', 'error');
        throw error;
      })
    );
  }

  rejectOrder(orderId: number, reason: string): Observable<any> {
    const request: OrderRejectRequest = {
      orderId: orderId,
      reason: reason,
      suggestAlternative: false
    };

    return this.http.post(`${this.apiUrl}/orders/${orderId}/reject`, request).pipe(
      tap((response: any) => {
        // Send notification to customer
        this.firebaseService.sendOrderNotification(
          response.orderNumber,
          'REJECTED',
          `Your order has been rejected. Reason: ${reason}`
        );
        
        Swal.fire({
          title: 'Order Rejected',
          text: 'The order has been rejected.',
          icon: 'info',
          timer: 3000
        });
      }),
      catchError(error => {
        console.error('Error rejecting order:', error);
        Swal.fire('Error', 'Failed to reject order', 'error');
        throw error;
      })
    );
  }

  updateOrderStatus(orderId: number, status: string): Observable<ShopOrder> {
    return this.http.put<ShopOrder>(`${this.apiUrl}/orders/${orderId}/status`, { status }).pipe(
      tap(order => {
        // Send notification based on status
        let message = '';
        switch(status) {
          case 'PREPARING':
            message = 'Your order is being prepared!';
            break;
          case 'READY_FOR_PICKUP':
            message = 'Your order is ready for pickup!';
            break;
          case 'COMPLETED':
            message = 'Your order has been completed!';
            break;
        }
        
        if (message) {
          this.firebaseService.sendOrderNotification(order.orderNumber, status, message);
        }
        
        Swal.fire({
          title: 'Status Updated',
          text: `Order status updated to ${status}`,
          icon: 'success',
          timer: 2000
        });
      }),
      catchError(error => {
        console.error('Error updating order status:', error);
        Swal.fire('Error', 'Failed to update order status', 'error');
        throw error;
      })
    );
  }

  markAsReady(orderId: number): Observable<ShopOrder> {
    return this.updateOrderStatus(orderId, 'READY_FOR_PICKUP');
  }

  markAsPreparing(orderId: number): Observable<ShopOrder> {
    return this.updateOrderStatus(orderId, 'PREPARING');
  }

  getOrderDetails(orderId: number): Observable<ShopOrder> {
    return this.http.get<ShopOrder>(`${this.apiUrl}/orders/${orderId}`).pipe(
      catchError(error => {
        console.error('Error loading order details:', error);
        Swal.fire('Error', 'Failed to load order details', 'error');
        throw error;
      })
    );
  }

  // Generate and verify shop OTP for delivery pickup
  generateShopOTP(orderId: number): Observable<{otp: string}> {
    return this.http.post<{otp: string}>(`${this.apiUrl}/orders/${orderId}/generate-otp`, {}).pipe(
      tap(response => {
        Swal.fire({
          title: 'Pickup OTP Generated',
          html: `<h2 style="font-size: 2em; color: #4CAF50;">${response.otp}</h2>
                 <p>Share this OTP with delivery partner for order pickup</p>`,
          icon: 'info',
          confirmButtonText: 'OK'
        });
      }),
      catchError(error => {
        console.error('Error generating OTP:', error);
        Swal.fire('Error', 'Failed to generate OTP', 'error');
        throw error;
      })
    );
  }

  verifyShopOTP(orderId: number, otp: string): Observable<boolean> {
    return this.http.post<{verified: boolean}>(`${this.apiUrl}/orders/${orderId}/verify-otp`, { otp }).pipe(
      switchMap(response => of(response.verified)),
      catchError(() => of(false))
    );
  }

  // Bulk order management
  acceptMultipleOrders(orderIds: number[], estimatedTime: string): Observable<any> {
    const requests = orderIds.map(id => ({
      orderId: id,
      estimatedPreparationTime: estimatedTime
    }));

    return this.http.post(`${this.apiUrl}/orders/bulk-accept`, { orders: requests }).pipe(
      tap(() => {
        Swal.fire({
          title: 'Orders Accepted!',
          text: `${orderIds.length} orders have been accepted.`,
          icon: 'success',
          timer: 3000
        });
      }),
      catchError(error => {
        console.error('Error accepting multiple orders:', error);
        Swal.fire('Error', 'Failed to accept orders', 'error');
        throw error;
      })
    );
  }

  // Order analytics
  getTodayOrderStats(shopId: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/shops/${shopId}/orders/stats/today`).pipe(
      catchError(() => {
        // Return mock data on error
        return of({
          totalOrders: 0,
          pendingOrders: 0,
          completedOrders: 0,
          revenue: 0,
          averageOrderValue: 0
        });
      })
    );
  }

  // Search orders
  searchOrders(shopId: number, searchTerm: string): Observable<ShopOrder[]> {
    const params = new HttpParams().set('search', searchTerm);
    
    return this.http.get<ShopOrder[]>(`${this.apiUrl}/shops/${shopId}/orders/search`, { params }).pipe(
      catchError(error => {
        console.error('Error searching orders:', error);
        return of([]);
      })
    );
  }

  // Print order receipt
  printOrderReceipt(orderId: number): void {
    this.getOrderDetails(orderId).subscribe(order => {
      const printContent = this.generateReceiptHTML(order);
      const printWindow = window.open('', '_blank', 'width=400,height=600');
      
      if (printWindow) {
        printWindow.document.write(printContent);
        printWindow.document.close();
        printWindow.print();
      }
    });
  }

  private generateReceiptHTML(order: ShopOrder): string {
    const itemsHTML = order.items.map(item => `
      <tr>
        <td>${item.productName}</td>
        <td>${item.quantity}</td>
        <td>₹${item.unitPrice}</td>
        <td>₹${item.totalPrice}</td>
      </tr>
    `).join('');

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <title>Order Receipt #${order.orderNumber}</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 20px; }
          h1 { text-align: center; }
          .info { margin: 20px 0; }
          table { width: 100%; border-collapse: collapse; }
          th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
          .total { font-weight: bold; font-size: 1.2em; margin-top: 20px; }
        </style>
      </head>
      <body>
        <h1>Order Receipt</h1>
        <div class="info">
          <p><strong>Order #:</strong> ${order.orderNumber}</p>
          <p><strong>Date:</strong> ${new Date(order.createdAt).toLocaleString()}</p>
          <p><strong>Customer:</strong> ${order.customerName}</p>
          <p><strong>Phone:</strong> ${order.customerPhone}</p>
        </div>
        <table>
          <thead>
            <tr>
              <th>Item</th>
              <th>Qty</th>
              <th>Price</th>
              <th>Total</th>
            </tr>
          </thead>
          <tbody>
            ${itemsHTML}
          </tbody>
        </table>
        <div class="total">
          <p>Total Amount: ₹${order.totalAmount}</p>
        </div>
      </body>
      </html>
    `;
  }
}