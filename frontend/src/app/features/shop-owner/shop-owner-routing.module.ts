import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { ShopOwnerDashboardComponent } from './components/shop-owner-dashboard/shop-owner-dashboard.component';
import { ShopProfileComponent } from './components/shop-profile/shop-profile.component';
import { ShopOverviewComponent } from './components/shop-overview/shop-overview.component';
import { MyProductsComponent } from './components/my-products/my-products.component';
import { InventoryManagementComponent } from './components/inventory-management/inventory-management.component';
import { OrderManagementComponent } from './components/order-management/order-management.component';
import { AddProductComponent } from './components/add-product/add-product.component';
import { BulkUploadComponent } from './components/bulk-upload/bulk-upload.component';
import { CategoriesComponent } from './components/categories/categories.component';
import { CustomerManagementComponent } from './components/customer-management/customer-management.component';
import { ShopSettingsComponent } from './components/shop-settings/shop-settings.component';
import { NotificationsComponent } from './components/notifications/notifications.component';

const routes: Routes = [
  {
    path: '',
    component: ShopOwnerDashboardComponent
  },
  {
    path: 'dashboard',
    component: ShopOwnerDashboardComponent
  },
  {
    path: 'overview',
    component: ShopOverviewComponent
  },
  {
    path: 'products',
    component: MyProductsComponent
  },
  {
    path: 'products/add',
    component: AddProductComponent
  },
  {
    path: 'products/edit/:id',
    component: AddProductComponent
  },
  {
    path: 'products/bulk-upload',
    component: BulkUploadComponent
  },
  {
    path: 'products/categories',
    component: CategoriesComponent
  },
  {
    path: 'inventory',
    component: InventoryManagementComponent
  },
  {
    path: 'orders',
    component: OrderManagementComponent
  },
  {
    path: 'shop/profile',
    component: ShopProfileComponent
  },
  {
    path: 'customers',
    component: CustomerManagementComponent
  },
  {
    path: 'settings',
    component: ShopSettingsComponent
  },
  {
    path: 'notifications',
    component: NotificationsComponent
  },
  // TODO: Implement orders and analytics modules
  // {
  //   path: 'orders',
  //   loadChildren: () => import('../orders/orders.module').then(m => m.OrdersModule)
  // },
  // {
  //   path: 'analytics',
  //   loadChildren: () => import('../analytics/analytics.module').then(m => m.AnalyticsModule)
  // },
  {
    path: 'products',
    loadChildren: () => import('../product/product.module').then(m => m.ProductModule)
  },
  {
    path: 'shop',
    loadChildren: () => import('../shop/shop.module').then(m => m.ShopModule)
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class ShopOwnerRoutingModule { }