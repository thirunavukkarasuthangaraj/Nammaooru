import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { Router } from '@angular/router';
import { ProductService } from '../../../../core/services/product.service';
import { MasterProduct, ProductFilters } from '../../../../core/models/product.model';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-master-product-list',
  template: `
    <div class="list-container">
      <div class="list-header">
        <h2>Master Products</h2>
        <div class="header-actions">
          <button mat-raised-button color="primary" routerLink="/products/master/new">
            <mat-icon>add</mat-icon>
            New Product
          </button>
        </div>
      </div>

      <mat-card class="filter-card">
        <app-product-filters 
          (filtersChange)="onFiltersChange($event)">
        </app-product-filters>
      </mat-card>

      <mat-card class="table-card">
        <div class="table-container">
          <table mat-table [dataSource]="dataSource" class="products-table" matSort>
            <ng-container matColumnDef="name">
              <th mat-header-cell *matHeaderCellDef mat-sort-header>Name</th>
              <td mat-cell *matCellDef="let product">
                <div class="product-name">{{ product.name }}</div>
                <div class="product-description">{{ product.description || 'No description' }}</div>
              </td>
            </ng-container>

            <ng-container matColumnDef="sku">
              <th mat-header-cell *matHeaderCellDef mat-sort-header>SKU</th>
              <td mat-cell *matCellDef="let product">{{ product.sku }}</td>
            </ng-container>

            <ng-container matColumnDef="brand">
              <th mat-header-cell *matHeaderCellDef>Brand</th>
              <td mat-cell *matCellDef="let product">{{ product.brand || '-' }}</td>
            </ng-container>

            <ng-container matColumnDef="status">
              <th mat-header-cell *matHeaderCellDef>Status</th>
              <td mat-cell *matCellDef="let product">
                <mat-chip [color]="product.status === 'ACTIVE' ? 'primary' : 'warn'"
                         [class.selected]="product.status === 'ACTIVE'">
                  {{ product.status }}
                </mat-chip>
              </td>
            </ng-container>

            <ng-container matColumnDef="actions">
              <th mat-header-cell *matHeaderCellDef>Actions</th>
              <td mat-cell *matCellDef="let product">
                <button mat-icon-button [routerLink]="['/products/master', product.id]" matTooltip="Edit">
                  <mat-icon>edit</mat-icon>
                </button>
                <button mat-icon-button (click)="deleteProduct(product)" matTooltip="Delete" color="warn">
                  <mat-icon>delete</mat-icon>
                </button>
              </td>
            </ng-container>

            <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
            <tr mat-row *matRowDef="let row; columns: displayedColumns;"></tr>
          </table>
        </div>

        <mat-paginator 
          [pageSizeOptions]="[5, 10, 25, 100]"
          showFirstLastButtons>
        </mat-paginator>
      </mat-card>
    </div>
  `,
  styles: [`
    .list-container {
      padding: 24px;
      max-width: 1200px;
      margin: 0 auto;
    }

    .list-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
    }

    .filter-card {
      margin-bottom: 16px;
    }

    .table-card {
      overflow: hidden;
    }

    .table-container {
      overflow-x: auto;
    }

    .products-table {
      width: 100%;
    }

    .product-name {
      font-weight: 500;
      margin-bottom: 4px;
    }

    .product-description {
      font-size: 12px;
      color: #666;
    }

    @media (max-width: 768px) {
      .list-container {
        padding: 16px;
      }

      .list-header {
        flex-direction: column;
        align-items: stretch;
        gap: 16px;
      }
    }
  `]
})
export class MasterProductListComponent implements OnInit {
  displayedColumns: string[] = ['name', 'sku', 'brand', 'status', 'actions'];
  dataSource = new MatTableDataSource<MasterProduct>();
  loading = false;
  
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  constructor(
    private productService: ProductService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadProducts();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  loadProducts(filters: ProductFilters = {}): void {
    this.loading = true;
    
    this.productService.getMasterProducts(filters).subscribe({
      next: (response) => {
        this.dataSource.data = response.content;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading products:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Error loading products',
          icon: 'error',
          confirmButtonText: 'OK'
        });
        this.loading = false;
      }
    });
  }

  onFiltersChange(filters: ProductFilters): void {
    this.loadProducts(filters);
  }

  deleteProduct(product: MasterProduct): void {
    Swal.fire({
      title: 'Are you sure?',
      text: `Do you want to delete "${product.name}"? This action cannot be undone.`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, delete it!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.productService.deleteMasterProduct(product.id).subscribe({
          next: () => {
            Swal.fire({
              title: 'Deleted!',
              text: 'Product deleted successfully',
              icon: 'success',
              confirmButtonText: 'OK'
            });
            this.loadProducts();
          },
          error: (error) => {
            console.error('Error deleting product:', error);
            Swal.fire({
              title: 'Error!',
              text: 'Error deleting product',
              icon: 'error',
              confirmButtonText: 'OK'
            });
          }
        });
      }
    });
  }
}