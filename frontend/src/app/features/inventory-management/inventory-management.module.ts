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
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatBadgeModule } from '@angular/material/badge';
import { MatProgressBarModule } from '@angular/material/progress-bar';

import { InventoryManagementRoutingModule } from './inventory-management-routing.module';

// Components
import { InventoryDashboardComponent } from './components/inventory-dashboard/inventory-dashboard.component';
import { ProductCatalogComponent } from './components/product-catalog/product-catalog.component';
import { StockManagementComponent } from './components/stock-management/stock-management.component';
import { InventoryAlertsComponent } from './components/inventory-alerts/inventory-alerts.component';
import { BulkUploadComponent } from './components/bulk-upload/bulk-upload.component';
import { ProductFormComponent } from './components/product-form/product-form.component';
import { StockAdjustmentComponent } from './components/stock-adjustment/stock-adjustment.component';
import { InventoryReportsComponent } from './components/inventory-reports/inventory-reports.component';
import { LowStockAlertsComponent } from './components/low-stock-alerts/low-stock-alerts.component';
import { CategoryManagementComponent } from './components/category-management/category-management.component';

@NgModule({
  declarations: [
    InventoryDashboardComponent,
    ProductCatalogComponent,
    StockManagementComponent,
    InventoryAlertsComponent,
    BulkUploadComponent,
    ProductFormComponent,
    StockAdjustmentComponent,
    InventoryReportsComponent,
    LowStockAlertsComponent,
    CategoryManagementComponent
  ],
  imports: [
    CommonModule,
    InventoryManagementRoutingModule,
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
    MatSlideToggleModule,
    MatBadgeModule,
    MatProgressBarModule
  ]
})
export class InventoryManagementModule { }