import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from '../../core/guards/auth.guard';
import { RoleGuard } from '../../core/guards/role.guard';
import { UserRole } from '../../core/models/auth.model';

import { FinancialDashboardComponent } from './components/financial-dashboard/financial-dashboard.component';
import { RevenueAnalyticsComponent } from './components/revenue-analytics/revenue-analytics.component';
import { CommissionManagementComponent } from './components/commission-management/commission-management.component';
import { PayoutManagementComponent } from './components/payout-management/payout-management.component';
import { TransactionHistoryComponent } from './components/transaction-history/transaction-history.component';
import { FinancialReportsComponent } from './components/financial-reports/financial-reports.component';
import { TaxManagementComponent } from './components/tax-management/tax-management.component';
import { RefundManagementComponent } from './components/refund-management/refund-management.component';
import { SettlementTrackingComponent } from './components/settlement-tracking/settlement-tracking.component';

const routes: Routes = [
  {
    path: '',
    component: FinancialDashboardComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN] }
  },
  {
    path: 'revenue',
    component: RevenueAnalyticsComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN] }
  },
  {
    path: 'commission',
    component: CommissionManagementComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.SUPER_ADMIN] }
  },
  {
    path: 'payouts',
    component: PayoutManagementComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN] }
  },
  {
    path: 'transactions',
    component: TransactionHistoryComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SHOP_OWNER] }
  },
  {
    path: 'reports',
    component: FinancialReportsComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SHOP_OWNER] }
  },
  {
    path: 'tax',
    component: TaxManagementComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN] }
  },
  {
    path: 'refunds',
    component: RefundManagementComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN] }
  },
  {
    path: 'settlements',
    component: SettlementTrackingComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { roles: [UserRole.SUPER_ADMIN, UserRole.ADMIN] }
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class FinancialManagementRoutingModule { }