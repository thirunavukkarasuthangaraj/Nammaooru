import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { NgChartsModule } from 'ng2-charts';

// Angular Material
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatTableModule } from '@angular/material/table';
import { MatPaginatorModule } from '@angular/material/paginator';
import { MatSortModule } from '@angular/material/sort';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatChipsModule } from '@angular/material/chips';
import { MatDialogModule } from '@angular/material/dialog';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTabsModule } from '@angular/material/tabs';
import { MatMenuModule } from '@angular/material/menu';
import { MatTooltipModule } from '@angular/material/tooltip';

import { FinancialManagementRoutingModule } from './financial-management-routing.module';

// Components
import { FinancialDashboardComponent } from './components/financial-dashboard/financial-dashboard.component';
import { RevenueAnalyticsComponent } from './components/revenue-analytics/revenue-analytics.component';
import { CommissionManagementComponent } from './components/commission-management/commission-management.component';
import { PayoutManagementComponent } from './components/payout-management/payout-management.component';
import { TransactionHistoryComponent } from './components/transaction-history/transaction-history.component';
import { FinancialReportsComponent } from './components/financial-reports/financial-reports.component';
import { TaxManagementComponent } from './components/tax-management/tax-management.component';
import { RefundManagementComponent } from './components/refund-management/refund-management.component';
import { SettlementTrackingComponent } from './components/settlement-tracking/settlement-tracking.component';

@NgModule({
  declarations: [
    FinancialDashboardComponent,
    RevenueAnalyticsComponent,
    CommissionManagementComponent,
    PayoutManagementComponent,
    TransactionHistoryComponent,
    FinancialReportsComponent,
    TaxManagementComponent,
    RefundManagementComponent,
    SettlementTrackingComponent
  ],
  imports: [
    CommonModule,
    FinancialManagementRoutingModule,
    ReactiveFormsModule,
    FormsModule,
    NgChartsModule,
    
    // Material Modules
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatTableModule,
    MatPaginatorModule,
    MatSortModule,
    MatInputModule,
    MatFormFieldModule,
    MatSelectModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatChipsModule,
    MatDialogModule,
    MatProgressSpinnerModule,
    MatTabsModule,
    MatMenuModule,
    MatTooltipModule
  ]
})
export class FinancialManagementModule { }