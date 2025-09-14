import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { UserListComponent } from './components/user-list/user-list.component';
import { UserDetailComponent } from './components/user-detail/user-detail.component';
import { UserFormComponent } from './components/user-form/user-form.component';
import { DeliveryPartnerDocumentsComponent } from '../delivery/components/delivery-partner-documents/delivery-partner-documents.component';
import { AuthGuard } from '../../core/guards/auth.guard';

const routes: Routes = [
  {
    path: '',
    component: UserListComponent,
    canActivate: [AuthGuard]
  },
  {
    path: 'admins',
    component: UserListComponent,
    canActivate: [AuthGuard],
    data: { role: 'ADMIN' }
  },
  {
    path: 'managers', 
    component: UserListComponent,
    canActivate: [AuthGuard],
    data: { role: 'MANAGER' }
  },
  {
    path: 'shop-owners',
    component: UserListComponent,
    canActivate: [AuthGuard], 
    data: { role: 'SHOP_OWNER' }
  },
  {
    path: 'delivery-partners',
    component: UserListComponent,
    canActivate: [AuthGuard],
    data: { role: 'DELIVERY_PARTNER' }
  },
  {
    path: 'customers',
    component: UserListComponent,
    canActivate: [AuthGuard],
    data: { role: 'USER' }
  },
  {
    path: 'new',
    component: UserFormComponent,
    canActivate: [AuthGuard]
  },
  {
    path: ':id',
    component: UserDetailComponent,
    canActivate: [AuthGuard]
  },
  {
    path: ':id/edit',
    component: UserFormComponent,
    canActivate: [AuthGuard]
  },
  {
    path: ':id/documents',
    component: DeliveryPartnerDocumentsComponent,
    canActivate: [AuthGuard]
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class UsersRoutingModule { }