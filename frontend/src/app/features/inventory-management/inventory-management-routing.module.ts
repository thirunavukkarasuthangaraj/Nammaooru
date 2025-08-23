import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from '../../core/guards/auth.guard';
import { RoleGuard } from '../../core/guards/role.guard';
import { UserRole } from '../../core/models/auth.model';

import { InventoryDashboardComponent } from './components/inventory-dashboard/inventory-dashboard.component';
import { ProductCatalogComponent } from './components/product-catalog/product-catalog.component';
import { StockManagementComponent } from './components/stock-management/stock-management.component';
import { InventoryAlertsComponent } from './components/inventory-alerts/inventory-alerts.component';
import { BulkUploadComponent } from './components/bulk-upload/bulk-upload.component';
import { InventoryReportsComponent } from './components/inventory-reports/inventory-reports.component';
import { CategoryManagementComponent } from './components/category-management/category-management.component';

const routes: Routes = [
  {
    path: '',
    component: InventoryDashboardComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SHOP_OWNER] }
  },
  {
    path: 'products',
    component: ProductCatalogComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SHOP_OWNER] }
  },
  {
    path: 'stock',
    component: StockManagementComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SHOP_OWNER] }
  },
  {
    path: 'alerts',
    component: InventoryAlertsComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SHOP_OWNER] }
  },
  {
    path: 'bulk-upload',
    component: BulkUploadComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SHOP_OWNER] }
  },
  {
    path: 'reports',
    component: InventoryReportsComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SHOP_OWNER] }
  },
  {
    path: 'categories',
    component: CategoryManagementComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SHOP_OWNER] }
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class InventoryManagementRoutingModule { }