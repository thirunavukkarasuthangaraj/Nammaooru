import { Injectable } from '@angular/core';
import { Observable, BehaviorSubject, Subject } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface WebSocketMessage {
  type: string;
  payload: any;
  timestamp: Date;
}

@Injectable({
  providedIn: 'root'
})
export class WebSocketService {
  private ws: WebSocket | null = null;
  private connectionStatus$ = new BehaviorSubject<boolean>(false);
  private messageSubjects: Map<string, Subject<any>> = new Map();
  
  private reconnectInterval = 5000; // 5 seconds
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 10;

  constructor() {}

  /**
   * Connect to WebSocket server
   */
  connect(token?: string): Observable<boolean> {
    const serverUrl = `${environment.apiUrl}/ws`.replace('http', 'ws');
    
    return new Observable(observer => {
      try {
        this.ws = new WebSocket(serverUrl);
        
        this.ws.onopen = (event) => {
          console.log('WebSocket Connected');
          this.connectionStatus$.next(true);
          this.reconnectAttempts = 0;
          
          // Send authentication if token provided
          if (token) {
            this.send('/auth', { token });
          }
          
          observer.next(true);
          observer.complete();
        };

        this.ws.onmessage = (event) => {
          try {
            const message = JSON.parse(event.data);
            this.handleMessage(message);
          } catch (error) {
            console.error('Error parsing WebSocket message:', error);
          }
        };

        this.ws.onerror = (error) => {
          console.error('WebSocket error:', error);
          this.connectionStatus$.next(false);
          observer.error(error);
        };

        this.ws.onclose = (event) => {
          console.log('WebSocket connection closed');
          this.connectionStatus$.next(false);
          this.handleReconnect(token);
        };

      } catch (error) {
        observer.error(error);
      }
    });
  }

  /**
   * Subscribe to a specific topic
   */
  subscribe(destination: string): Observable<any> {
    if (!this.messageSubjects.has(destination)) {
      this.messageSubjects.set(destination, new Subject<any>());
    }
    
    // Send subscription message
    this.send('/subscribe', { destination });
    
    return this.messageSubjects.get(destination)!.asObservable();
  }

  /**
   * Send message to WebSocket
   */
  private send(destination: string, data: any): void {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      const message = {
        destination,
        data,
        timestamp: new Date()
      };
      this.ws.send(JSON.stringify(message));
    }
  }

  /**
   * Handle incoming messages
   */
  private handleMessage(message: any): void {
    const { destination, data } = message;
    
    if (this.messageSubjects.has(destination)) {
      this.messageSubjects.get(destination)!.next(data);
    }
  }

  /**
   * Handle reconnection
   */
  private handleReconnect(token?: string): void {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      console.log(`Attempting to reconnect (${this.reconnectAttempts}/${this.maxReconnectAttempts})`);
      
      setTimeout(() => {
        this.connect(token).subscribe({
          next: () => console.log('Reconnected successfully'),
          error: (error) => console.error('Reconnection failed:', error)
        });
      }, this.reconnectInterval);
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
    if (this.ws) {
      this.ws.close();
      this.ws = null;
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
}