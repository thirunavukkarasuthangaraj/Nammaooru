import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from '@core/guards/auth.guard';
import { RoleGuard } from '@core/guards/role.guard';
import { UserRole } from '@core/models/auth.model';

import { ShopListComponent } from './components/shop-list/shop-list.component';
import { ShopDetailsComponent } from './components/shop-details/shop-details.component';
import { ShopFormComponent } from './components/shop-form/shop-form.component';
import { ShopMasterComponent } from './components/shop-master/shop-master.component';

const routes: Routes = [
  {
    path: '',
    component: ShopListComponent
  },
  {
    path: 'master',
    component: ShopMasterComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.ADMIN] }
  },
  {
    path: 'create',
    component: ShopFormComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.ADMIN, UserRole.SHOP_OWNER] }
  },
  {
    path: ':id/edit',
    component: ShopFormComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.ADMIN, UserRole.SHOP_OWNER] }
  },
  {
    path: ':id',
    component: ShopDetailsComponent
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class ShopRoutingModule { }