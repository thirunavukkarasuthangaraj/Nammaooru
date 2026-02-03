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
      expectedRoles: ['SUPER_ADMIN', 'DELIVERY_PARTNER'],
      title: 'Delivery Partner Dashboard'
    }
  },
  {
    path: 'partner/orders',
    component: PartnerOrdersComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { 
      expectedRoles: ['SUPER_ADMIN', 'DELIVERY_PARTNER'],
      title: 'My Orders'
    }
  },
  {
    path: 'admin/partners',
    component: AdminPartnersComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { 
      expectedRoles: ['SUPER_ADMIN', 'ADMIN', 'MANAGER'],
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
      expectedRoles: ['SUPER_ADMIN', 'ADMIN', 'MANAGER'],
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
      expectedRoles: ['SUPER_ADMIN', 'ADMIN', 'MANAGER'],
      title: 'Order Assignments'
    }
  },
  {
    path: 'admin/tracking',
    component: AdminTrackingComponent, // Live tracking dashboard for admins
    canActivate: [AuthGuard, RoleGuard],
    data: {
      expectedRoles: ['SUPER_ADMIN', 'ADMIN', 'MANAGER'],
      title: 'Live Tracking Dashboard'
    }
  },
  {
    path: 'partner-payments',
    component: PartnerPaymentsComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: {
      expectedRoles: ['SUPER_ADMIN', 'ADMIN'],
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