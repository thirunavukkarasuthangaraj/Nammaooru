import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, switchMap, tap } from 'rxjs/operators';
import { environment } from '../../../environments/environment';
import Swal from 'sweetalert2';

export interface EmailInvoiceRequest {
  orderNumber: string;
  customerEmail: string;
  customerName: string;
  shopName: string;
  items: InvoiceItem[];
  subtotal: number;
  deliveryFee: number;
  discount: number;
  total: number;
  deliveryAddress: string;
  orderDate: string;
  deliveryDate?: string;
}

export interface InvoiceItem {
  productName: string;
  quantity: number;
  price: number;
  unit: string;
  total: number;
}

export interface OTPRequest {
  email: string;
  purpose: 'LOGIN' | 'SIGNUP' | 'RESET_PASSWORD' | 'VERIFY_EMAIL' | 'ORDER_PICKUP' | 'ORDER_DELIVERY';
  orderId?: number;
}

export interface DailySummaryData {
  shopId: number;
  shopName: string;
  shopOwnerEmail: string;
  date: string;
  totalOrders: number;
  completedOrders: number;
  cancelledOrders: number;
  pendingOrders: number;
  totalRevenue: number;
  totalCost: number;
  totalProfit: number;
  profitMargin: number;
  topSellingItems: Array<{
    name: string;
    quantity: number;
    revenue: number;
  }>;
  orderDetails: Array<{
    orderNumber: string;
    customerName: string;
    items: string;
    total: number;
    status: string;
    time: string;
  }>;
  averageOrderValue: number;
  peakHours: string;
}

@Injectable({
  providedIn: 'root'
})
export class EmailService {
  private apiUrl = `${environment.apiUrl}/email`;

  constructor(private http: HttpClient) {}

  // Send OTP for authentication
  sendOTP(email: string, purpose: OTPRequest['purpose'], orderId?: number): Observable<{success: boolean, message: string}> {
    const request: OTPRequest = { email, purpose, orderId };
    
    return this.http.post<{success: boolean, message: string}>(`${this.apiUrl}/send-otp`, request).pipe(
      tap(response => {
        if (response.success) {
          let message = 'A 6-digit OTP has been sent to your email';
          if (purpose === 'ORDER_PICKUP') {
            message = 'Pickup OTP has been sent to shop owner';
          } else if (purpose === 'ORDER_DELIVERY') {
            message = 'Delivery OTP has been sent to customer';
          }
          Swal.fire({
            title: 'OTP Sent!',
            text: message,
            icon: 'success',
            timer: 3000
          });
        }
      }),
      catchError(error => {
        console.error('Error sending OTP:', error);
        return of({ success: false, message: 'Failed to send OTP' });
      })
    );
  }

  // Verify OTP
  verifyOTP(email: string, otp: string, purpose: string): Observable<{valid: boolean, token?: string}> {
    return this.http.post<{valid: boolean, token?: string}>(`${this.apiUrl}/verify-otp`, { email, otp, purpose }).pipe(
      catchError(error => {
        console.error('Error verifying OTP:', error);
        return of({ valid: false });
      })
    );
  }

  // Send invoice email with enhanced details
  sendInvoiceEmail(invoiceRequest: EmailInvoiceRequest): Observable<boolean> {
    const formData = new FormData();
    formData.append('orderNumber', invoiceRequest.orderNumber);
    formData.append('customerEmail', invoiceRequest.customerEmail);
    formData.append('invoiceHtml', this.generateInvoiceHtml(invoiceRequest));
    
    return this.http.post<{success: boolean}>(`${this.apiUrl}/send-invoice`, formData).pipe(
      switchMap(response => of(response.success)),
      tap(success => {
        if (success) {
          console.log(`Invoice email sent to ${invoiceRequest.customerEmail}`);
        }
      }),
      catchError(error => {
        console.error('Error sending invoice:', error);
        return of(false);
      })
    );
  }

  // Send order confirmation with OTP
  sendOrderConfirmationEmail(orderNumber: string, customerEmail: string, customerName: string, deliveryOTP?: string): Observable<boolean> {
    const emailData = {
      to: customerEmail,
      subject: `Order Confirmed - #${orderNumber}`,
      template: 'order-confirmation',
      data: {
        orderNumber,
        customerName,
        deliveryOTP,
        message: deliveryOTP ? `Your delivery OTP is: ${deliveryOTP}. Please share this with delivery partner upon delivery.` : ''
      }
    };
    
    return this.http.post<{success: boolean}>(`${this.apiUrl}/send`, emailData).pipe(
      switchMap(response => of(response.success)),
      catchError(() => of(false))
    );
  }

