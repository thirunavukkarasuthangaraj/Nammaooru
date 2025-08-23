import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of, forkJoin } from 'rxjs';
import { catchError, switchMap } from 'rxjs/operators';
import { FirebaseService } from './firebase.service';
import { EmailService } from './email.service';
import { environment } from '../../../environments/environment';

export interface NotificationEvent {
  type: 'ORDER_PLACED' | 'ORDER_ACCEPTED' | 'ORDER_REJECTED' | 'ORDER_READY' | 
        'ORDER_PICKED_UP' | 'ORDER_DELIVERED' | 'DAILY_SUMMARY';
  orderId?: number;
  orderNumber?: string;
  recipients: {
    customer?: { email: string; phone?: string; name?: string };
    shopOwner?: { email: string; phone?: string; name?: string };
    deliveryPartner?: { email: string; phone?: string; name?: string };
  };
  data: any;
}

@Injectable({
  providedIn: 'root'
})
export class NotificationOrchestratorService {
  private apiUrl = `${environment.apiUrl}/notifications`;

  constructor(
    private firebaseService: FirebaseService,
    private emailService: EmailService,
    private http: HttpClient
  ) {
    // Schedule daily summary at 10 PM every day
    this.scheduleDailySummary();
  }

  // Main notification handler
  handleNotification(event: NotificationEvent): Observable<any> {
    switch (event.type) {
      case 'ORDER_PLACED':
        return this.handleOrderPlaced(event);
      case 'ORDER_ACCEPTED':
        return this.handleOrderAccepted(event);
      case 'ORDER_REJECTED':
        return this.handleOrderRejected(event);
      case 'ORDER_READY':
        return this.handleOrderReady(event);
      case 'ORDER_PICKED_UP':
        return this.handleOrderPickedUp(event);
      case 'ORDER_DELIVERED':
        return this.handleOrderDelivered(event);
      case 'DAILY_SUMMARY':
        return this.handleDailySummary(event);
      default:
        return of(null);
    }
  }

  // Handle order placed notification
  private handleOrderPlaced(event: NotificationEvent): Observable<any> {
    const notifications = [];
    
    // Generate OTPs
    const customerOTP = this.generateOTP();
    const shopOTP = this.generateOTP();
    
    // Store OTPs in backend
    this.storeOTPs(event.orderId!, shopOTP, customerOTP).subscribe();
    
    // 1. Send Firebase notification to customer
    this.firebaseService.sendOrderNotification(
      event.orderNumber!,
      'CONFIRMED',
      'Your order has been placed successfully!'
    );
    
    // 2. Send confirmation email with delivery OTP to customer
    if (event.recipients.customer?.email) {
      notifications.push(
        this.emailService.sendOrderConfirmationEmail(
          event.orderNumber!,
          event.recipients.customer.email,
          event.recipients.customer.name || 'Customer',
          customerOTP
        )
      );
    }
    
    // 3. Send Firebase notification to shop owner
    this.firebaseService.sendAdminNotification(
      'New Order Received!',
      `Order #${event.orderNumber} from ${event.recipients.customer?.name}`
    );
    
    // 4. Send email to shop owner
    if (event.recipients.shopOwner?.email) {
      notifications.push(
        this.emailService.sendOrderStatusEmail(
          event.recipients.shopOwner.email,
          event.orderNumber!,
          'ACCEPTED',
          'New order received. Please accept or reject.',
          shopOTP
        )
      );
    }
    
    return forkJoin(notifications).pipe(
      catchError(() => of(null))
    );
  }

  // Handle order accepted by shop
  private handleOrderAccepted(event: NotificationEvent): Observable<any> {
    const notifications = [];
    
    // 1. Firebase notification to customer
    this.firebaseService.sendOrderNotification(
      event.orderNumber!,
      'CONFIRMED',
      `Your order has been accepted! Estimated time: ${event.data.estimatedTime}`
    );
    
    // 2. Email to customer with shop OTP
    if (event.recipients.customer?.email) {
      notifications.push(
        this.emailService.sendOrderStatusEmail(
          event.recipients.customer.email,
          event.orderNumber!,
          'ACCEPTED',
          `Your order has been accepted and will be ready in ${event.data.estimatedTime}`,
          event.data.shopOTP
        )
      );
    }
    
    // 3. Notify delivery partners
    if (event.data.assignedPartner) {
      this.firebaseService.sendDeliveryNotification(
        event.data.assignedPartner.phone,
        'New Delivery Assignment',
        `Order #${event.orderNumber} is ready for pickup`
      );
    }
    
    return forkJoin(notifications).pipe(
      catchError(() => of(null))
    );
  }

  // Handle order rejected by shop
  private handleOrderRejected(event: NotificationEvent): Observable<any> {
    const notifications = [];
    
    // 1. Firebase notification to customer
    this.firebaseService.sendOrderNotification(
      event.orderNumber!,
      'REJECTED',
      `Your order has been rejected. Reason: ${event.data.reason}`
    );
    
    // 2. Email to customer
    if (event.recipients.customer?.email) {
      notifications.push(
        this.emailService.sendOrderStatusEmail(
          event.recipients.customer.email,
          event.orderNumber!,
          'REJECTED',
          `We're sorry, your order has been rejected. Reason: ${event.data.reason}`
        )
      );
    }
    
    return forkJoin(notifications).pipe(
      catchError(() => of(null))
    );
  }

