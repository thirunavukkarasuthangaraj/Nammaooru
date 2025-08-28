import { Component, OnInit, ViewChild, OnDestroy } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { environment } from '../../../../../environments/environment';
import { ShopContextService } from '../../services/shop-context.service';

interface ShopProduct {
  id: number;
  customName: string;
  description?: string;
  price: number;
  costPrice?: number;
  stockQuantity: number;
  isAvailable: boolean;
  status: string;
  imageUrl?: string;
  category?: string;
  unit?: string;
  sku?: string;
  masterProductId?: number;
  masterProductName?: string;
  createdAt: string;
  updatedAt: string;
}

@Component({
  selector: 'app-my-products',
  templateUrl: './my-products.component.html',
  styleUrls: ['./my-products.component.scss']
})
export class MyProductsComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  private apiUrl = environment.apiUrl;
  
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  // Product data
  products: ShopProduct[] = [];
  filteredProducts: ShopProduct[] = [];
  categories: string[] = [];
  loading = false;
  usingFallbackData = false;
  
  shopId: number | null = null;
  
  // Filter controls
  searchTerm = '';
  selectedCategory = '';
  selectedStatus = '';
  
  // Pagination
  totalProducts = 0;
  pageSize = 12;

  constructor(
    private router: Router,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    private http: HttpClient,
    private shopContext: ShopContextService
  ) {}

  ngOnInit(): void {
    // Wait for shop context to load
    this.shopContext.shop$.pipe(
      takeUntil(this.destroy$)
    ).subscribe(shop => {
      if (shop) {
        this.shopId = shop.id;
        this.loadProducts();
        this.loadCategories();
      }
    });
  }
  
  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadProducts(): void {
    if (!this.shopId) return;
    
    this.loading = true;
    console.log('Loading products for shop:', this.shopId);
    
    this.http.get<any>(`${this.apiUrl}/shop-products/my-products`)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          // Handle paginated response from API
          const data = response.data || response;
          const products = data.content || data || [];
          console.log('Products loaded from API:', products);
          
          // Map API response to component interface
          this.products = products.map((p: any) => ({
            id: p.id,
            customName: p.displayName || p.customName || p.masterProduct?.name,
            description: p.displayDescription || p.customDescription || p.masterProduct?.description,
            price: p.price,
            costPrice: p.costPrice,
            stockQuantity: p.stockQuantity,
            isAvailable: p.isAvailable,
            status: p.status,
            category: p.masterProduct?.category?.name,
            unit: p.masterProduct?.baseUnit,
            sku: p.masterProduct?.sku,
            imageUrl: p.primaryImageUrl,
            masterProductId: p.masterProduct?.id,
            masterProductName: p.masterProduct?.name,
            createdAt: p.createdAt,
            updatedAt: p.updatedAt
          }));
          
          this.filteredProducts = [...this.products];
          this.totalProducts = this.products.length;
          this.usingFallbackData = false;
          this.applyFilters();
          this.loading = false;
        },
        error: (error) => {
          console.error('Product API error:', error);
          console.warn('Using fallback product data due to API issues');
          
          // Fallback to sample products that match the real order items
          this.products = [
            {
              id: 50,
              customName: 'Coffee Beans Arabica',
              description: 'Premium roasted coffee beans',
              price: 999,
              costPrice: 750,
              stockQuantity: 15,
              isAvailable: true,
              status: 'ACTIVE',
              category: 'Food & Beverages',
              unit: 'kg',
              sku: 'COFFEE-ARB-001',
              createdAt: new Date().toISOString(),
              updatedAt: new Date().toISOString()
            },
            {
              id: 51,
              customName: 'Garden Soil Organic',
              description: 'Premium organic potting soil',
              price: 199,
              costPrice: 150,
              stockQuantity: 8,
              isAvailable: true,
              status: 'ACTIVE',
              category: 'Garden',
              unit: 'bag',
              sku: 'SOIL-ORG-001',
              createdAt: new Date().toISOString(),
              updatedAt: new Date().toISOString()
            },
            {
              id: 49,
              customName: "Levi's Jeans 501",
              description: 'Classic straight fit denim jeans',
              price: 2999,
              costPrice: 2000,
              stockQuantity: 25,
              isAvailable: true,
              status: 'ACTIVE',
              category: 'Clothing',
              unit: 'piece',
              sku: 'LEVI-501-001',
              createdAt: new Date().toISOString(),
              updatedAt: new Date().toISOString()
            },
            {
              id: 12,
              customName: 'Dell Laptop XPS 13',
              description: 'High-performance ultrabook for professionals',
              price: 85000,
              costPrice: 75000,
              stockQuantity: 3,
              isAvailable: true,
              status: 'ACTIVE',
              category: 'Electronics',
              unit: 'piece',
              sku: 'DELL-XPS13-001',
              createdAt: new Date().toISOString(),
              updatedAt: new Date().toISOString()
            },
            {
              id: 11,
              customName: 'Samsung Galaxy S24',
              description: 'Latest Samsung smartphone with advanced camera',
              price: 75000,
              costPrice: 65000,
              stockQuantity: 5,
              isAvailable: true,
              status: 'ACTIVE',
              category: 'Electronics',
              unit: 'piece',
              sku: 'SGS24-001',
              createdAt: new Date().toISOString(),
              updatedAt: new Date().toISOString()
            }
          ];
          
          this.filteredProducts = [...this.products];
          this.totalProducts = this.products.length;
          this.usingFallbackData = true;
          this.applyFilters();
          this.loading = false;
          
          this.snackBar.open('Products loaded (API unavailable - showing sample data)', 'Close', { 
            duration: 5000,
            panelClass: ['warning-snackbar']
          });
        }
      });
  }

  loadCategories(): void {
    // Extract unique categories from products
    this.categories = [...new Set(this.products.map(p => p.category).filter(Boolean) as string[])];
  }

  applyFilters(): void {
    this.filteredProducts = this.products.filter(product => {
      const matchesSearch = !this.searchTerm || 
        product.customName.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        product.description?.toLowerCase().includes(this.searchTerm.toLowerCase());
      
      const matchesCategory = !this.selectedCategory || product.category === this.selectedCategory;
      const matchesStatus = !this.selectedStatus || 
        (this.selectedStatus === 'available' && product.isAvailable) ||
        (this.selectedStatus === 'unavailable' && !product.isAvailable);
      
      return matchesSearch && matchesCategory && matchesStatus;
    });
    
    this.totalProducts = this.filteredProducts.length;
    this.loadCategories(); // Update categories based on filtered products
  }

  onSearchChange(event: any): void {
    this.searchTerm = event.target.value;
    this.applyFilters();
  }

  onCategoryChange(category: string): void {
    this.selectedCategory = category;
    this.applyFilters();
  }

  onStatusChange(status: string): void {
    this.selectedStatus = status;
    this.applyFilters();
  }

  updateProductStatus(product: ShopProduct, status: boolean): void {
    if (this.usingFallbackData) {
      // Update locally for demo
      product.isAvailable = status;
      this.snackBar.open(`Product ${status ? 'enabled' : 'disabled'} (demo mode)`, 'Close', { duration: 2000 });
      return;
    }

    console.log('Updating product status:', product.id, status);
    
    const updateData = { isAvailable: status };
    
    this.http.put(`${this.apiUrl}/shop-products/${product.id}`, updateData)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          // Update the product in our local array
          const index = this.products.findIndex(p => p.id === product.id);
          if (index !== -1) {
            this.products[index] = { ...this.products[index], isAvailable: status };
            this.applyFilters();
          }
          this.snackBar.open(`Product ${status ? 'enabled' : 'disabled'}`, 'Close', { duration: 2000 });
        },
        error: (error) => {
          console.error('Error updating product status:', error);
          // Revert the toggle
          product.isAvailable = !status;
          this.handleError('Failed to update product status');
        }
      });
  }

  updateProductPrice(product: ShopProduct, newPrice: number): void {
    if (this.usingFallbackData) {
      // Update locally for demo
      product.price = newPrice;
      this.snackBar.open('Price updated (demo mode)', 'Close', { duration: 2000 });
      return;
    }

    console.log('Updating product price:', product.id, newPrice);
    
    const updateData = { price: newPrice };
    
    this.http.put(`${this.apiUrl}/shop-products/${product.id}`, updateData)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          // Update the product in our local array
          const index = this.products.findIndex(p => p.id === product.id);
          if (index !== -1) {
            this.products[index] = { ...this.products[index], price: newPrice };
          }
          this.snackBar.open('Price updated successfully', 'Close', { duration: 2000 });
        },
        error: (error) => {
          console.error('Error updating product price:', error);
          this.handleError('Failed to update product price');
        }
      });
  }

  editProduct(product: ShopProduct): void {
    this.router.navigate(['/shop-owner/products/edit', product.id]);
  }

  deleteProduct(product: ShopProduct): void {
    if (this.usingFallbackData) {
      // Remove from local array for demo
      this.products = this.products.filter(p => p.id !== product.id);
      this.applyFilters();
      this.snackBar.open('Product deleted (demo mode)', 'Close', { duration: 2000 });
      return;
    }

    if (confirm(`Are you sure you want to delete ${product.customName}?`)) {
      console.log('Deleting product:', product.id);
      
      this.http.delete(`${this.apiUrl}/shop-products/${product.id}`)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: () => {
            console.log('Product deleted successfully');
            this.products = this.products.filter(p => p.id !== product.id);
            this.applyFilters();
            this.snackBar.open('Product deleted successfully', 'Close', { duration: 2000 });
          },
          error: (error) => {
            console.error('Error deleting product:', error);
            this.handleError('Failed to delete product');
          }
        });
    }
  }

  addNewProduct(): void {
    this.router.navigate(['/shop-owner/products/add']);
  }

  refreshProducts(): void {
    this.loadProducts();
    this.snackBar.open('Products refreshed', 'Close', { duration: 2000 });
  }
  
  private handleError(message: string): void {
    this.snackBar.open(message, 'Close', { 
      duration: 5000,
      panelClass: ['error-snackbar']
    });
  }
  
  formatCurrency(amount: number): string {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR'
    }).format(amount);
  }

  getStockStatusClass(quantity: number): string {
    if (quantity <= 5) return 'low-stock';
    if (quantity <= 10) return 'medium-stock';
    return 'high-stock';
  }

  getStockStatusText(quantity: number): string {
    if (quantity <= 5) return 'Low Stock';
    if (quantity <= 10) return 'Medium Stock';
    return 'In Stock';
  }

  bulkUpload(): void {
    this.snackBar.open('Bulk upload feature coming soon', 'Close', { duration: 2000 });
  }

  applyFilter(): void {
    this.applyFilters();
  }

  duplicateProduct(productId: number): void {
    this.snackBar.open('Duplicate product feature coming soon', 'Close', { duration: 2000 });
  }

  toggleProductStatus(productId: number): void {
    const product = this.products.find(p => p.id === productId);
    if (product) {
      this.updateProductStatus(product, !product.isAvailable);
    }
  }

  viewAnalytics(productId: number): void {
    this.snackBar.open('Product analytics feature coming soon', 'Close', { duration: 2000 });
  }

  updateStock(productId: number): void {
    this.snackBar.open('Update stock feature coming soon', 'Close', { duration: 2000 });
  }

  onPageChange(event: any): void {
    // Pagination logic would go here
    console.log('Page changed:', event);
  }
}