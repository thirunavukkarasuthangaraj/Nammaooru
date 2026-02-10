import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from '../../core/guards/auth.guard';
import { RoleGuard } from '../../core/guards/role.guard';
import { DeliveryDashboardComponent } from './components/delivery-dashboard/delivery-dashboard.component';
import { DeliveryPartnerDashboardComponent } from './components/delivery-partner-dashboard/delivery-partner-dashboard.component';
import { PartnerRegistrationComponent } from './components/partner-registration/partner-registration.component';
import { AdminPartnersComponent } from './components/admin-partners/admin-partners.component';
import { OrderTrackingComponent } from './components/order-tracking/order-tracking.component';
import { AdminTrackingComponent } from './components/admin-tracking/admin-tracking.component';
import { PartnerOrdersComponent } from './components/partner-orders/partner-orders.component';
import { DeliveryAnalyticsComponent } from './components/delivery-analytics/delivery-analytics.component';
import { SimpleDocumentViewerComponent } from './components/simple-document-viewer/simple-document-viewer.component';
import { OrderAssignmentsComponent } from './components/order-assignments/order-assignments.component';
import { PartnerPaymentsComponent } from './components/partner-payments/partner-payments.component';
import { AvailableOrdersComponent } from './components/available-orders/available-orders.component';
import { EarningsOverviewComponent } from './components/earnings-overview/earnings-overview.component';
import { DeliveryPartnerDocumentsComponent } from './components/delivery-partner-documents/delivery-partner-documents.component';
import { PartnerPlaceholderComponent } from './components/partner-placeholder/partner-placeholder.component';
import { UserRole } from '../../core/models/auth.model';

const routes: Routes = [
  {
    path: 'dashboard',
    component: DeliveryDashboardComponent,
    canActivate: [AuthGuard],
    title: 'Delivery Dashboard'
  },
  {
    path: 'partner/register',
    component: PartnerRegistrationComponent,
    title: 'Delivery Partner Registration'
  },
  {
    path: 'partner/dashboard',
    component: DeliveryPartnerDashboardComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: {
      roles: [UserRole.SUPER_ADMIN, UserRole.DELIVERY_PARTNER],
      title: 'Delivery Partner Dashboard'
    }
  },
  {
    path: 'partner/orders',
    component: PartnerOrdersComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: {
      roles: [UserRole.SUPER_ADMIN, UserRole.DELIVERY_PARTNER],
      title: 'My Orders'
    }
  },
  {
    path: 'partner/available',
    component: AvailableOrdersComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: {
      roles: [UserRole.SUPER_ADMIN, UserRole.DELIVERY_PARTNER],
      title: 'Available Orders'
    }
  },
  {
    path: 'partner/deliveries',
    component: PartnerOrdersComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: {
      roles: [UserRole.SUPER_ADMIN, UserRole.DELIVERY_PARTNER],
      title: 'My Deliveries'
    }
  },
  {
    path: 'partner/earnings',
    component: EarningsOverviewComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: {
      roles: [UserRole.SUPER_ADMIN, UserRole.DELIVERY_PARTNER],
      title: 'Earnings'
    }
  },
  {
    path: 'partner/performance',
    component: PartnerPlaceholderComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: {
      roles: [UserRole.SUPER_ADMIN, UserRole.DELIVERY_PARTNER],
      title: 'Performance'
    }
  },
  {
    path: 'partner/profile',
    component: PartnerPlaceholderComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: {
      roles: [UserRole.SUPER_ADMIN, UserRole.DELIVERY_PARTNER],
      title: 'Profile'
    }
  },
  {
    path: 'partner/documents',
    component: DeliveryPartnerDocumentsComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: {
      roles: [UserRole.SUPER_ADMIN, UserRole.DELIVERY_PARTNER],
      title: 'Documents'
    }
  },
  {
    path: 'partner/vehicle',
    component: PartnerPlaceholderComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: {
      roles: [UserRole.SUPER_ADMIN, UserRole.DELIVERY_PARTNER],
      title: 'Vehicle Info'
    }
  },
  {
    path: 'partner/help',
    component: PartnerPlaceholderComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: {
      roles: [UserRole.SUPER_ADMIN, UserRole.DELIVERY_PARTNER],
      title: 'Help Center'
    }
  },
  {
    path: 'partner/emergency',
    component: PartnerPlaceholderComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: {
      roles: [UserRole.SUPER_ADMIN, UserRole.DELIVERY_PARTNER],
      title: 'Emergency'
    }
  },
  {
    path: 'admin/partners',
    component: AdminPartnersComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: {
      roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN],
      title: 'Manage Partners'
    }
  },
  {
    path: 'tracking/:assignmentId',
    component: OrderTrackingComponent,
    title: 'Order Tracking'
  },
  {
    path: 'analytics',
    component: DeliveryAnalyticsComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: {
      roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN],
      title: 'Delivery Analytics'
    }
  },
  {
    path: 'documents/view/:id/:name',
    component: SimpleDocumentViewerComponent,
    canActivate: [AuthGuard],
    title: 'View Documents'
  },
  {
    path: 'admin/assignments',
    component: OrderAssignmentsComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: {
      roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN],
      title: 'Order Assignments'
    }
  },
  {
    path: 'admin/tracking',
    component: AdminTrackingComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: {
      roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN],
      title: 'Live Tracking Dashboard'
    }
  },
  {
    path: 'partner-payments',
    component: PartnerPaymentsComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: {
      roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN],
      title: 'Partner Payments'
    }
  },
  {
    path: '',
    redirectTo: 'admin/partners',
    pathMatch: 'full'
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class DeliveryRoutingModule { }
