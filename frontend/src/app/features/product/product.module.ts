import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { MatTableModule } from '@angular/material/table';
import { MatPaginatorModule } from '@angular/material/paginator';
import { MatSortModule } from '@angular/material/sort';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatSelectModule } from '@angular/material/select';
import { MatCardModule } from '@angular/material/card';
import { MatChipsModule } from '@angular/material/chips';
import { MatTabsModule } from '@angular/material/tabs';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatMenuModule } from '@angular/material/menu';
import { MatDialogModule } from '@angular/material/dialog';
import { MatSnackBarModule } from '@angular/material/snack-bar';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatTreeModule } from '@angular/material/tree';
import { MatExpansionModule } from '@angular/material/expansion';
import { MatBadgeModule } from '@angular/material/badge';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatDividerModule } from '@angular/material/divider';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { DragDropModule } from '@angular/cdk/drag-drop';

import { ProductRoutingModule } from './product-routing.module';
import { SharedModule } from '../../shared/shared.module';

// Components
import { ProductMasterComponent } from './components/product-master/product-master.component';
import { ProductDashboardComponent } from './components/product-dashboard/product-dashboard.component';
import { MasterProductListComponent } from './components/master-product-list/master-product-list.component';
import { MasterProductFormComponent } from './components/master-product-form/master-product-form.component';
import { ShopProductListComponent } from './components/shop-product-list/shop-product-list.component';
import { ShopProductFormComponent } from './components/shop-product-form/shop-product-form.component';
import { CategoryListComponent } from './components/category-list/category-list.component';
import { CategoryFormComponent } from './components/category-form/category-form.component';
import { ProductFiltersComponent } from './components/product-filters/product-filters.component';
import { ProductStatsCardComponent } from './components/product-stats-card/product-stats-card.component';
import { CategoryTreeComponent } from './components/category-tree/category-tree.component';
import { InventoryDialogComponent } from './components/inventory-dialog/inventory-dialog.component';
import { ProductImageUploadComponent } from './components/product-image-upload/product-image-upload.component';

@NgModule({
  declarations: [
    ProductMasterComponent,
    ProductDashboardComponent,
    MasterProductListComponent,
    MasterProductFormComponent,
    ShopProductListComponent,
    ShopProductFormComponent,
    CategoryListComponent,
    CategoryFormComponent,
    ProductFiltersComponent,
    ProductStatsCardComponent,
    CategoryTreeComponent,
    InventoryDialogComponent,
    ProductImageUploadComponent
  ],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    FormsModule,
    ProductRoutingModule,
    SharedModule,
    
    // Angular Material
    MatTableModule,
    MatPaginatorModule,
    MatSortModule,
    MatInputModule,
    MatFormFieldModule,
    MatButtonModule,
    MatIconModule,
    MatSelectModule,
    MatCardModule,
    MatChipsModule,
    MatTabsModule,
    MatToolbarModule,
    MatMenuModule,
    MatDialogModule,
    MatSnackBarModule,
    MatProgressSpinnerModule,
    MatCheckboxModule,
    MatSlideToggleModule,
    MatTreeModule,
    MatExpansionModule,
    MatBadgeModule,
    MatTooltipModule,
    MatDividerModule,
    MatProgressBarModule,
    DragDropModule
  ]
})
export class ProductModule { }