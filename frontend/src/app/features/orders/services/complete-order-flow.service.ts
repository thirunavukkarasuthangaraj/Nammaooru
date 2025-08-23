import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of, throwError } from 'rxjs';
import { catchError, switchMap, map } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';

// Import all required services
import { CustomerOrderService } from '../../customer/services/customer-order.service';
import { ShopOwnerOrderService } from '../../shop-owner/services/shop-owner-order.service';
import { DeliveryPartnerService } from '../../delivery/services/delivery-partner.service';
import { InvoiceService } from './invoice.service';
import { FirebaseService } from '../../../core/services/firebase.service';

export interface CompleteOrderFlow {
  orderId: number;
  orderNumber: string;
  customerId: number;
  shopId: number;
  deliveryPartnerId?: number;
  assignmentId?: number;
  invoiceId?: number;
  status: OrderFlowStatus;
  timeline: OrderTimeline[];
}

export interface OrderFlowStatus {
  currentStep: string;
  nextStep: string;
  canProceed: boolean;
  blockedReason?: string;
}

export interface OrderTimeline {
  step: string;
  status: 'PENDING' | 'IN_PROGRESS' | 'COMPLETED' | 'FAILED';
  timestamp?: string;
  actor?: string;
  notes?: string;
}

@Injectable({
  providedIn: 'root'
})
export class CompleteOrderFlowService {
  private apiUrl = `${environment.apiUrl}`;

  constructor(
    private http: HttpClient,
    private customerOrderService: CustomerOrderService,
    private shopOwnerOrderService: ShopOwnerOrderService,
    private deliveryPartnerService: DeliveryPartnerService,
    private invoiceService: InvoiceService,
    private firebaseService: FirebaseService
  ) {}

  /**
   * COMPLETE ORDER FLOW - Step by Step
   */

  // STEP 1: Customer places order
  placeCustomerOrder(orderData: any): Observable<CompleteOrderFlow> {
    return this.customerOrderService.createOrder(orderData).pipe(
      switchMap(order => {
        const flow: CompleteOrderFlow = {
          orderId: order.id,
          orderNumber: order.orderNumber,
          customerId: order.customerId,
          shopId: order.shopId,
          status: {
            currentStep: 'ORDER_PLACED',
            nextStep: 'WAITING_SHOP_ACCEPTANCE',
            canProceed: true
          },
          timeline: [{
            step: 'ORDER_PLACED',
            status: 'COMPLETED',
            timestamp: new Date().toISOString(),
            actor: `Customer #${order.customerId}`,
            notes: 'Order placed successfully'
          }]
        };
        
        // Send notification to shop owner
        this.firebaseService.sendOrderNotification(
          order.orderNumber,
          'NEW_ORDER',
          'You have a new order!'
        );
        
        return of(flow);
      })
    );
  }

  // STEP 2: Shop owner accepts order
  shopAcceptOrder(orderId: number, estimatedTime: string): Observable<CompleteOrderFlow> {
    return this.shopOwnerOrderService.acceptOrder(orderId, estimatedTime).pipe(
      switchMap(order => {
        const flow: CompleteOrderFlow = {
          orderId: order.id,
          orderNumber: order.orderNumber,
          customerId: order.customerId,
          shopId: order.shopId,
          status: {
            currentStep: 'SHOP_ACCEPTED',
            nextStep: 'ASSIGNING_DELIVERY_PARTNER',
            canProceed: true
          },
          timeline: [
            {
              step: 'ORDER_PLACED',
              status: 'COMPLETED',
              timestamp: new Date(Date.now() - 10 * 60000).toISOString()
            },
            {
              step: 'SHOP_ACCEPTED',
              status: 'COMPLETED',
              timestamp: new Date().toISOString(),
              actor: `Shop #${order.shopId}`,
              notes: `Accepted with ${estimatedTime} preparation time`
            }
          ]
        };
        
        // Auto-assign delivery partner
        return this.autoAssignDeliveryPartner(orderId, order.shopId);
      })
    );
  }

  // STEP 3: Auto-assign delivery partner
  private autoAssignDeliveryPartner(orderId: number, shopId: number): Observable<CompleteOrderFlow> {
    // Get shop location (mock for now)
    const shopLocation = { lat: 13.0827, lng: 80.2707 };
    
    return this.deliveryPartnerService.getAvailablePartners(shopLocation).pipe(
      switchMap(partners => {
        if (partners.length === 0) {
          return throwError('No delivery partners available');
        }
        
        // Select best partner (first available for now)
        const selectedPartner = partners[0];
        
        // Assign the partner
        return this.deliveryPartnerService.assignDeliveryPartner(
          orderId,
          selectedPartner.id,
          30 // 30 minutes estimated
        );
      }),
      map(assignment => {
        const flow: CompleteOrderFlow = {
          orderId: orderId,
          orderNumber: `ORD-${orderId}`,
          customerId: 1,
          shopId: shopId,
          deliveryPartnerId: assignment.partnerId,
          assignmentId: assignment.id,
          status: {
            currentStep: 'DELIVERY_ASSIGNED',
            nextStep: 'WAITING_DELIVERY_ACCEPTANCE',
            canProceed: true
          },
          timeline: [
            { step: 'ORDER_PLACED', status: 'COMPLETED' },
            { step: 'SHOP_ACCEPTED', status: 'COMPLETED' },
            {
              step: 'DELIVERY_ASSIGNED',
              status: 'COMPLETED',
              timestamp: new Date().toISOString(),
              actor: `Partner #${assignment.partnerId}`,
              notes: 'Delivery partner assigned'
            }
          ]
        };
        return flow;
      })
    );
  }

