import { Injectable } from '@angular/core';
import { AngularFireMessaging } from '@angular/fire/compat/messaging';
import { BehaviorSubject, Observable, of, EMPTY } from 'rxjs';
import { mergeMapTo, catchError } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class FirebaseService {
  currentMessage = new BehaviorSubject<any>(null);
  private isSupported = false;
  private currentToken: string | null = null;

  constructor(private angularFireMessaging: AngularFireMessaging) {
    this.checkSupport();
    if (this.isSupported) {
      this.initializeMessaging();
    }
  }

  private checkSupport(): void {
    this.isSupported = 'serviceWorker' in navigator && 'Notification' in window;
  }

  private initializeMessaging(): void {
    try {
      this.angularFireMessaging.messages.subscribe(
        (payload) => {
          console.log("New Firebase message received: ", payload);
          this.currentMessage.next(payload);
          this.handleForegroundMessage(payload);
        },
        (error) => {
          console.error("Error receiving Firebase message: ", error);
        }
      );
    } catch (error) {
      console.error("Error initializing Firebase messaging: ", error);
    }
  }

  private handleForegroundMessage(payload: any): void {
    if (payload.notification) {
      this.showNotification(
        payload.notification.title || 'New Notification',
        {
          body: payload.notification.body || 'You have a new message',
          icon: payload.notification.icon
        }
      );
    }
  }

  requestPermission(): Observable<string | null> {
    if (!this.isSupported) {
      console.warn('Firebase messaging is not supported in this browser');
      return of(null);
    }

    return this.angularFireMessaging.requestToken.pipe(
      mergeMapTo(of('Permission granted')),
      catchError((error) => {
        console.error('Error requesting notification permission:', error);
        return of(null);
      })
    );
  }

  receiveMessage(): Observable<any> {
    if (!this.isSupported) {
      return EMPTY;
    }
    return this.angularFireMessaging.messages;
  }

  showNotification(title: string, options?: any): void {
    const body = typeof options === 'string' ? options : options?.body || '';
    const icon = typeof options === 'string' ? undefined : options?.icon;
    if (!this.isSupported) {
      console.warn('Notifications not supported');
      return;
    }

    if (Notification.permission === 'granted') {
      const notification = new Notification(title, {
        body: body,
        icon: icon || '/assets/icons/notification.png',
        badge: '/assets/icons/badge.png',
        tag: 'order-notification',
        requireInteraction: false,
        silent: false
      });

      // Auto close after 5 seconds
      setTimeout(() => {
        notification.close();
      }, 5000);

      notification.onclick = () => {
        window.focus();
        notification.close();
      };
    } else if (Notification.permission === 'default') {
      // Request permission first
      Notification.requestPermission().then((permission) => {
        if (permission === 'granted') {
          this.showNotification(title, options);
        }
      });
    }
  }

  getToken(): Observable<string | null> {
    if (!this.isSupported) {
      return of(null);
    }

    return this.angularFireMessaging.requestToken.pipe(
      catchError((error) => {
        console.error('Error getting FCM token:', error);
        return of(null);
      })
    );
  }

  // Method to simulate notification for testing
  testNotification(): void {
    this.showNotification(
      'Test Notification',
      {
        body: 'This is a test notification from NammaOoru!',
        icon: '/assets/icons/notification.png'
      }
    );
  }

  // Method to send order notifications
  sendOrderNotification(orderNumber: string, status: string, message: string): void {
    let title = '';
    let body = '';

    switch (status) {
      case 'CONFIRMED':
        title = 'Order Confirmed! 🎉';
        body = `Your order ${orderNumber} has been confirmed. ${message}`;
        break;
      case 'PREPARING':
        title = 'Order Being Prepared 👨‍🍳';
        body = `Your order ${orderNumber} is being prepared. ${message}`;
        break;
      case 'OUT_FOR_DELIVERY':
        title = 'Order Out for Delivery 🚚';
        body = `Your order ${orderNumber} is on its way! ${message}`;
        break;
      case 'DELIVERED':
        title = 'Order Delivered! ✅';
        body = `Your order ${orderNumber} has been delivered. ${message}`;
        break;
      case 'REJECTED':
        title = 'Order Rejected';
        body = `Your order ${orderNumber} has been rejected. ${message}`;
        break;
      default:
        title = 'Order Update';
        body = `Update for order ${orderNumber}: ${message}`;
    }

    this.showNotification(title, { body });
  }

  sendDeliveryNotification(partnerPhone: string, title: string, body: string): void {
    const notification = {
      title: title,
      body: body,
      icon: '/assets/icons/delivery-icon.png',
      badge: '/assets/icons/badge-icon.png',
      data: {
        type: 'delivery_assignment',
        partnerPhone: partnerPhone,
        timestamp: new Date().toISOString()
      }
    };

    // Send via FCM if token available
    if (this.currentToken) {
      // This would normally send to server to push to specific partner
      console.log('Sending delivery notification:', notification);
    }

    // Show local notification
    this.showNotification(notification.title, {
      body: notification.body,
      icon: notification.icon,
      badge: notification.badge,
      data: notification.data
    });
  }

  sendAdminNotification(title: string, body: string): void {
    this.showNotification(title, { body, icon: '/assets/icons/admin-icon.png' });
  }

  onMessageReceived(): Observable<any> {
    return this.currentMessage.asObservable();
  }
}