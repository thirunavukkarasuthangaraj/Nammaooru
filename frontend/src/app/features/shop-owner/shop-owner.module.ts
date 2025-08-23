import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatDividerModule } from '@angular/material/divider';
import { MatMenuModule } from '@angular/material/menu';
import { MatBadgeModule } from '@angular/material/badge';
import { MatChipsModule } from '@angular/material/chips';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSnackBarModule } from '@angular/material/snack-bar';
import { MatTableModule } from '@angular/material/table';
import { MatPaginatorModule } from '@angular/material/paginator';
import { MatSortModule } from '@angular/material/sort';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonToggleModule } from '@angular/material/button-toggle';
import { MatDialogModule } from '@angular/material/dialog';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatRadioModule } from '@angular/material/radio';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatTabsModule } from '@angular/material/tabs';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatStepperModule } from '@angular/material/stepper';

import { ShopOwnerRoutingModule } from './shop-owner-routing.module';
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

@NgModule({
  declarations: [
    ShopOwnerDashboardComponent,
    ShopProfileComponent,
    ShopOverviewComponent,
    MyProductsComponent,
    InventoryManagementComponent,
    OrderManagementComponent,
    AddProductComponent,
    BulkUploadComponent,
    CategoriesComponent,
    CustomerManagementComponent,
    ShopSettingsComponent,
    NotificationsComponent
  ],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    FormsModule,
    ShopOwnerRoutingModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatDividerModule,
    MatMenuModule,
    MatBadgeModule,
    MatChipsModule,
    MatFormFieldModule,
    MatInputModule,
    MatSnackBarModule,
    MatTableModule,
    MatPaginatorModule,
    MatSortModule,
    MatSelectModule,
    MatButtonToggleModule,
    MatDialogModule,
    MatTooltipModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatRadioModule,
    MatCheckboxModule,
    MatTabsModule,
    MatSlideToggleModule,
    MatStepperModule
  ]
})
export class ShopOwnerModule { }