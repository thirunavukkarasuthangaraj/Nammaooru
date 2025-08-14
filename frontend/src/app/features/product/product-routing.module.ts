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
          roles: ['ADMIN', 'MANAGER']
        }
      },
      {
        path: 'master/new',
        component: MasterProductFormComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'New Master Product',
          roles: ['ADMIN', 'MANAGER']
        }
      },
      {
        path: 'master/:id',
        component: MasterProductFormComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'Edit Master Product',
          roles: ['ADMIN', 'MANAGER']
        }
      },
      {
        path: 'shop/:shopId',
        component: ShopProductListComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'Shop Products',
          roles: ['ADMIN', 'MANAGER', 'SHOP_OWNER']
        }
      },
      {
        path: 'shop/:shopId/new',
        component: ShopProductFormComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'Add Product to Shop',
          roles: ['ADMIN', 'MANAGER', 'SHOP_OWNER']
        }
      },
      {
        path: 'shop/:shopId/:productId',
        component: ShopProductFormComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'Edit Shop Product',
          roles: ['ADMIN', 'MANAGER', 'SHOP_OWNER']
        }
      },
      {
        path: 'categories',
        component: CategoryListComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'Product Categories',
          roles: ['ADMIN', 'MANAGER']
        }
      },
      {
        path: 'categories/new',
        component: CategoryFormComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'New Category',
          roles: ['ADMIN', 'MANAGER']
        }
      },
      {
        path: 'categories/:id',
        component: CategoryFormComponent,
        canActivate: [RoleGuard],
        data: { 
          title: 'Edit Category',
          roles: ['ADMIN', 'MANAGER']
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