  // STEP 4: Delivery partner accepts
  deliveryPartnerAccept(assignmentId: number): Observable<CompleteOrderFlow> {
    return this.deliveryPartnerService.acceptAssignment(assignmentId).pipe(
      map(assignment => {
        const flow: CompleteOrderFlow = {
          orderId: assignment.orderId,
          orderNumber: `ORD-${assignment.orderId}`,
          customerId: 1,
          shopId: 1,
          deliveryPartnerId: assignment.partnerId,
          assignmentId: assignment.id,
          status: {
            currentStep: 'DELIVERY_ACCEPTED',
            nextStep: 'PREPARING_ORDER',
            canProceed: true
          },
          timeline: [
            { step: 'ORDER_PLACED', status: 'COMPLETED' },
            { step: 'SHOP_ACCEPTED', status: 'COMPLETED' },
            { step: 'DELIVERY_ASSIGNED', status: 'COMPLETED' },
            {
              step: 'DELIVERY_ACCEPTED',
              status: 'COMPLETED',
              timestamp: new Date().toISOString(),
              actor: `Partner #${assignment.partnerId}`,
              notes: 'Delivery partner accepted'
            }
          ]
        };
        return flow;
      })
    );
  }

  // STEP 5: Shop prepares order
  shopStartPreparing(orderId: number): Observable<CompleteOrderFlow> {
    return this.shopOwnerOrderService.startPreparing(orderId).pipe(
      map(order => {
        const flow: CompleteOrderFlow = {
          orderId: order.id,
          orderNumber: order.orderNumber,
          customerId: order.customerId,
          shopId: order.shopId,
          status: {
            currentStep: 'PREPARING',
            nextStep: 'READY_FOR_PICKUP',
            canProceed: true
          },
          timeline: [
            { step: 'ORDER_PLACED', status: 'COMPLETED' },
            { step: 'SHOP_ACCEPTED', status: 'COMPLETED' },
            { step: 'DELIVERY_ASSIGNED', status: 'COMPLETED' },
            { step: 'DELIVERY_ACCEPTED', status: 'COMPLETED' },
            {
              step: 'PREPARING',
              status: 'IN_PROGRESS',
              timestamp: new Date().toISOString(),
              actor: `Shop #${order.shopId}`,
              notes: 'Order preparation started'
            }
          ]
        };
        return flow;
      })
    );
  }

  // STEP 6: Shop marks order ready
  shopMarkReady(orderId: number): Observable<CompleteOrderFlow> {
    return this.shopOwnerOrderService.markReady(orderId).pipe(
      map(order => {
        const flow: CompleteOrderFlow = {
          orderId: order.id,
          orderNumber: order.orderNumber,
          customerId: order.customerId,
          shopId: order.shopId,
          status: {
            currentStep: 'READY_FOR_PICKUP',
            nextStep: 'WAITING_PICKUP',
            canProceed: true
          },
          timeline: [
            { step: 'ORDER_PLACED', status: 'COMPLETED' },
            { step: 'SHOP_ACCEPTED', status: 'COMPLETED' },
            { step: 'DELIVERY_ASSIGNED', status: 'COMPLETED' },
            { step: 'DELIVERY_ACCEPTED', status: 'COMPLETED' },
            { step: 'PREPARING', status: 'COMPLETED' },
            {
              step: 'READY_FOR_PICKUP',
              status: 'COMPLETED',
              timestamp: new Date().toISOString(),
              actor: `Shop #${order.shopId}`,
              notes: 'Order ready for pickup'
            }
          ]
        };
        
        // Notify delivery partner
        this.firebaseService.sendOrderNotification(
          order.orderNumber,
          'READY_FOR_PICKUP',
          'Order is ready for pickup!'
        );
        
        return flow;
      })
    );
  }

