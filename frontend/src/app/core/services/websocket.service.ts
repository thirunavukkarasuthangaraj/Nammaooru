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

/**
 * App-wide shared STOMP/SockJS connection.
 *
 * Design notes:
 * - connect() is idempotent: the first caller activates the client, later
 *   callers just get the connection-status stream. Components must NOT call
 *   disconnect() on destroy — the connection is shared for the app lifetime.
 * - Topic subscriptions are tracked per destination and automatically
 *   re-established after every reconnect (stompjs does not do this itself),
 *   so a network blip no longer silently kills real-time updates.
 * - connectionStatus$ emits true on every (re)connect; components can use it
 *   to refresh data and catch up on events missed while offline.
 */
@Injectable({
  providedIn: 'root'
})
export class WebSocketService {
  private stompClient: Client | null = null;
  private connectionStatus$ = new BehaviorSubject<boolean>(false);
  private stompSubscriptions: Map<string, StompSubscription> = new Map();
  private topicSubjects: Map<string, Subject<any>> = new Map();
  private topicRefCounts: Map<string, number> = new Map();

  private reconnectInterval = 5000; // 5 seconds

  constructor() {}

  /**
   * Connect to WebSocket server using STOMP over SockJS.
   * Idempotent — safe to call from multiple components.
   * Returns the connection-status stream (emits on connect/disconnect/reconnect).
   */
  connect(token?: string): Observable<boolean> {
    if (!this.stompClient) {
      // Strip only a TRAILING "/api" - a plain .replace('/api','') matches the
      // first "/api" anywhere in the string, which is inside "https://api."
      // for this domain and corrupts the host (e.g. "https://.nammaoorudelivary.in").
      const wsUrl = `${environment.apiUrl.replace(/\/api$/, '')}/ws`;
      console.log('📡 Connecting to WebSocket via SockJS:', wsUrl);

      this.stompClient = new Client({
        webSocketFactory: () => new SockJS(wsUrl),
        reconnectDelay: this.reconnectInterval,
        heartbeatIncoming: 4000,
        heartbeatOutgoing: 4000,
        onConnect: () => {
          console.log('✅ WebSocket Connected via STOMP');
          // Old STOMP subscriptions died with the previous socket —
          // re-establish every tracked topic on this fresh connection.
          this.stompSubscriptions.clear();
          this.topicSubjects.forEach((_, destination) => this.stompSubscribe(destination));
          this.connectionStatus$.next(true);
        },
        onStompError: (frame) => {
          console.error('❌ STOMP error:', frame.headers['message']);
          console.error('Details:', frame.body);
          this.connectionStatus$.next(false);
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

      this.stompClient.activate();
    }

    return this.connectionStatus$.asObservable();
  }

  /**
   * Subscribe to a specific topic. Survives reconnects; if called before the
   * connection is up, delivery starts as soon as it connects.
   */
  subscribe(destination: string): Observable<any> {
    return new Observable(observer => {
      let subject = this.topicSubjects.get(destination);
      if (!subject) {
        subject = new Subject<any>();
        this.topicSubjects.set(destination, subject);
      }
      this.topicRefCounts.set(destination, (this.topicRefCounts.get(destination) || 0) + 1);
      this.stompSubscribe(destination);

      const sub = subject.subscribe(observer);

      return () => {
        sub.unsubscribe();
        const remaining = (this.topicRefCounts.get(destination) || 1) - 1;
        if (remaining <= 0) {
          console.log('Unsubscribing from:', destination);
          this.topicRefCounts.delete(destination);
          this.topicSubjects.delete(destination);
          const stompSub = this.stompSubscriptions.get(destination);
          this.stompSubscriptions.delete(destination);
          if (stompSub && this.stompClient?.connected) {
            try { stompSub.unsubscribe(); } catch { /* socket already gone */ }
          }
        } else {
          this.topicRefCounts.set(destination, remaining);
        }
      };
    });
  }

  /** Create the STOMP-level subscription if connected and not already subscribed. */
  private stompSubscribe(destination: string): void {
    if (!this.stompClient?.connected || this.stompSubscriptions.has(destination)) {
      return;
    }
    const subject = this.topicSubjects.get(destination);
    if (!subject) return;

    console.log('📬 Subscribing to:', destination);
    const subscription = this.stompClient.subscribe(destination, (message: IMessage) => {
      try {
        subject.next(JSON.parse(message.body));
      } catch (error) {
        console.error('Error parsing message:', error);
        subject.next(message.body);
      }
    });
    this.stompSubscriptions.set(destination, subscription);
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
   * Tear down the shared connection. App-level use only (e.g. logout) —
   * component ngOnDestroy must NOT call this, other screens share the socket.
   */
  disconnect(): void {
    if (this.stompClient) {
      this.stompSubscriptions.forEach((sub, dest) => {
        console.log('Unsubscribing from:', dest);
        try { sub.unsubscribe(); } catch { /* socket already gone */ }
      });
      this.stompSubscriptions.clear();

      this.stompClient.deactivate();
      this.stompClient = null;
    }
    this.connectionStatus$.next(false);
    this.topicSubjects.clear();
    this.topicRefCounts.clear();
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
