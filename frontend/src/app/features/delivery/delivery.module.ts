import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatTableModule } from '@angular/material/table';
import { MatPaginatorModule } from '@angular/material/paginator';
import { MatSortModule } from '@angular/material/sort';
import { MatIconModule } from '@angular/material/icon';
import { MatChipsModule } from '@angular/material/chips';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSnackBarModule } from '@angular/material/snack-bar';
import { MatDialogModule } from '@angular/material/dialog';
import { MatExpansionModule } from '@angular/material/expansion';
import { MatTabsModule } from '@angular/material/tabs';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatBadgeModule } from '@angular/material/badge';
import { MatMenuModule } from '@angular/material/menu';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatStepperModule } from '@angular/material/stepper';
import { MatDividerModule } from '@angular/material/divider';
import { MatListModule } from '@angular/material/list';

import { DeliveryRoutingModule } from './delivery-routing.module';
import { SharedModule } from '../../shared/shared.module';

// Components
import { DeliveryDashboardComponent } from './components/delivery-dashboard/delivery-dashboard.component';
import { DeliveryPartnerDashboardComponent } from './components/delivery-partner-dashboard/delivery-partner-dashboard.component';
import { PartnerRegistrationComponent } from './components/partner-registration/partner-registration.component';
import { AdminPartnersComponent } from './components/admin-partners/admin-partners.component';
import { OrderTrackingComponent } from './components/order-tracking/order-tracking.component';
import { PartnerOrdersComponent } from './components/partner-orders/partner-orders.component';
import { DeliveryAnalyticsComponent } from './components/delivery-analytics/delivery-analytics.component';
import { PartnerStatusDialogComponent } from './components/partner-status-dialog/partner-status-dialog.component';
import { OrderAssignmentDialogComponent } from './components/order-assignment-dialog/order-assignment-dialog.component';
import { TrackingMapComponent } from './components/tracking-map/tracking-map.component';
import { EarningsOverviewComponent } from './components/earnings-overview/earnings-overview.component';
import { AvailableOrdersComponent } from './components/available-orders/available-orders.component';
import { PartnerDetailsDialogComponent } from './components/partner-details-dialog/partner-details-dialog.component';
import { DocumentVerificationDialogComponent } from './components/document-verification-dialog/document-verification-dialog.component';
import { DeliveryPartnerDocumentsComponent } from './components/delivery-partner-documents/delivery-partner-documents.component';
import { DeliveryPartnerDocumentViewerComponent } from './components/delivery-partner-document-viewer/delivery-partner-document-viewer.component';
import { SimpleDocumentViewerComponent } from './components/simple-document-viewer/simple-document-viewer.component';
import { OrderAssignmentsComponent } from './components/order-assignments/order-assignments.component';

// Services
import { DeliveryPartnerService } from './services/delivery-partner.service';
import { OrderAssignmentService } from './services/order-assignment.service';
import { DeliveryTrackingService } from './services/delivery-tracking.service';
import { DeliveryAssignmentService } from './services/delivery-assignment.service';

@NgModule({
  declarations: [
    DeliveryDashboardComponent,
    DeliveryPartnerDashboardComponent,
    PartnerRegistrationComponent,
    AdminPartnersComponent,
    OrderTrackingComponent,
    PartnerOrdersComponent,
    DeliveryAnalyticsComponent,
    PartnerStatusDialogComponent,
    OrderAssignmentDialogComponent,
    TrackingMapComponent,
    EarningsOverviewComponent,
    AvailableOrdersComponent,
    PartnerDetailsDialogComponent,
    DocumentVerificationDialogComponent,
    DeliveryPartnerDocumentsComponent,
    DeliveryPartnerDocumentViewerComponent,
    SimpleDocumentViewerComponent,
    OrderAssignmentsComponent
  ],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    FormsModule,
    DeliveryRoutingModule,
    SharedModule,
    
    // Angular Material Modules
    MatToolbarModule,
    MatCardModule,
    MatButtonModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatTableModule,
    MatPaginatorModule,
    MatSortModule,
    MatIconModule,
    MatChipsModule,
    MatProgressSpinnerModule,
    MatSnackBarModule,
    MatDialogModule,
    MatExpansionModule,
    MatTabsModule,
    MatSlideToggleModule,
    MatProgressBarModule,
    MatBadgeModule,
    MatMenuModule,
    MatTooltipModule,
    MatStepperModule,
    MatDividerModule,
    MatListModule
  ],
  providers: [
    DeliveryPartnerService,
    OrderAssignmentService,
    DeliveryTrackingService,
    DeliveryAssignmentService
  ],
  exports: [
    DeliveryPartnerDocumentsComponent,
    DeliveryPartnerDocumentViewerComponent
  ]
})
export class DeliveryModule { }