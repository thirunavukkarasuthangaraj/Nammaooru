import { Injectable } from '@angular/core';
import { Observable, BehaviorSubject, Subject } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Client, IMessage, StompSubscription } from '@stomp/stompjs';
import SockJS from 'sockjs-client';

export interface WebSocketMessage {
  type: string;
  payload: any;
  timestamp: Date;
}

@Injectable({
  providedIn: 'root'
})
export class WebSocketService {
  private stompClient: Client | null = null;
  private connectionStatus$ = new BehaviorSubject<boolean>(false);
  private subscriptions: Map<string, StompSubscription> = new Map();
  private messageSubjects: Map<string, Subject<any>> = new Map();

  private reconnectInterval = 5000; // 5 seconds
  private maxReconnectAttempts = 10;

  constructor() {}

  /**
   * Connect to WebSocket server using STOMP over SockJS
   */
  connect(token?: string): Observable<boolean> {
    return new Observable(observer => {
      try {
        // Build WebSocket URL using SockJS
        const wsUrl = `${environment.apiUrl.replace('/api', '')}/ws`;
        console.log('📡 Connecting to WebSocket via SockJS:', wsUrl);

        // Create STOMP client with SockJS
        this.stompClient = new Client({
          webSocketFactory: () => new SockJS(wsUrl),
          reconnectDelay: this.reconnectInterval,
          heartbeatIncoming: 4000,
          heartbeatOutgoing: 4000,
          debug: (str) => {
            console.log('STOMP:', str);
          },
          onConnect: (frame) => {
            console.log('✅ WebSocket Connected via STOMP');
            this.connectionStatus$.next(true);
            observer.next(true);
            observer.complete();
          },
          onStompError: (frame) => {
            console.error('❌ STOMP error:', frame.headers['message']);
            console.error('Details:', frame.body);
            this.connectionStatus$.next(false);
            observer.error(new Error(frame.headers['message']));
          },
          onDisconnect: () => {
            console.log('WebSocket disconnected');
            this.connectionStatus$.next(false);
          },
          onWebSocketClose: () => {
            console.log('WebSocket connection closed');
            this.connectionStatus$.next(false);
          }
        });

        // Activate the client
        this.stompClient.activate();

      } catch (error) {
        console.error('❌ Error creating WebSocket connection:', error);
        observer.error(error);
      }
    });
  }

  /**
   * Subscribe to a specific topic
   */
  subscribe(destination: string): Observable<any> {
    return new Observable(observer => {
      if (!this.stompClient || !this.stompClient.connected) {
        console.warn('WebSocket not connected, cannot subscribe to:', destination);
        return;
      }

      console.log('📬 Subscribing to:', destination);

      const subscription = this.stompClient.subscribe(destination, (message: IMessage) => {
        try {
          const body = JSON.parse(message.body);
          console.log('📩 Received message on', destination, ':', body);
          observer.next(body);
        } catch (error) {
          console.error('Error parsing message:', error);
          observer.next(message.body);
        }
      });

      this.subscriptions.set(destination, subscription);

      // Return unsubscribe function
      return () => {
        console.log('Unsubscribing from:', destination);
        subscription.unsubscribe();
        this.subscriptions.delete(destination);
      };
    });
  }

  /**
   * Send message to a destination
   */
  send(destination: string, data: any): void {
    if (this.stompClient && this.stompClient.connected) {
      this.stompClient.publish({
        destination: `/app${destination}`,
        body: JSON.stringify(data)
      });
    } else {
      console.warn('WebSocket not connected, cannot send to:', destination);
    }
  }

  /**
   * Get connection status
   */
  isConnected(): Observable<boolean> {
    return this.connectionStatus$.asObservable();
  }

  /**
   * Disconnect from WebSocket
   */
  disconnect(): void {
    if (this.stompClient) {
      // Unsubscribe from all subscriptions
      this.subscriptions.forEach((sub, dest) => {
        console.log('Unsubscribing from:', dest);
        sub.unsubscribe();
      });
      this.subscriptions.clear();

      // Deactivate the client
      this.stompClient.deactivate();
      this.stompClient = null;
    }
    this.connectionStatus$.next(false);
    this.messageSubjects.clear();
  }

  // Delivery-specific subscription methods for compatibility
  subscribeToTracking(assignmentId: number): Observable<any> {
    return this.subscribe(`/topic/tracking/assignment/${assignmentId}`);
  }

  subscribeToDeliveryStatus(assignmentId: number): Observable<any> {
    return this.subscribe(`/topic/delivery/status/${assignmentId}`);
  }

  subscribeToPartnerAssignments(partnerId: number): Observable<any> {
    return this.subscribe(`/queue/partner/${partnerId}/new-assignment`);
  }

  subscribeToPartnerMessages(partnerId: number): Observable<any> {
    return this.subscribe(`/queue/partner/${partnerId}/message`);
  }

  subscribeToCustomerNotifications(customerId: number): Observable<any> {
    return this.subscribe(`/queue/customer/${customerId}/notifications`);
  }

  subscribeToEmergencyAlerts(): Observable<any> {
    return this.subscribe('/topic/delivery/admin/emergency');
  }

  subscribeToAnnouncements(): Observable<any> {
    return this.subscribe('/topic/delivery/announcements');
  }

  subscribeToChatMessages(assignmentId: number): Observable<any> {
    return this.subscribe(`/topic/delivery/chat/${assignmentId}`);
  }

  /**
   * Subscribe to shop order updates for real-time notifications
   * Shop owners use this to receive new order and status update notifications
   */
  subscribeToShopOrders(shopId: number): Observable<any> {
    return this.subscribe(`/topic/shop/${shopId}/orders`);
  }
}
