import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from '../../core/guards/auth.guard';
import { RoleGuard } from '../../core/guards/role.guard';
import { DeliveryPartnerDashboardComponent } from './components/delivery-partner-dashboard/delivery-partner-dashboard.component';
import { PartnerRegistrationComponent } from './components/partner-registration/partner-registration.component';
import { AdminPartnersComponent } from './components/admin-partners/admin-partners.component';
import { OrderTrackingComponent } from './components/order-tracking/order-tracking.component';
import { PartnerOrdersComponent } from './components/partner-orders/partner-orders.component';
import { DeliveryAnalyticsComponent } from './components/delivery-analytics/delivery-analytics.component';

const routes: Routes = [
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
    path: 'admin/assignments',
    component: AdminPartnersComponent, // Temporary - will show assignments tab
    canActivate: [AuthGuard, RoleGuard],
    data: { 
      expectedRoles: ['SUPER_ADMIN', 'ADMIN', 'MANAGER'],
      title: 'Order Assignments'
    }
  },
  {
    path: 'admin/tracking',
    component: OrderTrackingComponent, // Live tracking view for admins
    canActivate: [AuthGuard, RoleGuard],
    data: { 
      expectedRoles: ['SUPER_ADMIN', 'ADMIN', 'MANAGER'],
      title: 'Live Tracking Dashboard'
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