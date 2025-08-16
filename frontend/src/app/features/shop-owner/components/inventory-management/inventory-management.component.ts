import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { FormControl, FormGroup, FormBuilder, Validators } from '@angular/forms';
import { ShopProductService } from '@core/services/shop-product.service';
import { AuthService } from '@core/services/auth.service';
import { finalize } from 'rxjs/operators';

interface InventoryItem {
  id: number;
  productName: string;
  category: string;
  currentStock: number;
  minStock: number;
  maxStock: number;
  unit: string;
  price: number;
  cost: number;
  supplier: string;
  lastRestocked: Date;
  status: 'healthy' | 'low' | 'critical' | 'overstock';
  location: string;
  reorderPoint: number;
}

@Component({
  selector: 'app-inventory-management',
  template: `
    <div class="inventory-container">
      <!-- Header -->
      <div class="page-header">
        <div class="header-content">
          <h1 class="page-title">Inventory Management</h1>
          <p class="page-subtitle">Monitor and manage your stock levels</p>
        </div>
        <div class="header-actions">
          <button mat-raised-button color="primary" (click)="openBulkUpdate()">
            <mat-icon>system_update_alt</mat-icon>
            Bulk Update
          </button>
          <button mat-stroked-button (click)="generateReport()">
            <mat-icon>assessment</mat-icon>
            Generate Report
          </button>
        </div>
      </div>

      <!-- Inventory Summary Cards -->
      <div class="summary-cards">
        <mat-card class="summary-card healthy">
          <mat-card-content>
            <div class="card-content">
              <div class="card-icon">
                <mat-icon>check_circle</mat-icon>
              </div>
              <div class="card-details">
                <h3>{{ getHealthyStock() }}</h3>
                <p>Healthy Stock</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="summary-card low">
          <mat-card-content>
            <div class="card-content">
              <div class="card-icon">
                <mat-icon>warning</mat-icon>
              </div>
              <div class="card-details">
                <h3>{{ getLowStock() }}</h3>
                <p>Low Stock</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="summary-card critical">
          <mat-card-content>
            <div class="card-content">
              <div class="card-icon">
                <mat-icon>error</mat-icon>
              </div>
              <div class="card-details">
                <h3>{{ getCriticalStock() }}</h3>
                <p>Critical Stock</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="summary-card overstock">
          <mat-card-content>
            <div class="card-content">
              <div class="card-icon">
                <mat-icon>trending_up</mat-icon>
              </div>
              <div class="card-details">
                <h3>{{ getOverstock() }}</h3>
                <p>Overstock</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>
      </div>

      <!-- Filters and Controls -->
      <mat-card class="filters-card">
        <mat-card-content>
          <div class="filters-section">
            <div class="filter-group">
              <mat-form-field appearance="outline">
                <mat-label>Search Products</mat-label>
                <input matInput [formControl]="searchControl" placeholder="Search by name or category">
                <mat-icon matPrefix>search</mat-icon>
              </mat-form-field>

              <mat-form-field appearance="outline">
                <mat-label>Category</mat-label>
                <mat-select [(value)]="selectedCategory" (selectionChange)="applyFilters()">
                  <mat-option value="">All Categories</mat-option>
                  <mat-option *ngFor="let category of categories" [value]="category">
                    {{ category }}
                  </mat-option>
                </mat-select>
              </mat-form-field>

              <mat-form-field appearance="outline">
                <mat-label>Stock Status</mat-label>
                <mat-select [(value)]="selectedStatus" (selectionChange)="applyFilters()">
                  <mat-option value="">All Status</mat-option>
                  <mat-option value="healthy">Healthy</mat-option>
                  <mat-option value="low">Low Stock</mat-option>
                  <mat-option value="critical">Critical</mat-option>
                  <mat-option value="overstock">Overstock</mat-option>
                </mat-select>
              </mat-form-field>
            </div>

            <div class="action-group">
              <button mat-button color="warn" (click)="showLowStockOnly()" [class.active]="showOnlyLowStock">
                <mat-icon>warning</mat-icon>
                Low Stock Only
              </button>
              <button mat-button (click)="showCriticalOnly()" [class.active]="showOnlyCritical">
                <mat-icon>error</mat-icon>
                Critical Only
              </button>
            </div>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Inventory Table -->
      <mat-card class="table-card">
        <mat-card-content>
          <div class="table-container">
            <table mat-table [dataSource]="dataSource" matSort class="inventory-table">
              
              <!-- Product Column -->
              <ng-container matColumnDef="product">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Product</th>
                <td mat-cell *matCellDef="let item">
                  <div class="product-cell">
                    <div class="product-info">
                      <h4>{{ item.productName }}</h4>
                      <p>{{ item.category }}</p>
                    </div>
                  </div>
                </td>
              </ng-container>

              <!-- Current Stock Column -->
              <ng-container matColumnDef="currentStock">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Current Stock</th>
                <td mat-cell *matCellDef="let item">
                  <div class="stock-cell">
                    <span class="stock-value" [class]="getStockClass(item)">
                      {{ item.currentStock }} {{ item.unit }}
                    </span>
                    <div class="stock-bar">
                      <div class="stock-fill" [style.width.%]="getStockPercentage(item)" [class]="getStockClass(item)"></div>
                    </div>
                  </div>
                </td>
              </ng-container>

              <!-- Min/Max Stock Column -->
              <ng-container matColumnDef="minMaxStock">
                <th mat-header-cell *matHeaderCellDef>Min/Max Stock</th>
                <td mat-cell *matCellDef="let item">
                  <div class="min-max-cell">
                    <span class="min-stock">Min: {{ item.minStock }}</span>
                    <span class="max-stock">Max: {{ item.maxStock }}</span>
                  </div>
                </td>
              </ng-container>

              <!-- Status Column -->
              <ng-container matColumnDef="status">
                <th mat-header-cell *matHeaderCellDef>Status</th>
                <td mat-cell *matCellDef="let item">
                  <span class="status-badge" [class]="'status-' + item.status">
                    <mat-icon>{{ getStatusIcon(item.status) }}</mat-icon>
                    {{ getStatusLabel(item.status) }}
                  </span>
                </td>
              </ng-container>

              <!-- Price/Cost Column -->
              <ng-container matColumnDef="pricing">
                <th mat-header-cell *matHeaderCellDef>Price/Cost</th>
                <td mat-cell *matCellDef="let item">
                  <div class="pricing-cell">
                    <span class="price">₹{{ item.price }}</span>
                    <span class="cost">Cost: ₹{{ item.cost }}</span>
                  </div>
                </td>
              </ng-container>

              <!-- Last Restocked Column -->
              <ng-container matColumnDef="lastRestocked">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Last Restocked</th>
                <td mat-cell *matCellDef="let item">
                  <span class="date-value">{{ item.lastRestocked | date:'short' }}</span>
                </td>
              </ng-container>

              <!-- Actions Column -->
              <ng-container matColumnDef="actions">
                <th mat-header-cell *matHeaderCellDef>Actions</th>
                <td mat-cell *matCellDef="let item">
                  <div class="action-buttons">
                    <button mat-icon-button color="primary" (click)="updateStock(item)" matTooltip="Update Stock">
                      <mat-icon>add_box</mat-icon>
                    </button>
                    <button mat-icon-button color="accent" (click)="editSettings(item)" matTooltip="Edit Settings">
                      <mat-icon>settings</mat-icon>
                    </button>
                    <button mat-icon-button [matMenuTriggerFor]="actionMenu" [matMenuTriggerData]="{item: item}">
                      <mat-icon>more_vert</mat-icon>
                    </button>
                  </div>
                </td>
              </ng-container>

              <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
              <tr mat-row *matRowDef="let row; columns: displayedColumns;"></tr>
            </table>

            <mat-paginator [pageSizeOptions]="[10, 25, 50]" showFirstLastButtons></mat-paginator>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Quick Stock Update Panel -->
      <mat-card class="quick-update-card" *ngIf="showQuickUpdate">
        <mat-card-header>
          <mat-card-title>Quick Stock Update</mat-card-title>
          <button mat-icon-button (click)="closeQuickUpdate()">
            <mat-icon>close</mat-icon>
          </button>
        </mat-card-header>
        <mat-card-content>
          <form [formGroup]="quickUpdateForm" (ngSubmit)="submitQuickUpdate()">
            <div class="quick-update-grid">
              <mat-form-field appearance="outline">
                <mat-label>Product</mat-label>
                <mat-select formControlName="productId">
                  <mat-option *ngFor="let item of inventoryData" [value]="item.id">
                    {{ item.productName }}
                  </mat-option>
                </mat-select>
              </mat-form-field>

              <mat-form-field appearance="outline">
                <mat-label>Update Type</mat-label>
                <mat-select formControlName="updateType">
                  <mat-option value="add">Add Stock</mat-option>
                  <mat-option value="remove">Remove Stock</mat-option>
                  <mat-option value="set">Set Stock</mat-option>
                </mat-select>
              </mat-form-field>

              <mat-form-field appearance="outline">
                <mat-label>Quantity</mat-label>
                <input matInput type="number" formControlName="quantity" placeholder="Enter quantity">
              </mat-form-field>

              <mat-form-field appearance="outline">
                <mat-label>Reason</mat-label>
                <mat-select formControlName="reason">
                  <mat-option value="purchase">Purchase</mat-option>
                  <mat-option value="return">Customer Return</mat-option>
                  <mat-option value="damage">Damage/Loss</mat-option>
                  <mat-option value="sale">Manual Sale</mat-option>
                  <mat-option value="audit">Stock Audit</mat-option>
                </mat-select>
              </mat-form-field>
            </div>

            <div class="form-actions">
              <button mat-raised-button color="primary" type="submit" [disabled]="quickUpdateForm.invalid">
                Update Stock
              </button>
              <button mat-button type="button" (click)="closeQuickUpdate()">
                Cancel
              </button>
            </div>
          </form>
        </mat-card-content>
      </mat-card>
    </div>

    <!-- Action Menu -->
    <mat-menu #actionMenu="matMenu">
      <ng-template matMenuContent let-item="item">
        <button mat-menu-item (click)="updateStock(item)">
          <mat-icon>add_box</mat-icon>
          <span>Update Stock</span>
        </button>
        <button mat-menu-item (click)="editSettings(item)">
          <mat-icon>settings</mat-icon>
          <span>Edit Settings</span>
        </button>
        <button mat-menu-item (click)="viewHistory(item)">
          <mat-icon>history</mat-icon>
          <span>Stock History</span>
        </button>
        <button mat-menu-item (click)="reorderProduct(item)">
          <mat-icon>shopping_cart</mat-icon>
          <span>Reorder</span>
        </button>
      </ng-template>
    </mat-menu>
  `,
  styles: [`
    .inventory-container {
      padding: 24px;
      background-color: #f5f5f5;
      min-height: calc(100vh - 64px);
    }

    .page-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
    }

    .page-title {
      font-size: 2rem;
      font-weight: 600;
      margin: 0 0 4px 0;
      color: #1f2937;
    }

    .page-subtitle {
      font-size: 1rem;
      color: #6b7280;
      margin: 0;
    }

    .header-actions {
      display: flex;
      gap: 12px;
    }

    .summary-cards {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }

    .summary-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      overflow: hidden;
    }

    .summary-card.healthy { border-left: 4px solid #10b981; }
    .summary-card.low { border-left: 4px solid #f59e0b; }
    .summary-card.critical { border-left: 4px solid #ef4444; }
    .summary-card.overstock { border-left: 4px solid #6366f1; }

    .card-content {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .card-icon {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
    }

    .summary-card.healthy .card-icon { background: #10b981; }
    .summary-card.low .card-icon { background: #f59e0b; }
    .summary-card.critical .card-icon { background: #ef4444; }
    .summary-card.overstock .card-icon { background: #6366f1; }

    .card-details h3 {
      font-size: 1.5rem;
      font-weight: 600;
      margin: 0;
      color: #1f2937;
    }

    .card-details p {
      font-size: 0.9rem;
      color: #6b7280;
      margin: 0;
    }

    .filters-card {
      margin-bottom: 16px;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .filters-section {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
    }

    .filter-group {
      display: flex;
      gap: 16px;
      align-items: center;
    }

    .action-group {
      display: flex;
      gap: 8px;
    }

    .action-group button.active {
      background: #fef3c7;
      color: #92400e;
    }

    .table-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      margin-bottom: 16px;
    }

    .table-container {
      overflow-x: auto;
    }

    .inventory-table {
      width: 100%;
      min-width: 1000px;
    }

    .product-cell {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .product-info h4 {
      margin: 0 0 2px 0;
      font-size: 0.9rem;
      font-weight: 600;
      color: #1f2937;
    }

    .product-info p {
      margin: 0;
      font-size: 0.8rem;
      color: #6b7280;
    }

    .stock-cell {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .stock-value {
      font-weight: 600;
      font-size: 0.9rem;
    }

    .stock-value.healthy { color: #10b981; }
    .stock-value.low { color: #f59e0b; }
    .stock-value.critical { color: #ef4444; }
    .stock-value.overstock { color: #6366f1; }

    .stock-bar {
      width: 60px;
      height: 4px;
      background: #e5e7eb;
      border-radius: 2px;
      overflow: hidden;
    }

    .stock-fill {
      height: 100%;
      transition: width 0.3s ease;
    }

    .stock-fill.healthy { background: #10b981; }
    .stock-fill.low { background: #f59e0b; }
    .stock-fill.critical { background: #ef4444; }
    .stock-fill.overstock { background: #6366f1; }

    .min-max-cell {
      display: flex;
      flex-direction: column;
      gap: 2px;
    }

    .min-stock, .max-stock {
      font-size: 0.8rem;
      color: #6b7280;
    }

    .status-badge {
      display: flex;
      align-items: center;
      gap: 4px;
      padding: 4px 8px;
      border-radius: 16px;
      font-size: 0.8rem;
      font-weight: 500;
    }

    .status-badge.status-healthy {
      background: #dcfce7;
      color: #16a34a;
    }

    .status-badge.status-low {
      background: #fef3c7;
      color: #92400e;
    }

    .status-badge.status-critical {
      background: #fef2f2;
      color: #dc2626;
    }

    .status-badge.status-overstock {
      background: #ede9fe;
      color: #7c3aed;
    }

    .pricing-cell {
      display: flex;
      flex-direction: column;
      gap: 2px;
    }

    .price {
      font-weight: 600;
      color: #1f2937;
    }

    .cost {
      font-size: 0.8rem;
      color: #6b7280;
    }

    .date-value {
      font-size: 0.8rem;
      color: #6b7280;
    }

    .action-buttons {
      display: flex;
      gap: 4px;
    }

    .quick-update-card {
      position: fixed;
      bottom: 24px;
      right: 24px;
      width: 400px;
      z-index: 1000;
      border-radius: 12px;
      box-shadow: 0 8px 24px rgba(0,0,0,0.2);
    }

    .quick-update-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      margin-bottom: 16px;
    }

    .form-actions {
      display: flex;
      gap: 12px;
      justify-content: flex-end;
    }

    /* Mobile Responsive */
    @media (max-width: 768px) {
      .inventory-container {
        padding: 16px;
      }

      .page-header {
        flex-direction: column;
        gap: 16px;
        text-align: center;
      }

      .summary-cards {
        grid-template-columns: 1fr 1fr;
      }

      .filters-section {
        flex-direction: column;
        align-items: stretch;
      }

      .filter-group {
        flex-direction: column;
        gap: 12px;
      }

      .quick-update-card {
        position: static;
        width: 100%;
        margin-top: 16px;
      }

      .quick-update-grid {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class InventoryManagementComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  displayedColumns: string[] = ['product', 'currentStock', 'minMaxStock', 'status', 'pricing', 'lastRestocked', 'actions'];
  dataSource = new MatTableDataSource<InventoryItem>();
  searchControl = new FormControl();
  
  selectedCategory = '';
  selectedStatus = '';
  showOnlyLowStock = false;
  showOnlyCritical = false;
  showQuickUpdate = false;

  quickUpdateForm: FormGroup;

  categories = ['Groceries', 'Vegetables', 'Fruits', 'Dairy', 'Bakery', 'Beverages'];

  // Mock data
  inventoryData: InventoryItem[] = [
    {
      id: 1,
      productName: 'Organic Rice',
      category: 'Groceries',
      currentStock: 50,
      minStock: 20,
      maxStock: 100,
      unit: 'kg',
      price: 120,
      cost: 90,
      supplier: 'ABC Suppliers',
      lastRestocked: new Date('2024-01-10'),
      status: 'healthy',
      location: 'Aisle 1',
      reorderPoint: 25
    },
    {
      id: 2,
      productName: 'Fresh Tomatoes',
      category: 'Vegetables',
      currentStock: 3,
      minStock: 10,
      maxStock: 50,
      unit: 'kg',
      price: 40,
      cost: 25,
      supplier: 'Local Farm',
      lastRestocked: new Date('2024-01-08'),
      status: 'critical',
      location: 'Cold Storage',
      reorderPoint: 8
    },
    {
      id: 3,
      productName: 'Whole Wheat Bread',
      category: 'Bakery',
      currentStock: 15,
      minStock: 10,
      maxStock: 30,
      unit: 'piece',
      price: 35,
      cost: 20,
      supplier: 'Daily Bread Co',
      lastRestocked: new Date('2024-01-12'),
      status: 'low',
      location: 'Bakery Section',
      reorderPoint: 12
    },
    {
      id: 4,
      productName: 'Premium Honey',
      category: 'Groceries',
      currentStock: 85,
      minStock: 15,
      maxStock: 40,
      unit: 'bottle',
      price: 350,
      cost: 200,
      supplier: 'Mountain Honey',
      lastRestocked: new Date('2024-01-01'),
      status: 'overstock',
      location: 'Aisle 3',
      reorderPoint: 20
    }
  ];

  loading = false;

  constructor(
    private fb: FormBuilder,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    private shopProductService: ShopProductService,
    private authService: AuthService
  ) {
    this.dataSource.data = [];
    this.quickUpdateForm = this.fb.group({
      productId: ['', Validators.required],
      updateType: ['add', Validators.required],
      quantity: ['', [Validators.required, Validators.min(1)]],
      reason: ['', Validators.required]
    });
  }

  ngOnInit(): void {
    this.setupFilters();
    this.loadInventoryData();
  }

  loadInventoryData(): void {
    this.loading = true;
    const currentUser = this.authService.getCurrentUser();
    
    if (!currentUser || !currentUser.shopId) {
      this.snackBar.open('Shop information not found', 'Close', { duration: 3000 });
      this.loading = false;
      // Fallback to mock data if no shop ID
      this.dataSource.data = this.inventoryData;
      return;
    }

    this.shopProductService.getShopProducts(currentUser.shopId, 0, 100)
      .pipe(
        finalize(() => this.loading = false)
      )
      .subscribe({
        next: (response) => {
          // Map API response to InventoryItem interface
          const inventoryItems = response.content.map((item: any) => ({
            id: item.id,
            productName: item.masterProduct.name,
            category: item.masterProduct.category?.name || 'Uncategorized',
            currentStock: item.stockQuantity,
            minStock: item.lowStockThreshold || 10,
            maxStock: item.maxStockThreshold || 100,
            unit: item.unit || 'piece',
            price: item.sellingPrice,
            cost: item.costPrice || item.sellingPrice * 0.7,
            supplier: item.supplier || 'Local Supplier',
            lastRestocked: new Date(item.lastRestockedAt || item.updatedAt),
            status: this.getStockStatus(item.stockQuantity, item.lowStockThreshold || 10),
            location: item.location || 'Main Store',
            reorderPoint: item.lowStockThreshold || 10
          }));
          
          this.inventoryData = inventoryItems;
          this.dataSource.data = this.inventoryData;
        },
        error: (error) => {
          console.error('Error loading inventory:', error);
          this.snackBar.open('Failed to load inventory. Showing sample data.', 'Close', { duration: 3000 });
          // Fallback to mock data on error
          this.dataSource.data = this.inventoryData;
        }
      });
  }

  private getStockStatus(currentStock: number, minStock: number): 'healthy' | 'low' | 'critical' | 'overstock' {
    if (currentStock === 0) return 'critical';
    if (currentStock <= minStock) return 'low';
    if (currentStock > minStock * 3) return 'overstock';
    return 'healthy';
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  private setupFilters(): void {
    this.searchControl.valueChanges.subscribe(() => {
      this.applyFilters();
    });
  }

  applyFilters(): void {
    this.dataSource.filterPredicate = (data: InventoryItem, filter: string) => {
      const searchTerm = this.searchControl.value?.toLowerCase() || '';
      const matchesSearch = data.productName.toLowerCase().includes(searchTerm) || 
                           data.category.toLowerCase().includes(searchTerm);
      const matchesCategory = !this.selectedCategory || data.category === this.selectedCategory;
      const matchesStatus = !this.selectedStatus || data.status === this.selectedStatus;
      const matchesLowStock = !this.showOnlyLowStock || data.status === 'low' || data.status === 'critical';
      const matchesCritical = !this.showOnlyCritical || data.status === 'critical';
      
      return matchesSearch && matchesCategory && matchesStatus && matchesLowStock && matchesCritical;
    };
    
    this.dataSource.filter = Math.random().toString();
  }

  getHealthyStock(): number {
    return this.inventoryData.filter(item => item.status === 'healthy').length;
  }

  getLowStock(): number {
    return this.inventoryData.filter(item => item.status === 'low').length;
  }

  getCriticalStock(): number {
    return this.inventoryData.filter(item => item.status === 'critical').length;
  }

  getOverstock(): number {
    return this.inventoryData.filter(item => item.status === 'overstock').length;
  }

  getStockClass(item: InventoryItem): string {
    return item.status;
  }

  getStockPercentage(item: InventoryItem): number {
    return Math.min((item.currentStock / item.maxStock) * 100, 100);
  }

  getStatusIcon(status: string): string {
    switch (status) {
      case 'healthy': return 'check_circle';
      case 'low': return 'warning';
      case 'critical': return 'error';
      case 'overstock': return 'trending_up';
      default: return 'help';
    }
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'healthy': return 'Healthy';
      case 'low': return 'Low Stock';
      case 'critical': return 'Critical';
      case 'overstock': return 'Overstock';
      default: return status;
    }
  }

  showLowStockOnly(): void {
    this.showOnlyLowStock = !this.showOnlyLowStock;
    this.showOnlyCritical = false;
    this.applyFilters();
  }

  showCriticalOnly(): void {
    this.showOnlyCritical = !this.showOnlyCritical;
    this.showOnlyLowStock = false;
    this.applyFilters();
  }

  updateStock(item: InventoryItem): void {
    this.showQuickUpdate = true;
    this.quickUpdateForm.patchValue({
      productId: item.id
    });
  }

  editSettings(item: InventoryItem): void {
    console.log('Edit settings for:', item);
    // Open settings dialog
  }

  viewHistory(item: InventoryItem): void {
    console.log('View history for:', item);
    // Navigate to history page
  }

  reorderProduct(item: InventoryItem): void {
    console.log('Reorder product:', item);
    // Create reorder request
  }

  openBulkUpdate(): void {
    console.log('Open bulk update');
    // Navigate to bulk update page
  }

  generateReport(): void {
    console.log('Generate inventory report');
    // Generate and download report
  }

  closeQuickUpdate(): void {
    this.showQuickUpdate = false;
    this.quickUpdateForm.reset();
  }

  submitQuickUpdate(): void {
    if (this.quickUpdateForm.valid) {
      const formData = this.quickUpdateForm.value;
      console.log('Update stock:', formData);
      
      // Simulate stock update
      const item = this.inventoryData.find(i => i.id === formData.productId);
      if (item) {
        switch (formData.updateType) {
          case 'add':
            item.currentStock += formData.quantity;
            break;
          case 'remove':
            item.currentStock = Math.max(0, item.currentStock - formData.quantity);
            break;
          case 'set':
            item.currentStock = formData.quantity;
            break;
        }
        
        // Update status
        if (item.currentStock <= item.reorderPoint) {
          item.status = item.currentStock <= (item.reorderPoint / 2) ? 'critical' : 'low';
        } else if (item.currentStock > item.maxStock) {
          item.status = 'overstock';
        } else {
          item.status = 'healthy';
        }
        
        item.lastRestocked = new Date();
        this.dataSource.data = [...this.inventoryData];
      }
      
      this.snackBar.open('Stock updated successfully', 'Close', { duration: 3000 });
      this.closeQuickUpdate();
    }
  }
}