  // Send daily summary to shop owner
  sendDailySummary(summaryData: DailySummaryData): Observable<boolean> {
    const emailHtml = this.generateDailySummaryHtml(summaryData);
    
    const emailData = {
      to: summaryData.shopOwnerEmail,
      subject: `Daily Summary - ${summaryData.shopName} - ${summaryData.date}`,
      html: emailHtml,
      template: 'daily-summary'
    };
    
    return this.http.post<{success: boolean}>(`${this.apiUrl}/send`, emailData).pipe(
      tap(response => {
        if (response.success) {
          console.log(`Daily summary sent to ${summaryData.shopOwnerEmail}`);
        }
      }),
      switchMap(response => of(response.success)),
      catchError(error => {
        console.error('Error sending daily summary:', error);
        return of(false);
      })
    );
  }

  // Send notification when order is accepted/rejected
  sendOrderStatusEmail(customerEmail: string, orderNumber: string, status: 'ACCEPTED' | 'REJECTED', message: string, shopOTP?: string): Observable<boolean> {
    const emailData = {
      to: customerEmail,
      subject: `Order ${orderNumber} - ${status === 'ACCEPTED' ? 'Accepted' : 'Rejected'}`,
      template: 'order-status',
      data: {
        orderNumber,
        status,
        message,
        shopOTP: status === 'ACCEPTED' ? shopOTP : undefined,
        otpMessage: shopOTP ? `Shop Pickup OTP: ${shopOTP}` : ''
      }
    };
    
    return this.http.post<{success: boolean}>(`${this.apiUrl}/send`, emailData).pipe(
      switchMap(response => of(response.success)),
      catchError(() => of(false))
    );
  }

  // Send delivery notification with OTP
  sendDeliveryNotificationEmail(orderNumber: string, customerEmail: string, trackingUrl: string, deliveryOTP: string): Observable<boolean> {
    const emailData = {
      to: customerEmail,
      subject: `Your order ${orderNumber} is out for delivery!`,
      template: 'delivery-notification',
      data: {
        orderNumber,
        trackingUrl,
        deliveryOTP,
        message: `Your delivery OTP is: ${deliveryOTP}. Please share this with the delivery partner upon delivery.`
      }
    };
    
    return this.http.post<{success: boolean}>(`${this.apiUrl}/send`, emailData).pipe(
      switchMap(response => of(response.success)),
      catchError(() => of(false))
    );
  }

