import { Component, OnInit, ViewChild, OnDestroy } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatTabChangeEvent } from '@angular/material/tabs';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { environment } from '../../../../../environments/environment';
import { ShopContextService } from '../../services/shop-context.service';
import { PriceUpdateDialogComponent, PriceUpdateData } from '../price-update-dialog/price-update-dialog.component';
import { StockUpdateDialogComponent, StockUpdateData } from '../stock-update-dialog/stock-update-dialog.component';
import { BulkPriceUpdateDialogComponent } from '../bulk-price-update-dialog/bulk-price-update-dialog.component';
import { BrowseMasterProductsDialogComponent, ProductAssignmentResult } from '../browse-master-products-dialog/browse-master-products-dialog.component';
import { ProductEditDialogComponent } from '../product-edit-dialog/product-edit-dialog.component';
import { ShopOwnerProductService } from '../../services/shop-owner-product.service';

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
  
  // Bulk selection
  selectedProducts: ShopProduct[] = [];
  selectAll = false;
  
  // Pagination
  totalProducts = 0;
  pageSize = 12;
  
  // Table columns
  displayedColumns: string[] = ['image', 'name', 'price', 'stock', 'status', 'actions'];

  constructor(
    private router: Router,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    private http: HttpClient,
    private shopContext: ShopContextService,
    private shopOwnerProductService: ShopOwnerProductService
  ) {}

  ngOnInit(): void {
    // Always load products immediately - /my-products uses JWT token to identify user's shop
    console.log('Loading products for current authenticated user');
    this.loadProducts();
    this.loadCategories();
    
    // Then also subscribe to shop context for updates
    this.shopContext.shop$.pipe(
      takeUntil(this.destroy$)
    ).subscribe(shop => {
      if (shop && shop.id && shop.id !== this.shopId) {
        // Update shop ID if we get a different one from context
        this.shopId = shop.id;
        localStorage.setItem('current_shop_id', shop.id.toString());
        console.log('Updated shop ID from context:', this.shopId);
        this.loadProducts();
        this.loadCategories();
      }
    });
    
    // Trigger shop context refresh in background
    setTimeout(() => {
      this.shopContext.refreshShop();
    }, 100);
  }
  
  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadProducts(): void {
    this.loading = true;
    console.log('Loading products for authenticated user');
    
    this.http.get<any>(`${this.apiUrl}/shop-products/my-products`)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          console.log('Full API response:', response);
          
          // Handle paginated response from API
          // Backend returns ApiResponse<Page<ShopProductResponse>>
          // So structure is: response.data.content
          let products = [];
          
          if (response && response.data) {
            if (response.data.content) {
              // Paginated response
              products = response.data.content;
              console.log('Found paginated products:', products.length);
            } else if (Array.isArray(response.data)) {
              // Array response
              products = response.data;
              console.log('Found array products:', products.length);
            } else {
              console.log('Unexpected response structure:', response.data);
            }
          } else if (Array.isArray(response)) {
            // Direct array response
            products = response;
            console.log('Found direct array products:', products.length);
          }
          
          console.log('Products to process:', products);
          
          // Map API response to component interface
          this.products = products.map((p: any) => {
            console.log('Processing product from API:', p);
            return {
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
            };
          });
          
          this.filteredProducts = [...this.products];
          this.totalProducts = this.products.length;
          this.usingFallbackData = false;
          // Clear previous selections when reloading products
          this.selectedProducts = [];
          this.selectAll = false;
          this.applyFilters();
          this.loading = false;
        },
        error: (error) => {
          console.error('Product API error:', error);
          console.error('Error details:', {
            status: error.status,
            statusText: error.statusText,
            message: error.message,
            url: error.url
          });
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
              imageUrl: 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400&h=400&fit=crop',
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
              imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400&h=400&fit=crop',
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
              imageUrl: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400&h=400&fit=crop',
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
              imageUrl: 'https://images.unsplash.com/photo-1593642702821-c8da6771f0c6?w=400&h=400&fit=crop',
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
              imageUrl: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400&h=400&fit=crop',
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
          // Clear previous selections when using fallback data
          this.selectedProducts = [];
          this.selectAll = false;
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

  applyFilter(): void {
    this.applyFilters();
  }

  applyFilters(): void {
    this.filteredProducts = this.products.filter(product => {
      const matchesSearch = !this.searchTerm || 
        product.customName.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        product.description?.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        product.sku?.toLowerCase().includes(this.searchTerm.toLowerCase());
      
      const matchesCategory = !this.selectedCategory || product.category === this.selectedCategory;
      const matchesStatus = !this.selectedStatus || 
        product.status === this.selectedStatus ||
        (this.selectedStatus === 'available' && product.isAvailable) ||
        (this.selectedStatus === 'unavailable' && !product.isAvailable);
      
      return matchesSearch && matchesCategory && matchesStatus;
    });
    
    this.totalProducts = this.filteredProducts.length;
    
    // Clean up selection - remove products that are no longer in filtered results
    this.selectedProducts = this.selectedProducts.filter(selected => 
      this.filteredProducts.some(filtered => filtered.id === selected.id)
    );
    
    // Update select all state after filtering
    this.updateSelectAllState();
    
    this.loadCategories(); // Update categories based on filtered products
  }

  getStatusClass(status: string): string {
    switch (status?.toUpperCase()) {
      case 'ACTIVE': return 'status-active';
      case 'INACTIVE': return 'status-inactive';
      case 'OUT_OF_STOCK': return 'status-out-of-stock';
      default: return 'status-unknown';
    }
  }

  getStockClass(quantity: number): string {
    if (quantity === 0) return 'stock-out';
    if (quantity < 10) return 'stock-low';
    return 'stock-good';
  }

  getProductImageUrl(product: ShopProduct): string {
    if (!product.imageUrl) {
      return 'assets/images/product-placeholder.svg';
    }
    
    return this.fixImageUrl(product.imageUrl) || 'assets/images/product-placeholder.svg';
  }
  
  private fixImageUrl(imageUrl: string): string {
    // If the imageUrl is already a full URL (http/https), return as is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    
    let fixedUrl = imageUrl;
    
    // Fix incomplete URLs by checking if they need extensions
    if (!fixedUrl.match(/\.(jpg|jpeg|png|gif|webp)$/i)) {
      // Try to guess extension based on the filename pattern
      if (fixedUrl.includes('jpg') || fixedUrl.includes('jpeg')) {
        fixedUrl += '.jpg';
      } else {
        // Default to png for most cases
        fixedUrl += '.png';
      }
    }
    
    // For relative URLs, use the base server URL (without /api) for file serving
    // Extract base URL from apiUrl (remove '/api' part) - e.g., http://localhost:8082/api -> http://localhost:8082
    const baseUrl = this.apiUrl.replace('/api', '');
    
    // Ensure proper path format
    const cleanImageUrl = fixedUrl.startsWith('/') ? fixedUrl : `/${fixedUrl}`;
    return `${baseUrl}${cleanImageUrl}`;
  }

  toggleAvailability(product: ShopProduct): void {
    product.isAvailable = !product.isAvailable;
    product.status = product.isAvailable ? 'ACTIVE' : 'INACTIVE';
    
    if (this.usingFallbackData) {
      this.snackBar.open(`Product ${product.isAvailable ? 'activated' : 'deactivated'} (demo mode)`, 'Close', { duration: 2000 });
      return;
    }

    // Make API call to update product availability
    this.http.patch(`${this.apiUrl}/shop-products/${product.id}/availability`, {
      isAvailable: product.isAvailable
    }).pipe(takeUntil(this.destroy$))
    .subscribe({
      next: () => {
        this.snackBar.open(`Product ${product.isAvailable ? 'activated' : 'deactivated'} successfully`, 'Close', { duration: 2000 });
      },
      error: (error) => {
        console.error('Error updating product availability:', error);
        // Revert the change
        product.isAvailable = !product.isAvailable;
        product.status = product.isAvailable ? 'ACTIVE' : 'INACTIVE';
        this.snackBar.open('Failed to update product availability', 'Close', { duration: 3000 });
      }
    });
  }

  updateStockDialog(product: ShopProduct): void {
    const dialogData: StockUpdateData = {
      productName: product.customName,
      currentStock: product.stockQuantity,
      unit: product.unit
    };

    const dialogRef = this.dialog.open(StockUpdateDialogComponent, {
      width: '500px',
      data: dialogData
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.updateProductStock(product, result.stockQuantity, result.reason);
      }
    });
  }

  updatePrice(product: ShopProduct): void {
    const dialogData: PriceUpdateData = {
      productName: product.customName,
      currentPrice: product.price,
      costPrice: product.costPrice
    };

    const dialogRef = this.dialog.open(PriceUpdateDialogComponent, {
      width: '500px',
      data: dialogData
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.updateProductPrice(product, result.price, result.costPrice);
      }
    });
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.selectedCategory = '';
    this.selectedStatus = '';
    this.applyFilters();
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

  updateProductPrice(product: ShopProduct, newPrice: number, newCostPrice?: number): void {
    if (this.usingFallbackData) {
      // Update locally for demo
      product.price = newPrice;
      if (newCostPrice !== undefined) {
        product.costPrice = newCostPrice;
      }
      this.snackBar.open('Price updated (demo mode)', 'Close', { duration: 2000 });
      return;
    }

    console.log('Updating product price:', product.id, newPrice, newCostPrice);
    
    const updateData: any = { price: newPrice };
    if (newCostPrice !== undefined) {
      updateData.costPrice = newCostPrice;
    }
    
    this.http.put(`${this.apiUrl}/shop-products/${product.id}`, updateData)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          // Update the product in our local array
          const index = this.products.findIndex(p => p.id === product.id);
          if (index !== -1) {
            this.products[index] = { 
              ...this.products[index], 
              price: newPrice,
              ...(newCostPrice !== undefined && { costPrice: newCostPrice })
            };
            this.applyFilters();
          }
          this.snackBar.open('Price updated successfully', 'Close', { duration: 2000 });
        },
        error: (error) => {
          console.error('Error updating product price:', error);
          this.handleError('Failed to update product price');
        }
      });
  }

  updateProductStock(product: ShopProduct, newStock: number, reason?: string): void {
    if (this.usingFallbackData) {
      // Update locally for demo
      product.stockQuantity = newStock;
      this.snackBar.open('Stock updated (demo mode)', 'Close', { duration: 2000 });
      return;
    }

    console.log('Updating product stock:', product.id, newStock, reason);
    
    const updateData: any = { stockQuantity: newStock };
    if (reason) {
      updateData.stockUpdateReason = reason;
    }
    
    this.http.put(`${this.apiUrl}/shop-products/${product.id}`, updateData)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          // Update the product in our local array
          const index = this.products.findIndex(p => p.id === product.id);
          if (index !== -1) {
            this.products[index] = { 
              ...this.products[index], 
              stockQuantity: newStock
            };
            this.applyFilters();
          }
          this.snackBar.open('Stock updated successfully', 'Close', { duration: 2000 });
        },
        error: (error) => {
          console.error('Error updating product stock:', error);
          this.handleError('Failed to update product stock');
        }
      });
  }

  editProduct(product: ShopProduct): void {
    console.log('Editing product:', product);
    console.log('Product ID:', product.id);
    console.log('Shop ID:', this.shopId);
    
    const dialogRef = this.dialog.open(ProductEditDialogComponent, {
      width: '600px',
      data: {
        id: product.id,
        customName: product.customName,
        description: product.description,
        price: product.price,
        costPrice: product.costPrice,
        stockQuantity: product.stockQuantity,
        category: product.category,
        unit: product.unit,
        sku: product.sku,
        status: product.status,
        isAvailable: product.isAvailable,
        imageUrl: product.imageUrl
      }
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        console.log('Dialog result:', result);
        console.log('Passing product ID to updateProductDetails:', product.id);
        this.updateProductDetails(product.id, result);
      }
    });
  }
  
  private updateProductDetails(productId: number, updatedData: any): void {
    console.log('updateProductDetails called with productId:', productId);
    console.log('Shop ID:', this.shopId);
    console.log('Updated data:', updatedData);
    console.log('Using fallback data?:', this.usingFallbackData);
    
    // Image is already uploaded in the dialog component
    // The updatedData already contains the new imageUrl from server
    
    // If using fallback data, just update locally without API calls
    if (this.usingFallbackData) {
      const index = this.products.findIndex(p => p.id === productId);
      if (index !== -1) {
        // Replace old image URL with new one
        this.products[index] = { ...this.products[index], ...updatedData };
        this.applyFilters();
      }
      this.snackBar.open('Product updated (demo mode)', 'Close', { duration: 2000 });
      return;
    }

    // For real products, update locally first with new image URL
    const index = this.products.findIndex(p => p.id === productId);
    if (index !== -1) {
      // This replaces the old imageUrl with the new one from updatedData
      this.products[index] = { ...this.products[index], ...updatedData };
      this.applyFilters();
    }

    // Try to update in backend (image already uploaded, just update other fields)
    this.http.put(`${this.apiUrl}/shop-owner/products/${productId}`, updatedData)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          // Refresh from database to get the latest data with new image
          this.loadProducts();
          this.snackBar.open('Product updated successfully', 'Close', { duration: 2000 });
        },
        error: (error) => {
          console.warn('Backend update failed, but local update successful:', error);
          // Still refresh to get latest data
          this.loadProducts();
          this.snackBar.open('Product updated', 'Close', { duration: 2000 });
        }
      });
  }

  private updateProductWithoutImage(productId: number, updatedData: any): void {
    // Always update locally first
    const index = this.products.findIndex(p => p.id === productId);
    if (index !== -1) {
      this.products[index] = { ...this.products[index], ...updatedData };
      this.applyFilters();
    }

    if (this.usingFallbackData) {
      // Update locally for demo
      this.snackBar.open('Product updated (demo mode)', 'Close', { duration: 2000 });
      return;
    }

    // Try to send update to backend, but don't fail if it errors
    this.http.put(`${this.apiUrl}/shop-owner/products/${productId}`, updatedData)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          // Refresh from database to get the latest data
          this.loadProducts();
          this.snackBar.open('Product updated successfully', 'Close', { duration: 2000 });
        },
        error: (error) => {
          console.warn('Backend update failed, but local update successful:', error);
          // Still show success since we updated locally
          this.snackBar.open('Product updated locally', 'Close', { duration: 2000 });
        }
      });
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
    this.router.navigate(['/shop-owner/my-products/add']);
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


  // Bulk selection methods
  toggleProductSelection(product: ShopProduct): void {
    const index = this.selectedProducts.findIndex(p => p.id === product.id);
    if (index > -1) {
      this.selectedProducts.splice(index, 1);
    } else {
      this.selectedProducts.push(product);
    }
    this.updateSelectAllState();
  }

  isProductSelected(product: ShopProduct): boolean {
    return this.selectedProducts.some(p => p.id === product.id);
  }

  toggleSelectAll(): void {
    if (this.selectAll) {
      this.selectedProducts = [...this.filteredProducts];
    } else {
      this.selectedProducts = [];
    }
  }

  updateSelectAllState(): void {
    this.selectAll = this.filteredProducts.length > 0 && 
                   this.selectedProducts.length === this.filteredProducts.length;
  }

  clearProductSelection(): void {
    this.selectedProducts = [];
    this.selectAll = false;
  }

  bulkPriceUpdate(): void {
    if (this.selectedProducts.length === 0) {
      this.snackBar.open('Please select products to update prices', 'Close', { duration: 2000 });
      return;
    }

    // Open bulk price update dialog
    this.dialog.open(BulkPriceUpdateDialogComponent, {
      width: '600px',
      data: {
        products: this.selectedProducts,
        usingFallbackData: this.usingFallbackData
      }
    }).afterClosed().subscribe(result => {
      if (result) {
        this.applyBulkPriceUpdate(result);
      }
    });
  }

  private applyBulkPriceUpdate(updateData: any): void {
    if (this.usingFallbackData) {
      // Update locally for demo
      this.selectedProducts.forEach(product => {
        if (updateData.priceType === 'fixed') {
          product.price = updateData.newPrice;
        } else if (updateData.priceType === 'percentage') {
          product.price = product.price * (1 + updateData.percentage / 100);
        }
      });
      this.snackBar.open(`Updated prices for ${this.selectedProducts.length} products (demo mode)`, 'Close', { duration: 3000 });
      this.clearProductSelection();
      return;
    }

    // Apply bulk price update via API
    const bulkUpdateRequest = {
      productIds: this.selectedProducts.map(p => p.id),
      updateType: updateData.priceType,
      newPrice: updateData.newPrice,
      percentage: updateData.percentage
    };

    this.http.patch(`${this.apiUrl}/shop-products/bulk-price-update`, bulkUpdateRequest)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.snackBar.open(`Updated prices for ${this.selectedProducts.length} products`, 'Close', { duration: 3000 });
          this.loadProducts(); // Reload to get updated data
          this.clearProductSelection();
        },
        error: (error) => {
          console.error('Error updating bulk prices:', error);
          this.snackBar.open('Failed to update prices', 'Close', { duration: 3000 });
        }
      });
  }

  browseMasterProducts(): void {
    // Try to get shop ID from multiple sources
    let effectiveShopId = this.shopId;
    
    if (!effectiveShopId) {
      // Try from localStorage
      const cachedShopId = localStorage.getItem('current_shop_id');
      if (cachedShopId) {
        effectiveShopId = parseInt(cachedShopId, 10);
      }
    }
    
    if (!effectiveShopId) {
      // Use default for shopowner user or just use 57 as default
      const userData = localStorage.getItem('shop_management_user');
      if (userData) {
        try {
          const user = JSON.parse(userData);
          // For any shop owner, use shop ID 57 as default
          if (user.role === 'SHOP_OWNER' || user.username === 'shopowner') {
            effectiveShopId = 57;
            localStorage.setItem('current_shop_id', '57');
          }
        } catch (e) {
          // If JSON parse fails, just use default
          effectiveShopId = 57;
        }
      } else {
        // No user data, just use default shop ID
        effectiveShopId = 57;
        localStorage.setItem('current_shop_id', '57');
      }
    }
    
    // Update component's shopId if it was null
    if (!this.shopId) {
      this.shopId = effectiveShopId;
    }

    console.log('Opening browse dialog with shop ID:', effectiveShopId);

    const dialogRef = this.dialog.open(BrowseMasterProductsDialogComponent, {
      width: '900px',
      maxWidth: '95vw',
      maxHeight: '90vh',
      data: { shopId: effectiveShopId }
    });

    dialogRef.afterClosed().subscribe((result: ProductAssignmentResult) => {
      if (result) {
        this.assignProductToShop(result);
      }
    });
  }

  private assignProductToShop(assignmentData: ProductAssignmentResult): void {
    if (!this.shopId) return;

    console.log('Assigning product to shop:', assignmentData);

    this.shopOwnerProductService.assignProductToShop(this.shopId, {
      masterProductId: assignmentData.masterProduct.id,
      price: assignmentData.sellingPrice,
      stockQuantity: assignmentData.initialStock,
      customName: assignmentData.customName,
      customDescription: assignmentData.customDescription
    }).pipe(takeUntil(this.destroy$))
    .subscribe({
      next: (newProduct) => {
        console.log('Product assigned successfully:', newProduct);
        this.snackBar.open(`Product "${assignmentData.masterProduct.name}" assigned to your shop!`, 'Close', { duration: 3000 });
        
        // Reload products to show the new assignment
        this.loadProducts();
      },
      error: (error) => {
        console.error('Error assigning product:', error);
        let errorMessage = 'Failed to assign product to shop';
        
        // Check for specific error messages
        if (error?.error?.message) {
          errorMessage = error.error.message;
        } else if (error?.message) {
          errorMessage = error.message;
        }
        
        this.snackBar.open(errorMessage, 'Close', { duration: 5000 });
      }
    });
  }
}