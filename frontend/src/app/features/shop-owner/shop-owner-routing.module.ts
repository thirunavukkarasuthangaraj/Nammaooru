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
import { ProductsPricingComponent } from './components/products-pricing/products-pricing.component';
import { BusinessSummaryComponent } from './components/business-summary/business-summary.component';
import { BusinessHoursComponent } from './components/business-hours/business-hours.component';
import { BrowseProductsComponent } from './components/browse-products/browse-products.component';

const routes: Routes = [
  {
    path: '',
    redirectTo: 'dashboard',
    pathMatch: 'full'
  },
  {
    path: 'summary',
    component: BusinessSummaryComponent
  },
  {
    path: 'profile',
    component: ShopProfileComponent
  },
  {
    path: 'products-pricing',
    component: ProductsPricingComponent
  },
  {
    path: 'orders',
    component: OrderManagementComponent
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
    path: 'my-products',
    component: MyProductsComponent
  },
  {
    path: 'my-products/add',
    component: AddProductComponent
  },
  {
    path: 'my-products/edit/:id',
    component: AddProductComponent
  },
  {
    path: 'my-products/bulk-upload',
    component: BulkUploadComponent
  },
  {
    path: 'my-products/categories',
    component: CategoriesComponent
  },
  {
    path: 'browse-products',
    component: BrowseProductsComponent
  },
  {
    path: 'inventory',
    component: InventoryManagementComponent
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
    path: 'business-hours',
    component: BusinessHoursComponent
  },
  {
    path: 'notifications',
    component: NotificationsComponent
  },
  // Analytics route
  {
    path: 'analytics',
    component: BusinessSummaryComponent // Reuse for now
  },
  // Categories route
  {
    path: 'categories',
    component: CategoriesComponent
  },
  // Order routes
  {
    path: 'orders/today',
    component: OrderManagementComponent // Will filter for today
  },
  {
    path: 'orders/history',
    component: OrderManagementComponent // Will show all orders
  },
  // Customer routes
  {
    path: 'reviews',
    component: CustomerManagementComponent // Placeholder
  },
  {
    path: 'loyalty',
    component: CustomerManagementComponent // Placeholder
  },
  // Finance routes
  {
    path: 'revenue',
    component: BusinessSummaryComponent // Shows revenue data
  },
  {
    path: 'payouts',
    component: BusinessSummaryComponent // Placeholder
  },
  {
    path: 'reports',
    component: BusinessSummaryComponent // Placeholder
  },
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