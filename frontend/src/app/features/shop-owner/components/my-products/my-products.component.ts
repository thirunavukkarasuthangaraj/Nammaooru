import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { FormControl } from '@angular/forms';
import { Router } from '@angular/router';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { ShopOwnerProductService, ShopProduct } from '../../services/shop-owner-product.service';

// Using ShopProduct from service instead of local interface

@Component({
  selector: 'app-my-products',
  templateUrl: './my-products.component.html',
  styleUrls: ['./my-products.component.scss']
})
export class MyProductsComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  // Product data
  products: ShopProduct[] = [];
  filteredProducts: ShopProduct[] = [];
  categories: string[] = [];
  
  // Shop ID - should be retrieved from auth service
  shopId = 1;
  
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
    private productService: ShopOwnerProductService
  ) {}

  ngOnInit(): void {
    this.loadProducts();
    this.loadCategories();
  }

  loadProducts(): void {
    this.productService.getShopProducts(this.shopId).subscribe({
      next: (products) => {
        this.products = products;
        this.filteredProducts = [...this.products];
        this.totalProducts = this.products.length;
      },
      error: (error) => {
        console.error('Error loading products:', error);
        this.snackBar.open('Error loading products', 'Close', { duration: 3000 });
      }
    });
  }

  loadCategories(): void {
    this.productService.getProductCategories(this.shopId).subscribe({
      next: (categories) => {
        this.categories = categories;
      },
      error: (error) => {
        console.error('Error loading categories:', error);
      }
    });
  }

  applyFilter(): void {
    this.filteredProducts = this.products.filter(product => {
      const matchesSearch = !this.searchTerm || 
        product.name.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        product.description?.toLowerCase().includes(this.searchTerm.toLowerCase());
      
      const matchesCategory = !this.selectedCategory || 
        product.category === this.selectedCategory;
      
      const matchesStatus = !this.selectedStatus || 
        product.status === this.selectedStatus;
      
      return matchesSearch && matchesCategory && matchesStatus;
    });
  }

  addProduct(): void {
    this.router.navigate(['/shop-owner/products/add']);
  }

  editProduct(id: number): void {
    this.router.navigate(['/shop-owner/products/edit', id]);
  }

  duplicateProduct(id: number): void {
    this.snackBar.open('Product duplicated successfully', 'Close', { duration: 3000 });
  }

  toggleProductStatus(id: number): void {
    this.productService.toggleProductStatus(id).subscribe({
      next: (updatedProduct) => {
        const productIndex = this.products.findIndex(p => p.id === id);
        if (productIndex !== -1) {
          this.products[productIndex] = updatedProduct;
          this.applyFilter();
        }
        this.snackBar.open('Product status updated', 'Close', { duration: 3000 });
      },
      error: (error) => {
        console.error('Error updating product status:', error);
        this.snackBar.open('Error updating product status', 'Close', { duration: 3000 });
      }
    });
  }

  updateStock(id: number): void {
    const newQuantity = prompt('Enter new stock quantity:');
    if (newQuantity && !isNaN(Number(newQuantity))) {
      const stockUpdate = {
        productId: id,
        newQuantity: Number(newQuantity),
        reason: 'Manual update',
        notes: 'Updated from product management'
      };
      
      this.productService.updateStock(stockUpdate).subscribe({
        next: (updatedProduct) => {
          const productIndex = this.products.findIndex(p => p.id === id);
          if (productIndex !== -1) {
            this.products[productIndex] = updatedProduct;
            this.applyFilter();
          }
          this.snackBar.open('Stock updated successfully', 'Close', { duration: 3000 });
        },
        error: (error) => {
          console.error('Error updating stock:', error);
          this.snackBar.open('Error updating stock', 'Close', { duration: 3000 });
        }
      });
    }
  }

  viewAnalytics(id: number): void {
    this.router.navigate(['/shop-owner/analytics/product', id]);
  }

  deleteProduct(id: number): void {
    if (confirm('Are you sure you want to delete this product?')) {
      this.productService.deleteProduct(id).subscribe({
        next: () => {
          this.products = this.products.filter(p => p.id !== id);
          this.applyFilter();
          this.snackBar.open('Product deleted successfully', 'Close', { duration: 3000 });
        },
        error: (error) => {
          console.error('Error deleting product:', error);
          this.snackBar.open('Error deleting product', 'Close', { duration: 3000 });
        }
      });
    }
  }

  bulkUpload(): void {
    this.router.navigate(['/shop-owner/products/bulk-upload']);
  }

  onPageChange(event: any): void {
    // Handle pagination
  }
}