import { Component, OnInit, AfterViewInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatSnackBar } from '@angular/material/snack-bar';
import { ShopOwnerProductService } from '../../services/shop-owner-product.service';

interface ProductPricing {
  id: number;
  masterId: string;
  name: string;
  category: string;
  unit: string;
  price: number;
  marketAverage: number;
  stock: number;
  bulkShopsCount: number;
  totalBulkStock: number;
  isActive: boolean;
  lastUpdated: Date;
}

@Component({
  selector: 'app-products-pricing',
  templateUrl: './products-pricing.component.html',
  styleUrls: ['./products-pricing.component.scss']
})
export class ProductsPricingComponent implements OnInit, AfterViewInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  displayedColumns: string[] = ['name', 'stock', 'price', 'status', 'actions'];
  dataSource = new MatTableDataSource<ProductPricing>([]);
  
  products: ProductPricing[] = [];
  filteredProducts: ProductPricing[] = [];
  loading = false;
  syncing = false;

  searchTerm = '';
  searchQuery = '';
  selectedCategory = 'all';
  stockFilter = 'all';
  
  // Statistics properties
  totalProducts = 0;
  availableProducts = 0;
  lowStockProducts = 0;
  outOfStockProducts = 0;

  // Summary metrics
  belowMarketCount = 0;
  aboveMarketCount = 0;
  lowStockCount = 0;
  activeCount = 0;

  constructor(
    private productService: ShopOwnerProductService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadProducts();
  }

  ngAfterViewInit() {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  loadProducts(): void {
    this.loading = true;
    
    // Get shop ID from user data
    const shopId = this.getShopId();
    
    // Load real products from backend
    this.productService.getShopProducts(shopId).subscribe({
      next: (products: any) => {
        this.products = this.transformProducts(products);
        this.applyFilter();
        this.calculateMetrics();
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading products:', error);
        // Fallback to some default products if API fails
        const fallbackProducts = [
          {
            id: 1,
            name: 'Tomatoes',
            category: 'Vegetables',
            unit: 'kg',
            price: 40,
            stock: 25,
            marketAverage: 45,
            isActive: true,
            updatedAt: new Date().toISOString()
          }
        ];
        this.products = this.transformProducts(fallbackProducts);
        this.applyFilter();
        this.calculateMetrics();
        this.loading = false;
      }
    });
  }

  private getShopId(): number {
    // First try to get from current_shop_id (set during login for shop owners)
    const storedShopId = localStorage.getItem('current_shop_id');
    if (storedShopId) {
      const shopId = parseInt(storedShopId, 10);
      if (!isNaN(shopId) && shopId > 0) {
        return shopId;
      }
    }

    // Fallback: try user data
    const user = localStorage.getItem('shop_management_user') || localStorage.getItem('currentUser');
    if (user) {
      try {
        const userData = JSON.parse(user);
        if (userData.shopId && userData.shopId > 0) {
          return userData.shopId;
        }
      } catch (e) {
        console.error('Error parsing user data:', e);
      }
    }

    console.error('No valid shop ID found for current user!');
    return 0;
  }

  transformProducts(data: any[]): ProductPricing[] {
    // Handle both array and single product responses
    const productArray = Array.isArray(data) ? data : [data];
    
    // Transform backend data to match our interface
    return productArray.map(item => ({
      id: item.id,
      masterId: item.masterProductId || item.masterId || `PROD_${item.id}`,
      name: item.customName || item.name || 'Product',
      category: item.category || 'General',
      unit: item.unit || 'piece',
      price: item.price || 0,
      marketAverage: item.marketPrice || item.marketAverage || (item.price * 1.1),
      stock: item.stockQuantity || item.stock || 0,
      bulkShopsCount: item.bulkShopsCount || 0,
      totalBulkStock: item.totalBulkStock || 0,
      isActive: item.isAvailable !== false && item.status === 'ACTIVE',
      lastUpdated: new Date(item.updatedAt || item.createdAt || Date.now())
    }));
  }

  applyFilter(): void {
    let filtered = [...this.products];

    // Search filter
    if (this.searchTerm) {
      const search = this.searchTerm.toLowerCase();
      filtered = filtered.filter(p => 
        p.name.toLowerCase().includes(search) ||
        p.masterId.toLowerCase().includes(search) ||
        p.category.toLowerCase().includes(search)
      );
    }

    // Category filter
    if (this.selectedCategory !== 'all') {
      filtered = filtered.filter(p => p.category.toLowerCase() === this.selectedCategory);
    }

    // Stock filter
    if (this.stockFilter === 'in-stock') {
      filtered = filtered.filter(p => p.stock > 10);
    } else if (this.stockFilter === 'low-stock') {
      filtered = filtered.filter(p => p.stock > 0 && p.stock <= 10);
    } else if (this.stockFilter === 'out-of-stock') {
      filtered = filtered.filter(p => p.stock === 0);
    }

    this.filteredProducts = filtered;
    this.dataSource.data = filtered;
  }

  calculateMetrics(): void {
    this.totalProducts = this.products.length;
    this.availableProducts = this.products.filter(p => p.isActive && p.stock > 0).length;
    this.lowStockProducts = this.products.filter(p => p.stock <= 10 && p.stock > 0).length;
    this.outOfStockProducts = this.products.filter(p => p.stock === 0).length;
    
    this.belowMarketCount = this.products.filter(p => p.price < p.marketAverage).length;
    this.aboveMarketCount = this.products.filter(p => p.price > p.marketAverage).length;
    this.lowStockCount = this.products.filter(p => p.stock <= 10 && p.stock > 0).length;
    this.activeCount = this.products.filter(p => p.isActive).length;
  }

  updatePrice(product: ProductPricing): void {
    // Show dialog to get new price
    const newPrice = prompt(`Enter new price for ${product.name}:`, product.price.toString());
    
    if (newPrice && !isNaN(Number(newPrice))) {
      const price = Number(newPrice);
      
      // Update the local product first for immediate UI feedback
      product.price = price;
      
      this.productService.updatePrice(product.id, price).subscribe({
        next: () => {
          this.snackBar.open('Price updated successfully', 'Close', { 
            duration: 2000,
            panelClass: 'success-snackbar'
          });
          this.calculateMetrics();
        },
        error: (error: any) => {
          console.error('Error updating price:', error);
          // Revert the price if update fails
          this.loadProducts();
          this.snackBar.open('Failed to update price', 'Close', { duration: 3000 });
        }
      });
    }
  }

  updateStock(product: ProductPricing): void {
    // Show dialog to get new stock quantity
    const newStock = prompt(`Enter new stock quantity for ${product.name}:`, product.stock.toString());
    
    if (newStock && !isNaN(Number(newStock))) {
      const stockQuantity = Number(newStock);
      
      // Update the local product first for immediate UI feedback
      product.stock = stockQuantity;
      
      const stockUpdate = {
        productId: product.id,
        newQuantity: stockQuantity,
        reason: 'Manual update',
        notes: 'Updated from pricing screen'
      };
      
      this.productService.updateStock(stockUpdate).subscribe({
        next: () => {
          this.snackBar.open('Stock updated successfully', 'Close', { 
            duration: 2000,
            panelClass: 'success-snackbar'
          });
          this.calculateMetrics();
        },
        error: (error: any) => {
          console.error('Error updating stock:', error);
          // Revert the stock if update fails
          this.loadProducts();
          this.snackBar.open('Failed to update stock', 'Close', { duration: 3000 });
        }
      });
    }
  }

  toggleProductStatus(product: ProductPricing): void {
    this.productService.toggleProductStatus(product.id).subscribe({
      next: () => {
        this.snackBar.open(
          product.isActive ? 'Product activated' : 'Product deactivated', 
          'Close', 
          { duration: 2000 }
        );
        this.calculateMetrics();
      },
      error: (error: any) => {
        console.error('Error toggling product status:', error);
        product.isActive = !product.isActive; // Revert
        this.snackBar.open('Failed to update product status', 'Close', { duration: 3000 });
      }
    });
  }

  syncPrices(): void {
    this.syncing = true;
    // Simulate sync - in real app, would call a sync API
    setTimeout(() => {
      this.snackBar.open('Market prices synced successfully', 'Close', { 
        duration: 3000,
        panelClass: 'success-snackbar'
      });
      this.loadProducts(); // Reload with updated prices
      this.syncing = false;
    }, 2000);
  }

  getProductIcon(category: string): string {
    const icons: { [key: string]: string } = {
      'dairy': 'egg',
      'vegetables': 'eco',
      'fruits': 'apple',
      'grains': 'grain',
      'bakery': 'bakery_dining',
      'beverages': 'local_drink',
      'meat': 'kebab_dining',
      'seafood': 'set_meal',
      'snacks': 'cookie',
      'frozen': 'ac_unit'
    };
    return icons[category.toLowerCase()] || 'inventory';
  }

  getPriceComparison(product: ProductPricing): string {
    const diff = ((product.price - product.marketAverage) / product.marketAverage * 100);
    if (Math.abs(diff) < 1) return 'At market';
    return `${Math.abs(diff).toFixed(0)}% ${diff < 0 ? 'below' : 'above'}`;
  }

  getStockIcon(stock: number): string {
    if (stock === 0) return 'error';
    if (stock <= 10) return 'warning';
    return 'check_circle';
  }

  viewDetails(product: ProductPricing): void {
    console.log('View details for:', product);
    // Implement view details modal
  }

  viewPriceHistory(product: ProductPricing): void {
    console.log('View price history for:', product);
    // Implement price history modal
  }

  compareWithOthers(product: ProductPricing): void {
    console.log('Compare prices for:', product);
    // Implement price comparison modal
  }

  addNewProduct(): void {
    console.log('Add new product');
    // Implement add new product dialog
  }

  getStockClass(stockQuantity: number): string {
    if (stockQuantity === 0) return 'out-of-stock';
    if (stockQuantity <= 10) return 'low-stock';
    return 'in-stock';
  }

  toggleAvailability(product: any): void {
    console.log('Toggle availability for:', product);
    // Implement toggle availability
  }

  editProduct(product: any): void {
    console.log('Edit product:', product);
    // Implement edit product dialog
  }

  viewAnalytics(product: any): void {
    console.log('View analytics for:', product);
    // Implement analytics view
  }

  deleteProduct(product: any): void {
    console.log('Delete product:', product);
    // Implement delete confirmation dialog
  }
}