  generateInvoiceHtml(invoiceRequest: EmailInvoiceRequest): string {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
          .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
          .header { background: #2563eb; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; }
          .order-info { background: #f8fafc; padding: 15px; border-radius: 6px; margin-bottom: 20px; }
          .items-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
          .items-table th, .items-table td { padding: 10px; border-bottom: 1px solid #e5e7eb; text-align: left; }
          .items-table th { background: #f9fafb; font-weight: 600; }
          .total-section { background: #f0f9f0; padding: 15px; border-radius: 6px; }
          .total-row { display: flex; justify-content: space-between; margin-bottom: 5px; }
          .total-final { font-weight: bold; font-size: 18px; color: #059669; border-top: 2px solid #059669; padding-top: 10px; margin-top: 10px; }
          .footer { background: #f8fafc; padding: 20px; text-align: center; color: #6b7280; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>NammaOoru Delivery</h1>
            <h2>Order Invoice</h2>
          </div>
          <div class="content">
            <div class="order-info">
              <h3>Order Details</h3>
              <p><strong>Order Number:</strong> ${invoiceRequest.orderNumber}</p>
              <p><strong>Customer:</strong> ${invoiceRequest.customerName}</p>
              <p><strong>Shop:</strong> ${invoiceRequest.shopName}</p>
              <p><strong>Order Date:</strong> ${new Date(invoiceRequest.orderDate).toLocaleDateString('en-IN')}</p>
              ${invoiceRequest.deliveryDate ? `<p><strong>Delivery Date:</strong> ${new Date(invoiceRequest.deliveryDate).toLocaleDateString('en-IN')}</p>` : ''}
              <p><strong>Delivery Address:</strong> ${invoiceRequest.deliveryAddress}</p>
            </div>
            
            <h3>Items Ordered</h3>
            <table class="items-table">
              <thead>
                <tr>
                  <th>Item</th>
                  <th>Qty</th>
                  <th>Price</th>
                  <th>Total</th>
                </tr>
              </thead>
              <tbody>
                ${invoiceRequest.items.map(item => `
                  <tr>
                    <td>${item.productName}</td>
                    <td>${item.quantity} ${item.unit}</td>
                    <td>₹${item.price}</td>
                    <td>₹${item.total}</td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
            
            <div class="total-section">
              <div class="total-row">
                <span>Subtotal:</span>
                <span>₹${invoiceRequest.subtotal}</span>
              </div>
              ${invoiceRequest.discount > 0 ? `
                <div class="total-row">
                  <span style="color: #059669;">Discount:</span>
                  <span style="color: #059669;">-₹${invoiceRequest.discount}</span>
                </div>
              ` : ''}
              <div class="total-row">
                <span>Delivery Fee:</span>
                <span>₹${invoiceRequest.deliveryFee}</span>
              </div>
              <div class="total-row total-final">
                <span>Total Amount:</span>
                <span>₹${invoiceRequest.total}</span>
              </div>
            </div>
            
            <p style="margin-top: 20px; color: #6b7280; font-style: italic;">
              Thank you for ordering with NammaOoru! We hope you enjoyed your meal.
            </p>
          </div>
          <div class="footer">
            <p>NammaOoru Multi-Service Delivery Platform</p>
            <p>Contact: +91 98765 43210 | Email: support@nammaooru.com</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  // Generate daily summary HTML for shop owners
  generateDailySummaryHtml(data: DailySummaryData): string {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
          .container { max-width: 800px; margin: 0 auto; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }
          .content { padding: 30px; }
          .stats-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; margin-bottom: 30px; }
          .stat-card { background: #f8fafc; padding: 20px; border-radius: 8px; border-left: 4px solid #667eea; }
          .stat-value { font-size: 32px; font-weight: bold; color: #1a202c; }
          .stat-label { color: #718096; margin-top: 5px; }
          .profit-section { background: #f0fdf4; padding: 20px; border-radius: 8px; border-left: 4px solid #10b981; margin-bottom: 30px; }
          .profit-value { font-size: 36px; font-weight: bold; color: #10b981; }
          .table { width: 100%; border-collapse: collapse; margin-top: 20px; }
          .table th, .table td { padding: 12px; text-align: left; border-bottom: 1px solid #e5e7eb; }
          .table th { background: #f9fafb; font-weight: 600; color: #4b5563; }
          .top-items { background: #fef3c7; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
          .footer { background: #f8fafc; padding: 20px; text-align: center; color: #6b7280; border-top: 1px solid #e5e7eb; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Daily Business Summary</h1>
            <h2>${data.shopName}</h2>
            <p style="margin: 0; opacity: 0.9;">${data.date}</p>
          </div>
          
          <div class="content">
            <div class="stats-grid">
              <div class="stat-card">
                <div class="stat-value">${data.totalOrders}</div>
                <div class="stat-label">Total Orders</div>
              </div>
              <div class="stat-card">
                <div class="stat-value">₹${data.totalRevenue.toLocaleString()}</div>
                <div class="stat-label">Total Revenue</div>
              </div>
              <div class="stat-card">
                <div class="stat-value">${data.completedOrders}</div>
                <div class="stat-label">Completed Orders</div>
              </div>
              <div class="stat-card">
                <div class="stat-value">₹${data.averageOrderValue.toFixed(0)}</div>
                <div class="stat-label">Average Order Value</div>
              </div>
            </div>
            
            <div class="profit-section">
              <h3 style="margin-top: 0;">Today's Profit</h3>
              <div class="profit-value">₹${data.totalProfit.toLocaleString()}</div>
              <p style="color: #6b7280; margin: 10px 0;">Profit Margin: ${data.profitMargin.toFixed(1)}%</p>
              <p style="color: #6b7280; margin: 0;">Total Cost: ₹${data.totalCost.toLocaleString()}</p>
            </div>
            
            <div class="top-items">
              <h3 style="margin-top: 0;">Top Selling Items</h3>
              <table class="table">
                <thead>
                  <tr>
                    <th>Item</th>
                    <th>Quantity Sold</th>
                    <th>Revenue</th>
                  </tr>
                </thead>
                <tbody>
                  ${data.topSellingItems.slice(0, 5).map(item => `
                    <tr>
                      <td>${item.name}</td>
                      <td>${item.quantity}</td>
                      <td>₹${item.revenue}</td>
                    </tr>
                  `).join('')}
                </tbody>
              </table>
            </div>
            
            <div>
              <h3>Order Details</h3>
              <table class="table">
                <thead>
                  <tr>
                    <th>Order #</th>
                    <th>Customer</th>
                    <th>Items</th>
                    <th>Total</th>
                    <th>Status</th>
                    <th>Time</th>
                  </tr>
                </thead>
                <tbody>
                  ${data.orderDetails.map(order => `
                    <tr>
                      <td>${order.orderNumber}</td>
                      <td>${order.customerName}</td>
                      <td>${order.items}</td>
                      <td>₹${order.total}</td>
                      <td>${order.status}</td>
                      <td>${order.time}</td>
                    </tr>
                  `).join('')}
                </tbody>
              </table>
            </div>
            
            <div style="margin-top: 30px; padding: 20px; background: #eff6ff; border-radius: 8px;">
              <h4 style="margin-top: 0;">Business Insights</h4>
              <p>• Peak hours: ${data.peakHours}</p>
              <p>• Pending orders: ${data.pendingOrders}</p>
              <p>• Cancelled orders: ${data.cancelledOrders}</p>
            </div>
          </div>
          
          <div class="footer">
            <p style="margin: 0;">This is an automated daily summary from NammaOoru</p>
            <p style="margin: 10px 0 0 0;">For support: support@nammaooru.com | +91 98765 43210</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }
}