  // STEP 7: Delivery partner picks up order
  deliveryPartnerPickup(assignmentId: number, shopOTP: string): Observable<CompleteOrderFlow> {
    return this.deliveryPartnerService.markPickedUp(assignmentId, shopOTP).pipe(
      map(assignment => {
        const flow: CompleteOrderFlow = {
          orderId: assignment.orderId,
          orderNumber: `ORD-${assignment.orderId}`,
          customerId: 1,
          shopId: 1,
          deliveryPartnerId: assignment.partnerId,
          assignmentId: assignment.id,
          status: {
            currentStep: 'OUT_FOR_DELIVERY',
            nextStep: 'DELIVERING',
            canProceed: true
          },
          timeline: [
            { step: 'ORDER_PLACED', status: 'COMPLETED' },
            { step: 'SHOP_ACCEPTED', status: 'COMPLETED' },
            { step: 'DELIVERY_ASSIGNED', status: 'COMPLETED' },
            { step: 'DELIVERY_ACCEPTED', status: 'COMPLETED' },
            { step: 'PREPARING', status: 'COMPLETED' },
            { step: 'READY_FOR_PICKUP', status: 'COMPLETED' },
            {
              step: 'PICKED_UP',
              status: 'COMPLETED',
              timestamp: new Date().toISOString(),
              actor: `Partner #${assignment.partnerId}`,
              notes: 'Order picked up from shop'
            }
          ]
        };
        
        // Notify customer
        this.firebaseService.sendOrderNotification(
          `ORD-${assignment.orderId}`,
          'OUT_FOR_DELIVERY',
          'Your order is out for delivery!'
        );
        
        return flow;
      })
    );
  }

  // STEP 8: Delivery partner delivers order
  deliveryPartnerDeliver(assignmentId: number, customerOTP: string, proofImage?: File): Observable<CompleteOrderFlow> {
    return this.deliveryPartnerService.completeDelivery(assignmentId, customerOTP, proofImage).pipe(
      switchMap(assignment => {
        const flow: CompleteOrderFlow = {
          orderId: assignment.orderId,
          orderNumber: `ORD-${assignment.orderId}`,
          customerId: 1,
          shopId: 1,
          deliveryPartnerId: assignment.partnerId,
          assignmentId: assignment.id,
          status: {
            currentStep: 'DELIVERED',
            nextStep: 'GENERATING_INVOICE',
            canProceed: true
          },
          timeline: [
            { step: 'ORDER_PLACED', status: 'COMPLETED' },
            { step: 'SHOP_ACCEPTED', status: 'COMPLETED' },
            { step: 'DELIVERY_ASSIGNED', status: 'COMPLETED' },
            { step: 'DELIVERY_ACCEPTED', status: 'COMPLETED' },
            { step: 'PREPARING', status: 'COMPLETED' },
            { step: 'READY_FOR_PICKUP', status: 'COMPLETED' },
            { step: 'PICKED_UP', status: 'COMPLETED' },
            {
              step: 'DELIVERED',
              status: 'COMPLETED',
              timestamp: new Date().toISOString(),
              actor: `Partner #${assignment.partnerId}`,
              notes: 'Order delivered successfully'
            }
          ]
        };
        
        // Auto-generate invoice
        return this.generateAndSendInvoice(assignment.orderId, flow);
      })
    );
  }

  // STEP 9: Generate and send invoice
  private generateAndSendInvoice(orderId: number, flow: CompleteOrderFlow): Observable<CompleteOrderFlow> {
    return this.invoiceService.processOrderInvoice(orderId).pipe(
      map(success => {
        if (success) {
          flow.status = {
            currentStep: 'COMPLETED',
            nextStep: 'NONE',
            canProceed: false
          };
          flow.timeline.push({
            step: 'INVOICE_SENT',
            status: 'COMPLETED',
            timestamp: new Date().toISOString(),
            notes: 'Invoice generated and sent to customer'
          });
        }
        return flow;
      })
    );
  }

  // Get complete order flow status
  getOrderFlowStatus(orderId: number): Observable<CompleteOrderFlow> {
    return this.http.get<{data: CompleteOrderFlow}>(`${this.apiUrl}/orders/${orderId}/flow-status`)
      .pipe(
        switchMap(response => of(response.data)),
        catchError(() => {
          // Mock flow status
          const mockFlow: CompleteOrderFlow = {
            orderId: orderId,
            orderNumber: `ORD-${orderId}`,
            customerId: 1,
            shopId: 1,
            deliveryPartnerId: 1,
            assignmentId: 1,
            invoiceId: 1,
            status: {
              currentStep: 'OUT_FOR_DELIVERY',
              nextStep: 'DELIVERING',
              canProceed: true
            },
            timeline: [
              { step: 'ORDER_PLACED', status: 'COMPLETED', timestamp: new Date(Date.now() - 60 * 60000).toISOString() },
              { step: 'SHOP_ACCEPTED', status: 'COMPLETED', timestamp: new Date(Date.now() - 55 * 60000).toISOString() },
              { step: 'DELIVERY_ASSIGNED', status: 'COMPLETED', timestamp: new Date(Date.now() - 50 * 60000).toISOString() },
              { step: 'DELIVERY_ACCEPTED', status: 'COMPLETED', timestamp: new Date(Date.now() - 45 * 60000).toISOString() },
              { step: 'PREPARING', status: 'COMPLETED', timestamp: new Date(Date.now() - 40 * 60000).toISOString() },
              { step: 'READY_FOR_PICKUP', status: 'COMPLETED', timestamp: new Date(Date.now() - 20 * 60000).toISOString() },
              { step: 'PICKED_UP', status: 'COMPLETED', timestamp: new Date(Date.now() - 10 * 60000).toISOString() },
              { step: 'OUT_FOR_DELIVERY', status: 'IN_PROGRESS', timestamp: new Date().toISOString() }
            ]
          };
          return of(mockFlow);
        })
      );
  }
}