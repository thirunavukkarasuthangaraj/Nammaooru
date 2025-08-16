import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';

// Angular Material
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatTableModule } from '@angular/material/table';
import { MatPaginatorModule } from '@angular/material/paginator';
import { MatSortModule } from '@angular/material/sort';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatDialogModule } from '@angular/material/dialog';
import { MatSnackBarModule } from '@angular/material/snack-bar';
import { MatChipsModule } from '@angular/material/chips';
import { MatTabsModule } from '@angular/material/tabs';
import { MatExpansionModule } from '@angular/material/expansion';
import { MatMenuModule } from '@angular/material/menu';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatDividerModule } from '@angular/material/divider';
import { MatTooltipModule } from '@angular/material/tooltip';

import { ShopRoutingModule } from './shop-routing.module';
import { SharedModule } from '../../shared/shared.module';

// Components
import { ShopListComponent } from './components/shop-list/shop-list.component';
import { ShopCardComponent } from './components/shop-card/shop-card.component';
import { ShopDetailsComponent } from './components/shop-details/shop-details.component';
import { ShopFormComponent } from './components/shop-form/shop-form.component';
import { ShopFilterComponent } from './components/shop-filter/shop-filter.component';
// import { ShopMapComponent } from './components/shop-map/shop-map.component'; // Disabled - Google Maps issues
import { ShopImageUploadComponent } from './components/shop-image-upload/shop-image-upload.component';
import { ShopMasterComponent } from './components/shop-master/shop-master.component';
import { DocumentUploadComponent } from './components/document-upload/document-upload.component';
import { SimpleDocumentUploadComponent } from './components/simple-document-upload/simple-document-upload.component';
import { ShopApprovalComponent } from './components/shop-approval/shop-approval.component';
import { ShopApprovalsListComponent } from './components/shop-approvals-list/shop-approvals-list.component';

@NgModule({
  declarations: [
    ShopListComponent,
    ShopCardComponent,
    ShopDetailsComponent,
    ShopFormComponent,
    ShopFilterComponent,
    // ShopMapComponent, // Disabled - Google Maps issues
    ShopImageUploadComponent,
    ShopMasterComponent,
    DocumentUploadComponent,
    SimpleDocumentUploadComponent,
    ShopApprovalComponent,
    ShopApprovalsListComponent
  ],
  imports: [
    CommonModule,
    ShopRoutingModule,
    ReactiveFormsModule,
    FormsModule,
    SharedModule,
    
    // Angular Material
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatCheckboxModule,
    MatSlideToggleModule,
    MatTableModule,
    MatPaginatorModule,
    MatSortModule,
    MatProgressSpinnerModule,
    MatDialogModule,
    MatSnackBarModule,
    MatChipsModule,
    MatTabsModule,
    MatExpansionModule,
    MatMenuModule,
    MatToolbarModule,
    MatProgressBarModule,
    MatDividerModule,
    MatTooltipModule
  ],
  exports: [
    ShopCardComponent,
    ShopListComponent
    // ShopMapComponent // Disabled - Google Maps issues
  ]
})
export class ShopModule { }