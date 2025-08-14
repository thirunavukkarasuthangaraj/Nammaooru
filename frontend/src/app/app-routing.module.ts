import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from './core/guards/auth.guard';
import { RoleGuard } from './core/guards/role.guard';
import { UserRole } from './core/models/auth.model';
import { UnauthorizedComponent } from './shared/components/unauthorized/unauthorized.component';
import { MainLayoutComponent } from './layout/main-layout/main-layout.component';

const routes: Routes = [
  {
    path: '',
    redirectTo: '/dashboard',
    pathMatch: 'full'
  },
  {
    path: 'auth/login',
    loadComponent: () => import('./features/auth/login/login.component').then(m => m.LoginComponent)
  },
  {
    path: '',
    component: MainLayoutComponent,
    canActivate: [AuthGuard],
    children: [
      {
        path: 'dashboard',
        loadComponent: () => import('./features/dashboard/dashboard.component').then(m => m.DashboardComponent)
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
        data: { roles: [UserRole.ADMIN] }
      },
      {
        path: 'shop-owner',
        loadChildren: () => import('./features/shop-owner/shop-owner.module').then(m => m.ShopOwnerModule),
        canActivate: [RoleGuard],
        data: { roles: [UserRole.SHOP_OWNER, UserRole.ADMIN] }
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