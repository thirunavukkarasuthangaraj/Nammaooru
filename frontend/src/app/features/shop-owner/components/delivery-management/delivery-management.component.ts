import { Component, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Subject, takeUntil, interval } from 'rxjs';

@Component({
  selector: 'app-delivery-management',
  templateUrl: './delivery-management.component.html',
  styleUrls: ['./delivery-management.component.scss']
})
export class DeliveryManagementComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  // Tab Management
  selectedTabIndex = 0;

  // Loading States
  isLoading = false;
  loadingMessage = '';

  // Message States
  successMessage = '';
  errorMessage = '';

  // Delivery Stats
  deliveryStats = {
    activeDeliveries: 0,
    onlinePartners: 0,
    avgDeliveryTime: 0,
    completedToday: 0
  };

  // Data Collections
  readyOrders: any[] = [];
  activeDeliveries: any[] = [];
  completedDeliveries: any[] = [];
  deliveryPartners: any[] = [];
  availablePartners: any[] = [];

  constructor(
    private router: Router,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadDeliveryData();
    this.setupAutoRefresh();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  // ===== DATA LOADING =====

  async loadDeliveryData(): Promise<void> {
    this.isLoading = true;
    this.loadingMessage = 'Loading delivery data...';

    try {
      await Promise.all([
        this.loadDeliveryStats(),
        this.loadReadyOrders(),
        this.loadActiveDeliveries(),
        this.loadCompletedDeliveries(),
        this.loadDeliveryPartners()
      ]);
    } catch (error) {
      this.showError('Failed to load delivery data');
    } finally {
      this.isLoading = false;
      this.loadingMessage = '';
    }
  }

  private async loadDeliveryStats(): Promise<void> {
    // Mock data - replace with actual API call
    this.deliveryStats = {
      activeDeliveries: 8,
      onlinePartners: 12,
      avgDeliveryTime: 25,
      completedToday: 45
    };
  }

  private async loadReadyOrders(): Promise<void> {
    // Mock data - replace with actual API call
    this.readyOrders = [
      {
        id: 1,
        orderNumber: 'ORD-2025-001',
        customerName: 'Rajesh Kumar',
        customerPhone: '+91 98765 43210',
        deliveryAddress: '123 MG Road, T. Nagar, Chennai - 600017',
        totalAmount: 850,
        paymentMethod: 'COD',
        selectedPartnerId: null,
        createdAt: new Date()
      },
      {
        id: 2,
        orderNumber: 'ORD-2025-002',
        customerName: 'Priya Sharma',
        customerPhone: '+91 87654 32109',
        deliveryAddress: '456 Anna Salai, Nandanam, Chennai - 600035',
        totalAmount: 1250,
        paymentMethod: 'PAID',
        selectedPartnerId: null,
        createdAt: new Date()
      }
    ];
  }

  private async loadActiveDeliveries(): Promise<void> {
    // Mock data - replace with actual API call
    this.activeDeliveries = [
      {
        id: 1,
        orderId: 3,
        orderNumber: 'ORD-2025-003',
        customerName: 'Suresh Babu',
        customerId: 123,
        customerPhone: '+91 76543 21098',
        deliveryAddress: '789 GST Road, Pallikaranai, Chennai - 600100',
        totalAmount: 650,
        paymentMethod: 'COD',
        paymentStatus: 'PENDING',
        status: 'OUT_FOR_DELIVERY',
        assignedDriver: {
          id: 1,
          name: 'Muthu Kumar',
          phone: '+91 99887 76655',
          vehicleType: 'Bike',
          vehicleNumber: 'TN01AB1234',
          rating: 4.5
        },
        pickupTime: new Date(Date.now() - 20 * 60 * 1000), // 20 minutes ago
        estimatedDeliveryTime: new Date(Date.now() + 10 * 60 * 1000), // 10 minutes from now
        driverVerified: true,
        otpCode: ''
      },
      {
        id: 2,
        orderId: 4,
        orderNumber: 'ORD-2025-004',
        customerName: 'Lakshmi Devi',
        customerId: 124,
        customerPhone: '+91 65432 10987',
        deliveryAddress: '321 ECR Road, Sholinganallur, Chennai - 600119',
        totalAmount: 980,
        paymentMethod: 'PAID',
        paymentStatus: 'COMPLETED',
        status: 'ASSIGNED',
        assignedDriver: {
          id: 2,
          name: 'Karthik Raja',
          phone: '+91 88776 65544',
          vehicleType: 'Bike',
          vehicleNumber: 'TN02CD5678',
          rating: 4.2
        },
        assignedAt: new Date(Date.now() - 5 * 60 * 1000), // 5 minutes ago
        driverVerified: false,
        otpCode: ''
      }
    ];
  }

  private async loadCompletedDeliveries(): Promise<void> {
    // Mock data - replace with actual API call
    this.completedDeliveries = [
      {
        id: 1,
        orderId: 5,
        orderNumber: 'ORD-2025-005',
        customerName: 'Venkat Raman',
        totalAmount: 750,
        status: 'DELIVERED',
        assignedDriver: {
          name: 'Arjun Prasad'
        },
        completedAt: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
        deliveryDuration: 35,
        proofOfDelivery: {
          photo: 'assets/images/delivery-proof.jpg',
          signature: true,
          receiverName: 'Venkat Raman'
        }
      },
      {
        id: 2,
        orderId: 6,
        orderNumber: 'ORD-2025-006',
        customerName: 'Meera Nair',
        totalAmount: 450,
        status: 'FAILED',
        assignedDriver: {
          name: 'Raj Mohan'
        },
        failedAt: new Date(Date.now() - 1 * 60 * 60 * 1000), // 1 hour ago
        failureReason: 'Customer not available after multiple attempts'
      }
    ];
  }

  private async loadDeliveryPartners(): Promise<void> {
    // Mock data - replace with actual API call
    this.deliveryPartners = [
      {
        id: 1,
        partnerId: 'DP001',
        fullName: 'Muthu Kumar',
        phone: '+91 99887 76655',
        isOnline: true,
        rating: 4.5,
        vehicleType: 'Bike',
        vehicleNumber: 'TN01AB1234',
        activeOrders: 2,
        avgDeliveryTime: 22,
        totalDeliveries: 458,
        successRate: 96,
        monthlyEarnings: 45000,
        profilePhoto: null
      },
      {
        id: 2,
        partnerId: 'DP002',
        fullName: 'Karthik Raja',
        phone: '+91 88776 65544',
        isOnline: true,
        rating: 4.2,
        vehicleType: 'Bike',
        vehicleNumber: 'TN02CD5678',
        activeOrders: 1,
        avgDeliveryTime: 28,
        totalDeliveries: 312,
        successRate: 94,
        monthlyEarnings: 38000,
        profilePhoto: null
      },
      {
        id: 3,
        partnerId: 'DP003',
        fullName: 'Arjun Prasad',
        phone: '+91 77665 54433',
        isOnline: false,
        rating: 4.7,
        vehicleType: 'Bike',
        vehicleNumber: 'TN03EF9012',
        activeOrders: 0,
        avgDeliveryTime: 20,
        totalDeliveries: 623,
        successRate: 98,
        monthlyEarnings: 52000,
        profilePhoto: null
      }
    ];

    // Filter available partners (online only)
    this.availablePartners = this.deliveryPartners.filter(partner => partner.isOnline);
  }

  // ===== AUTO REFRESH =====

  private setupAutoRefresh(): void {
    // Refresh data every 30 seconds
    interval(30000)
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        if (!this.isLoading) {
          this.loadDeliveryData();
        }
      });
  }

  // ===== ORDER ASSIGNMENT =====

  onPartnerSelect(order: any, event: any): void {
    order.selectedPartnerId = event.value;
  }

  async assignDeliveryPartner(order: any): Promise<void> {
    if (!order.selectedPartnerId) {
      this.showError('Please select a delivery partner');
      return;
    }

    this.isLoading = true;
    this.loadingMessage = 'Assigning delivery partner...';

    try {
      // Mock API call - replace with actual service
      await this.delay(1500);

      const partner = this.availablePartners.find(p => p.id === order.selectedPartnerId);
      if (partner) {
        // Remove from ready orders
        this.readyOrders = this.readyOrders.filter(o => o.id !== order.id);

        // Add to active deliveries
        const newDelivery = {
          id: Date.now(),
          orderId: order.id,
          orderNumber: order.orderNumber,
          customerName: order.customerName,
          customerId: order.customerId,
          customerPhone: order.customerPhone,
          deliveryAddress: order.deliveryAddress,
          totalAmount: order.totalAmount,
          paymentMethod: order.paymentMethod,
          paymentStatus: 'PENDING',
          status: 'ASSIGNED',
          assignedDriver: partner,
          assignedAt: new Date(),
          driverVerified: false,
          otpCode: ''
        };

        this.activeDeliveries.unshift(newDelivery);

        // Update stats
        this.deliveryStats.activeDeliveries++;

        this.showSuccess(`Order assigned to ${partner.fullName}`);
        this.selectedTabIndex = 1; // Switch to Active Deliveries tab
      }
    } catch (error) {
      this.showError('Failed to assign delivery partner');
    } finally {
      this.isLoading = false;
      this.loadingMessage = '';
    }
  }

  // ===== DRIVER VERIFICATION =====

  async verifyDriver(deliveryId: number, otpCode: string): Promise<void> {
    if (!otpCode || otpCode.length < 6) {
      this.showError('Please enter a valid 6-digit OTP');
      return;
    }

    this.isLoading = true;
    this.loadingMessage = 'Verifying driver...';

    try {
      // Mock API call - replace with actual service
      await this.delay(1000);

      // Simulate OTP verification (in real app, this would call the backend)
      const delivery = this.activeDeliveries.find(d => d.id === deliveryId);
      if (delivery) {
        delivery.driverVerified = true;
        delivery.status = 'PICKED_UP';
        delivery.pickupTime = new Date();
        delivery.estimatedDeliveryTime = new Date(Date.now() + 25 * 60 * 1000); // 25 minutes from now

        this.showSuccess('Driver verified successfully. Order released for delivery.');
      }
    } catch (error) {
      this.showError('Invalid OTP. Please try again.');
    } finally {
      this.isLoading = false;
      this.loadingMessage = '';
    }
  }

  // ===== COMMUNICATION ACTIONS =====

  callDriver(phone: string): void {
    if (phone) {
      window.open(`tel:${phone}`, '_self');
    }
  }

  callCustomer(phone: string): void {
    if (phone) {
      window.open(`tel:${phone}`, '_self');
    }
  }

  callPartner(phone: string): void {
    if (phone) {
      window.open(`tel:${phone}`, '_self');
    }
  }

  messageDriver(driverId: number, deliveryId: number): void {
    // Implement messaging functionality
    this.showInfo('Messaging feature will be implemented');
  }

  messageCustomer(customerId: number, deliveryId: number): void {
    // Implement messaging functionality
    this.showInfo('Messaging feature will be implemented');
  }

  messagePartner(partnerId: number): void {
    // Implement messaging functionality
    this.showInfo('Messaging feature will be implemented');
  }

  // ===== TRACKING =====

  trackDriver(driverId: number): void {
    // Implement GPS tracking functionality
    this.showInfo('GPS tracking feature will be implemented');
  }

  // ===== TIMELINE HELPERS =====

  isTimelineStepCompleted(delivery: any, step: string): boolean {
    switch (step) {
      case 'pickup':
        return ['PICKED_UP', 'OUT_FOR_DELIVERY', 'DELIVERED'].includes(delivery.status);
      case 'transit':
        return ['OUT_FOR_DELIVERY', 'DELIVERED'].includes(delivery.status);
      case 'delivered':
        return delivery.status === 'DELIVERED';
      default:
        return false;
    }
  }

  // ===== DELIVERY MANAGEMENT =====

  getDeliveryETA(delivery: any): string {
    if (delivery.estimatedDeliveryTime) {
      const eta = new Date(delivery.estimatedDeliveryTime);
      const now = new Date();
      const diffMinutes = Math.ceil((eta.getTime() - now.getTime()) / (1000 * 60));

      if (diffMinutes > 0) {
        return `ETA: ${diffMinutes} min`;
      } else {
        return 'Overdue';
      }
    }
    return 'Calculating...';
  }

  getDeliveryStatusClass(status: string): string {
    switch (status) {
      case 'ASSIGNED': return 'status-assigned';
      case 'PICKED_UP': return 'status-picked';
      case 'OUT_FOR_DELIVERY': return 'status-transit';
      case 'DELIVERED': return 'status-delivered';
      case 'FAILED': return 'status-failed';
      default: return '';
    }
  }

  // ===== ACTION HANDLERS =====

  async refreshDeliveries(): Promise<void> {
    await this.loadDeliveryData();
    this.showSuccess('Delivery data refreshed');
  }

  viewOrderDetails(orderId: number): void {
    this.router.navigate(['/shop-owner/orders-management', orderId]);
  }

  reportDeliveryIssue(deliveryId: number): void {
    // Implement issue reporting
    this.showInfo('Issue reporting feature will be implemented');
  }

  rescheduleDelivery(deliveryId: number): void {
    // Implement delivery rescheduling
    this.showInfo('Delivery rescheduling feature will be implemented');
  }

  processRefund(deliveryId: number): void {
    // Implement refund processing
    this.showInfo('Refund processing feature will be implemented');
  }

  viewDeliveryReceipt(deliveryId: number): void {
    // Implement receipt viewing
    this.showInfo('Receipt viewing feature will be implemented');
  }

  downloadDeliveryReport(deliveryId: number): void {
    // Implement report download
    this.showInfo('Report download feature will be implemented');
  }

  viewProofPhoto(photoUrl: string): void {
    // Implement photo viewer
    window.open(photoUrl, '_blank');
  }

  viewPartnerDetails(partnerId: number): void {
    // Implement partner details view
    this.showInfo('Partner details feature will be implemented');
  }

  // ===== UTILITY METHODS =====

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  private showSuccess(message: string): void {
    this.successMessage = message;
    this.errorMessage = '';
    setTimeout(() => this.successMessage = '', 5000);
  }

  private showError(message: string): void {
    this.errorMessage = message;
    this.successMessage = '';
    setTimeout(() => this.errorMessage = '', 5000);
  }

  private showInfo(message: string): void {
    this.snackBar.open(message, 'Close', {
      duration: 3000,
      horizontalPosition: 'center',
      verticalPosition: 'top'
    });
  }
}