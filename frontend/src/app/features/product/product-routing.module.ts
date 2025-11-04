import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from '../../core/guards/auth.guard';
import { RoleGuard } from '../../core/guards/role.guard';
import { ProductMasterComponent } from './components/product-master/product-master.component';
import { MasterProductListComponent } from './components/master-product-list/master-product-list.component';
import { MasterProductFormComponent } from './components/master-product-form/master-product-form.component';
import { ShopProductListComponent } from './components/shop-product-list/shop-product-list.component';
import { ShopProductFormComponent } from './components/shop-product-form/shop-product-form.component';
import { CategoryListComponent } from './components/category-list/category-list.component';
import { CategoryFormComponent } from './components/category-form/category-form.component';
import { ProductDashboardComponent } from './components/product-dashboard/product-dashboard.component';
import { BulkProductAssignmentComponent } from './components/bulk-product-assignment/bulk-product-assignment.component';
import { ShopOwnerProductsComponent } from './components/shop-owner-products/shop-owner-products.component';
import { ProductBulkImportComponent } from './components/product-bulk-import/product-bulk-import.component';

const routes: Routes = [
  {
    path: '',
    component: ProductMasterComponent,
    canActivate: [AuthGuard],
    children: [
      {
        path: '',
        redirectTo: 'dashboard',
        pathMatch: 'full'
      },
      {
        path: 'dashboard',
        component: ProductDashboardComponent,
        data: { title: 'Product Dashboard' }
      },
      {
        path: 'master',
        component: MasterProductListComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'Master Products',
          roles: ['SUPER_ADMIN', 'ADMIN', 'MANAGER', 'SHOP_OWNER']
        }
      },
      {
        path: 'master/new',
        component: MasterProductFormComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'New Master Product',
          roles: ['SUPER_ADMIN', 'ADMIN', 'MANAGER']
        }
      },
      {
        path: 'master/:id',
        component: MasterProductFormComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'Edit Master Product',
          roles: ['SUPER_ADMIN', 'ADMIN', 'MANAGER', 'SHOP_OWNER']
        }
      },
      {
        path: 'shop/:shopId',
        component: ShopProductListComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'Shop Products',
          roles: ['SUPER_ADMIN', 'ADMIN', 'MANAGER', 'SHOP_OWNER']
        }
      },
      {
        path: 'shop/:shopId/new',
        component: ShopProductFormComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'Add Product to Shop',
          roles: ['SUPER_ADMIN', 'ADMIN', 'MANAGER', 'SHOP_OWNER']
        }
      },
      {
        path: 'shop/:shopId/:productId',
        component: ShopProductFormComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'Edit Shop Product',
          roles: ['SUPER_ADMIN', 'ADMIN', 'MANAGER', 'SHOP_OWNER']
        }
      },
      {
        path: 'categories',
        component: CategoryListComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'Product Categories',
          roles: ['SUPER_ADMIN', 'ADMIN', 'MANAGER']
        }
      },
      {
        path: 'categories/new',
        component: CategoryFormComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'New Category',
          roles: ['SUPER_ADMIN', 'ADMIN', 'MANAGER']
        }
      },
      {
        path: 'categories/:id',
        component: CategoryFormComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'Edit Category',
          roles: ['SUPER_ADMIN', 'ADMIN', 'MANAGER']
        }
      },
      {
        path: 'bulk-assignment',
        component: BulkProductAssignmentComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'Bulk Assign Products',
          roles: ['SUPER_ADMIN', 'ADMIN']
        }
      },
      {
        path: 'assign/:shopId',
        component: BulkProductAssignmentComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'Assign Products to Shop',
          roles: ['SUPER_ADMIN', 'ADMIN', 'MANAGER']
        }
      },
      {
        path: 'shop-owner',
        component: ShopOwnerProductsComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'Select Products for My Shop',
          roles: ['SHOP_OWNER']
        }
      },
      {
        path: 'my-shop',
        component: ShopProductListComponent,
        canActivate: [RoleGuard],
        data: {
          title: 'My Shop Products',
          roles: ['SHOP_OWNER']
        }
      },
      {
        path: 'bulk-import',
        component: ProductBulkImportComponent,
        canActivate: [RoleGuard],
        data: {
          title: 'Bulk Import Products',
          roles: ['SUPER_ADMIN', 'ADMIN', 'SHOP_OWNER']
        }
      }
    ]
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class ProductRoutingModule { }