  // Handle order ready for pickup
  private handleOrderReady(event: NotificationEvent): Observable<any> {
    // Firebase notification to delivery partner
    if (event.data.assignedPartner) {
      this.firebaseService.sendDeliveryNotification(
        event.data.assignedPartner.phone,
        'Order Ready for Pickup',
        `Order #${event.orderNumber} is ready. Pickup OTP: ${event.data.shopOTP}`
      );
    }
    
    // Firebase notification to customer
    this.firebaseService.sendOrderNotification(
      event.orderNumber!,
      'READY_FOR_PICKUP',
      'Your order is ready and will be picked up soon!'
    );
    
    return of(null);
  }

  // Handle order picked up by delivery partner
  private handleOrderPickedUp(event: NotificationEvent): Observable<any> {
    const notifications = [];
    
    // 1. Firebase notification to customer
    this.firebaseService.sendOrderNotification(
      event.orderNumber!,
      'OUT_FOR_DELIVERY',
      `Your order is on the way! Delivery OTP: ${event.data.customerOTP}`
    );
    
    // 2. Email to customer with delivery OTP
    if (event.recipients.customer?.email) {
      notifications.push(
        this.emailService.sendDeliveryNotificationEmail(
          event.orderNumber!,
          event.recipients.customer.email,
          `${environment.apiUrl}/track/${event.orderNumber}`,
          event.data.customerOTP
        )
      );
    }
    
    return forkJoin(notifications).pipe(
      catchError(() => of(null))
    );
  }

  // Handle order delivered
  private handleOrderDelivered(event: NotificationEvent): Observable<any> {
    const notifications = [];
    
    // 1. Firebase notification to customer
    this.firebaseService.sendOrderNotification(
      event.orderNumber!,
      'DELIVERED',
      'Your order has been delivered successfully! Thank you for ordering.'
    );
    
    // 2. Send invoice email to customer
    if (event.recipients.customer?.email && event.data.invoice) {
      notifications.push(
        this.emailService.sendInvoiceEmail(event.data.invoice)
      );
    }
    
    // 3. Update shop owner about completion
    this.firebaseService.sendAdminNotification(
      'Order Delivered',
      `Order #${event.orderNumber} has been delivered successfully`
    );
    
    return forkJoin(notifications).pipe(
      catchError(() => of(null))
    );
  }

  // Handle daily summary for shop owners
  private handleDailySummary(event: NotificationEvent): Observable<any> {
    if (!event.recipients.shopOwner?.email) {
      return of(null);
    }
    
    // Send daily summary email
    return this.emailService.sendDailySummary(event.data);
  }

  // Schedule daily summary emails
  private scheduleDailySummary(): void {
    // Check every hour if it's time to send daily summary (10 PM)
    setInterval(() => {
      const now = new Date();
      if (now.getHours() === 22 && now.getMinutes() === 0) {
        this.sendAllDailySummaries();
      }
    }, 60000); // Check every minute
  }

  // Send daily summaries to all shop owners
  private sendAllDailySummaries(): void {
    this.http.get<any[]>(`${this.apiUrl}/daily-summaries`).pipe(
      switchMap(summaries => {
        const notifications = summaries.map(summary => 
          this.handleDailySummary({
            type: 'DAILY_SUMMARY',
            recipients: {
              shopOwner: { 
                email: summary.shopOwnerEmail,
                name: summary.shopName 
              }
            },
            data: summary
          })
        );
        return forkJoin(notifications);
      }),
      catchError(error => {
        console.error('Error sending daily summaries:', error);
        return of(null);
      })
    ).subscribe();
  }

  // Generate random 6-digit OTP
  private generateOTP(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  // Store OTPs in backend
  private storeOTPs(orderId: number, shopOTP: string, customerOTP: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/store-otps`, {
      orderId,
      shopOTP,
      customerOTP
    }).pipe(
      catchError(error => {
        console.error('Error storing OTPs:', error);
        return of(null);
      })
    );
  }

  // Get profit calculation for shop
  calculateDailyProfit(shopId: number, date: string): Observable<any> {
    return this.http.get(`${environment.apiUrl}/shops/${shopId}/profit`, {
      params: { date }
    }).pipe(
      catchError(() => {
        // Return mock profit data
        return of({
          totalRevenue: 15000,
          totalCost: 10000,
          totalProfit: 5000,
          profitMargin: 33.3,
          breakdown: {
            foodCost: 7000,
            deliveryFees: 1500,
            platformFees: 1500
          }
        });
      })
    );
  }

  // Send test notifications
  sendTestNotification(type: 'firebase' | 'email', recipient: string): Observable<any> {
    if (type === 'firebase') {
      this.firebaseService.testNotification();
      return of({ success: true });
    } else {
      return this.emailService.sendOTP(recipient, 'VERIFY_EMAIL');
    }
  }
}