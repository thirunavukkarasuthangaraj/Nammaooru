import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { MatTableModule } from '@angular/material/table';
import { MatPaginatorModule } from '@angular/material/paginator';
import { MatSortModule } from '@angular/material/sort';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { MatCardModule } from '@angular/material/card';
import { MatDialogModule } from '@angular/material/dialog';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatChipsModule } from '@angular/material/chips';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSnackBarModule } from '@angular/material/snack-bar';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatButtonToggleModule } from '@angular/material/button-toggle';
import { MatMenuModule } from '@angular/material/menu';
import { MatRadioModule } from '@angular/material/radio';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatDividerModule } from '@angular/material/divider';

import { CustomerListComponent } from './components/customer-list/customer-list.component';
import { CustomerFormComponent } from './components/customer-form/customer-form.component';
import { CustomerDetailComponent } from './components/customer-detail/customer-detail.component';
import { DeliveryFeeManagementComponent } from './components/delivery-fee-management/delivery-fee-management.component';
import { PromoCodeListComponent } from './components/promo-code-management/promo-code-list.component';
import { PromoCodeFormComponent } from './components/promo-code-management/promo-code-form.component';
import { PromoCodeStatsComponent } from './components/promo-code-management/promo-code-stats.component';
import { MarketingMessagesComponent } from './components/marketing-messages/marketing-messages.component';
import { PushNotificationSenderComponent } from './components/push-notification-sender/push-notification-sender.component';
import { MenuPermissionsComponent } from './components/menu-permissions/menu-permissions.component';
import { MarketplaceManagementComponent } from './components/marketplace-management/marketplace-management.component';
import { RealEstateManagementComponent } from './components/real-estate-management/real-estate-management.component';
import { BusTimingManagementComponent } from './components/bus-timing-management/bus-timing-management.component';
import { ReportedPostsComponent } from './components/reported-posts/reported-posts.component';
import { MarketplaceConfigComponent } from './components/marketplace-config/marketplace-config.component';
import { FarmerProductsManagementComponent } from './components/farmer-products-management/farmer-products-management.component';

@NgModule({
  declarations: [
    CustomerListComponent,
    CustomerFormComponent,
    CustomerDetailComponent,
    DeliveryFeeManagementComponent,
    PromoCodeListComponent,
    PromoCodeFormComponent,
    PromoCodeStatsComponent,
    MarketingMessagesComponent,
    PushNotificationSenderComponent,
    MenuPermissionsComponent,
    MarketplaceManagementComponent,
    RealEstateManagementComponent,
    BusTimingManagementComponent,
    ReportedPostsComponent,
    MarketplaceConfigComponent,
    FarmerProductsManagementComponent
  ],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    FormsModule,
    MatTableModule,
    MatPaginatorModule,
    MatSortModule,
    MatButtonModule,
    MatIconModule,
    MatInputModule,
    MatFormFieldModule,
    MatSelectModule,
    MatCardModule,
    MatDialogModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatCheckboxModule,
    MatChipsModule,
    MatTooltipModule,
    MatProgressSpinnerModule,
    MatSnackBarModule,
    MatSlideToggleModule,
    MatButtonToggleModule,
    MatMenuModule,
    MatRadioModule,
    MatProgressBarModule,
    MatDividerModule,
    RouterModule.forChild([
      {
        path: '',
        redirectTo: 'customers',
        pathMatch: 'full'
      },
      {
        path: 'customers',
        component: CustomerListComponent
      },
      {
        path: 'customers/create',
        component: CustomerFormComponent
      },
      {
        path: 'customers/:id',
        component: CustomerDetailComponent
      },
      {
        path: 'customers/:id/edit',
        component: CustomerFormComponent
      },
      {
        path: 'delivery-fees',
        component: DeliveryFeeManagementComponent
      },
      {
        path: 'promo-codes',
        component: PromoCodeListComponent
      },
      {
        path: 'push-notifications',
        component: PushNotificationSenderComponent
      },
      {
        path: 'marketing',
        component: MarketingMessagesComponent
      },
      {
        path: 'menu-permissions',
        component: MenuPermissionsComponent
      },
      {
        path: 'marketplace',
        component: MarketplaceManagementComponent
      },
      {
        path: 'real-estate',
        component: RealEstateManagementComponent
      },
      {
        path: 'bus-timing',
        component: BusTimingManagementComponent
      },
      {
        path: 'reported-posts',
        component: ReportedPostsComponent
      },
      {
        path: 'marketplace-config',
        component: MarketplaceConfigComponent
      },
      {
        path: 'farmer-products',
        component: FarmerProductsManagementComponent
      },
      {
        path: 'shops',
        loadChildren: () => import('../shop/shop.module').then(m => m.ShopModule)
      }
    ])
  ]
})
export class AdminModule { }