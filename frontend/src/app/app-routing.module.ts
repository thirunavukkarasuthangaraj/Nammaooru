import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from './core/guards/auth.guard';
import { RoleGuard } from './core/guards/role.guard';
import { UserRole } from './core/models/auth.model';
import { UnauthorizedComponent } from './shared/components/unauthorized/unauthorized.component';
import { MainLayoutComponent } from './layout/main-layout/main-layout.component';
import { RoleTestComponent } from './shared/components/role-test/role-test.component';
import { PrivacyPolicyComponent } from './shared/components/privacy-policy/privacy-policy.component';
import { TermsConditionsComponent } from './shared/components/terms-conditions/terms-conditions.component';

const routes: Routes = [
  {
    path: '',
    redirectTo: '/shop-owner',
    pathMatch: 'full'
  },
  {
    path: 'auth',
    loadChildren: () => import('./features/auth/auth.module').then(m => m.AuthModule)
  },
  {
    path: 'privacy-policy',
    component: PrivacyPolicyComponent
  },
  {
    path: 'terms-conditions',
    component: TermsConditionsComponent
  },
  {
    path: 'role-test',
    component: RoleTestComponent
  },
  {
    path: 'test-delivery',
    loadChildren: () => import('./features/delivery/delivery.module').then(m => m.DeliveryModule)
  },
  {
    path: '',
    component: MainLayoutComponent,
    canActivate: [AuthGuard],
    children: [
      {
        path: 'dashboard',
        loadChildren: () => import('./features/dashboard/dashboard.module').then(m => m.DashboardModule)
      },
      {
        path: 'customer',
        loadChildren: () => import('./features/customer/customer.module').then(m => m.CustomerModule)
      },
      {
        path: 'orders',
        loadChildren: () => import('./features/orders/orders.module').then(m => m.OrdersModule)
      },
      {
        path: 'users',
        loadChildren: () => import('./features/users/users.module').then(m => m.UsersModule),
        canActivate: [RoleGuard],
        data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN] }
      },
      {
        path: 'analytics',
        loadChildren: () => import('./features/analytics/analytics.module').then(m => m.AnalyticsModule),
        canActivate: [RoleGuard],
        data: { roles: [UserRole.SUPER_ADMIN] }
      },
      {
        path: 'settings',
        loadChildren: () => import('./features/settings/settings.module').then(m => m.SettingsModule),
        canActivate: [RoleGuard],
        data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN] }
      },
      {
        path: 'notifications',
        loadChildren: () => import('./features/notifications/notifications.module').then(m => m.NotificationsModule)
      },
      {
        path: 'shops',
        loadChildren: () => import('./features/shop/shop.module').then(m => m.ShopModule)
      },
      {
        path: 'products',
        loadChildren: () => import('./features/product/product.module').then(m => m.ProductModule)
      },
      {
        path: 'admin',
        loadChildren: () => import('./features/admin/admin.module').then(m => m.AdminModule),
        canActivate: [RoleGuard],
        data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN] }
      },
      {
        path: 'shop-owner',
        loadChildren: () => import('./features/shop-owner/shop-owner.module').then(m => m.ShopOwnerModule),
        canActivate: [RoleGuard],
        data: { roles: [UserRole.SUPER_ADMIN, UserRole.SHOP_OWNER, UserRole.ADMIN] }
      },
      {
        path: 'delivery',
        loadChildren: () => import('./features/delivery/delivery.module').then(m => m.DeliveryModule)
      },
      {
        path: 'financial',
        loadChildren: () => import('./features/financial-management/financial-management.module').then(m => m.FinancialManagementModule),
        canActivate: [RoleGuard],
        data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN] }
      },
      {
        path: 'inventory',
        loadChildren: () => import('./features/inventory-management/inventory-management.module').then(m => m.InventoryManagementModule),
        canActivate: [RoleGuard],
        data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SHOP_OWNER] }
      }
    ]
  },
  {
    path: 'unauthorized',
    component: UnauthorizedComponent
  },
  {
    path: '**',
    redirectTo: '/dashboard'
  }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }