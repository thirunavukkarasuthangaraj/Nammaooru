import { Component, OnInit, ViewChild } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Router } from '@angular/router';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';

@Component({
  selector: 'app-add-product-modern',
  template: `
    <div class="product-add-container">
      <!-- Modern Header with Gradient -->
      <div class="header-section">
        <button mat-icon-button class="back-btn" (click)="goBack()">
          <mat-icon>arrow_back</mat-icon>
        </button>
        <div class="header-content">
          <h1>Add Product to Your Store</h1>
          <p>Search from catalog or create new listing</p>
        </div>
      </div>

      <!-- Quick Add Section - Like Swiggy -->
      <div class="quick-add-section" *ngIf="!selectedProduct">
        <h3>Quick Add</h3>
        <div class="quick-add-pills">
          <div class="pill-item" *ngFor="let item of recentProducts" (click)="selectProduct(item)">
            <img [src]="item.image || 'assets/images/default-product.png'" [alt]="item.name">
            <span>{{ item.name }}</span>
            <mat-icon>add_circle</mat-icon>
          </div>
        </div>
      </div>

      <!-- Search Section - Modern Like Zomato -->
      <div class="search-section" *ngIf="!selectedProduct">
        <div class="search-container">
          <mat-icon class="search-icon">search</mat-icon>
          <input 
            type="text" 
            placeholder="Search by product name, SKU or scan barcode"
            [(ngModel)]="searchQuery"
            (ngModelChange)="onSearchChange()"
            class="search-input">
          <button mat-icon-button class="scan-btn" (click)="openScanner()">
            <mat-icon>qr_code_scanner</mat-icon>
          </button>
        </div>

        <!-- Search Filters - Like Swiggy -->
        <div class="filter-chips">
          <mat-chip-list>
            <mat-chip [selected]="selectedCategory === 'all'" (click)="filterCategory('all')">
              All Products
            </mat-chip>
            <mat-chip [selected]="selectedCategory === 'grocery'" (click)="filterCategory('grocery')">
              <mat-icon>shopping_basket</mat-icon> Grocery
            </mat-chip>
            <mat-chip [selected]="selectedCategory === 'dairy'" (click)="filterCategory('dairy')">
              <mat-icon>egg</mat-icon> Dairy
            </mat-chip>
            <mat-chip [selected]="selectedCategory === 'vegetables'" (click)="filterCategory('vegetables')">
              <mat-icon>eco</mat-icon> Vegetables
            </mat-chip>
            <mat-chip [selected]="selectedCategory === 'beverages'" (click)="filterCategory('beverages')">
              <mat-icon>local_cafe</mat-icon> Beverages
            </mat-chip>
          </mat-chip-list>
        </div>
      </div>

      <!-- Search Results - Card Grid Like Swiggy -->
      <div class="search-results" *ngIf="searchResults.length > 0 && !selectedProduct">
        <div class="results-header">
          <h3>{{ searchResults.length }} Products Found</h3>
          <button mat-button class="green-button" (click)="requestNewProduct()">
            <mat-icon>add</mat-icon> Request New Product
          </button>
        </div>

        <div class="product-grid">
          <div class="product-card" *ngFor="let product of searchResults" (click)="selectProduct(product)">
            <div class="product-image">
              <img [src]="product.image || 'assets/images/default-product.png'" [alt]="product.name">
              <span class="sku-badge">{{ product.sku }}</span>
            </div>
            <div class="product-info">
              <h4>{{ product.name }}</h4>
              <p class="product-brand">{{ product.brand }}</p>
              <div class="product-meta">
                <span class="unit">{{ product.baseUnit }}</span>
                <span class="category">{{ product.category }}</span>
              </div>
              <button mat-raised-button class="select-btn green-button-raised">
                <mat-icon>add</mat-icon> Add to Store
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Selected Product Configuration - Modern Form -->
      <div class="configuration-section" *ngIf="selectedProduct">
        <div class="selected-product-header">
          <div class="product-preview">
            <img [src]="selectedProduct.image || 'assets/images/default-product.png'" 
                 [alt]="selectedProduct.name">
            <div class="product-details">
              <h2>{{ selectedProduct.name }}</h2>
              <p>{{ selectedProduct.brand }} • SKU: {{ selectedProduct.sku }}</p>
              <div class="tags">
                <span class="tag">{{ selectedProduct.category }}</span>
                <span class="tag">{{ selectedProduct.baseUnit }}</span>
              </div>
            </div>
          </div>
          <button mat-button (click)="changeProduct()">
            <mat-icon>swap_horiz</mat-icon> Change Product
          </button>
        </div>

        <form [formGroup]="productForm" class="modern-form">
          <!-- Pricing Section -->
          <div class="form-section pricing-section">
            <h3>
              <mat-icon>sell</mat-icon>
              Pricing & Offers
            </h3>
            
            <div class="price-inputs">
              <div class="price-field main-price">
                <label>Selling Price</label>
                <div class="price-input-group">
                  <span class="currency">₹</span>
                  <input type="number" formControlName="price" placeholder="0.00">
                </div>
                <mat-error *ngIf="productForm.get('price')?.invalid">Required</mat-error>
              </div>

              <div class="price-field">
                <label>MRP (Optional)</label>
                <div class="price-input-group">
                  <span class="currency">₹</span>
                  <input type="number" formControlName="originalPrice" placeholder="0.00">
                </div>
                <span class="discount-badge" *ngIf="calculateDiscount() > 0">
                  {{ calculateDiscount() }}% OFF
                </span>
              </div>

              <div class="price-field">
                <label>Cost Price (Optional)</label>
                <div class="price-input-group">
                  <span class="currency">₹</span>
                  <input type="number" formControlName="costPrice" placeholder="0.00">
                </div>
                <span class="margin-info" *ngIf="calculateMargin() > 0">
                  Margin: {{ calculateMargin() }}%
                </span>
              </div>
            </div>
          </div>

          <!-- Inventory Section -->
          <div class="form-section inventory-section">
            <h3>
              <mat-icon>inventory_2</mat-icon>
              Inventory Management
            </h3>

            <div class="inventory-controls">
              <div class="stock-field">
                <label>Current Stock</label>
                <div class="stock-input">
                  <button mat-icon-button (click)="decrementStock()">
                    <mat-icon>remove_circle</mat-icon>
                  </button>
                  <input type="number" formControlName="stockQuantity" min="0">
                  <button mat-icon-button (click)="incrementStock()">
                    <mat-icon>add_circle</mat-icon>
                  </button>
                </div>
              </div>

              <div class="stock-field">
                <label>Min Stock Alert</label>
                <input type="number" formControlName="minStockLevel" placeholder="10">
              </div>

              <div class="toggle-field">
                <mat-slide-toggle formControlName="trackInventory">
                  Track Inventory
                </mat-slide-toggle>
                <span class="helper-text">Get alerts when stock is low</span>
              </div>
            </div>
          </div>

          <!-- Customization Section -->
          <div class="form-section custom-section">
            <h3>
              <mat-icon>edit</mat-icon>
              Store Customization (Optional)
            </h3>

            <mat-form-field appearance="outline" class="full-width">
              <mat-label>Custom Product Name</mat-label>
              <input matInput formControlName="customName"
                     placeholder="e.g., Premium {{ selectedProduct.name }}">
              <mat-hint>Display name in your store (optional)</mat-hint>
            </mat-form-field>

            <mat-form-field appearance="outline" class="full-width">
              <mat-label>Custom Description</mat-label>
              <textarea matInput formControlName="customDescription" rows="3"
                       placeholder="Add your own product description"></textarea>
            </mat-form-field>

            <div class="toggle-field">
              <mat-slide-toggle formControlName="isFeatured">
                <mat-icon>star</mat-icon> Feature this product
              </mat-slide-toggle>
              <span class="helper-text">Show in featured section</span>
            </div>
          </div>

          <!-- Barcodes Section -->
          <div class="form-section">
            <h3>
              <mat-icon>qr_code</mat-icon>
              Product Barcodes
            </h3>

            <mat-form-field appearance="outline" class="full-width">
              <mat-label>Barcode 1 *</mat-label>
              <input matInput formControlName="barcode1" placeholder="Enter primary barcode (required)">
              <mat-icon matPrefix>qr_code</mat-icon>
              <mat-error *ngIf="productForm.get('barcode1')?.hasError('required')">
                Barcode 1 is required
              </mat-error>
            </mat-form-field>

            <mat-form-field appearance="outline" class="full-width">
              <mat-label>Barcode 2</mat-label>
              <input matInput formControlName="barcode2" placeholder="Enter secondary barcode (optional)">
              <mat-icon matPrefix>qr_code</mat-icon>
              <mat-hint>Optional: Different packaging or supplier code</mat-hint>
            </mat-form-field>

            <mat-form-field appearance="outline" class="full-width">
              <mat-label>Barcode 3</mat-label>
              <input matInput formControlName="barcode3" placeholder="Enter tertiary barcode (optional)">
              <mat-icon matPrefix>qr_code</mat-icon>
              <mat-hint>Optional: Additional barcode</mat-hint>
            </mat-form-field>
          </div>

          <!-- Action Buttons -->
          <div class="form-actions">
            <button mat-button type="button" (click)="cancel()" class="cancel-btn">
              Cancel
            </button>
            <button mat-raised-button class="draft-button" type="button" (click)="saveAsDraft()">
              <mat-icon>save_as</mat-icon> Save as Draft
            </button>
            <button mat-raised-button class="save-button" type="submit" 
                    (click)="saveProduct()" [disabled]="productForm.invalid || saving">
              <mat-spinner *ngIf="saving" diameter="20"></mat-spinner>
              <mat-icon *ngIf="!saving">check_circle</mat-icon>
              Add to Store
            </button>
          </div>
        </form>
      </div>

      <!-- Empty State -->
      <div class="empty-state" *ngIf="searchQuery && searchResults.length === 0 && !searching">
        <img src="assets/images/no-products.svg" alt="No products">
        <h3>No products found for "{{ searchQuery }}"</h3>
        <p>Try different keywords or request a new product</p>
        <button mat-raised-button color="primary" (click)="requestNewProduct()">
          <mat-icon>add</mat-icon> Request New Product
        </button>
      </div>

      <!-- Loading State -->
      <div class="loading-state" *ngIf="searching">
        <mat-spinner></mat-spinner>
        <p>Searching products...</p>
      </div>
    </div>
  `,
  styles: [`
    .product-add-container {
      min-height: 100vh;
      background: #f8f9fa;
    }

    /* Header Section */
    .header-section {
      background: linear-gradient(135deg, #43a047 0%, #66bb6a 50%, #81c784 100%);
      color: white;
      padding: 24px;
      display: flex;
      align-items: center;
      gap: 16px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.1);
    }

    .back-btn {
      color: white;
    }

    .header-content h1 {
      margin: 0;
      font-size: 1.75rem;
      font-weight: 600;
    }

    .header-content p {
      margin: 4px 0 0;
      opacity: 0.9;
    }

    /* Quick Add Section */
    .quick-add-section {
      background: white;
      padding: 24px;
      margin: 16px;
      border-radius: 16px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.05);
    }

    .quick-add-section h3 {
      margin: 0 0 16px;
      font-size: 1.25rem;
      font-weight: 600;
    }

    .quick-add-pills {
      display: flex;
      gap: 12px;
      overflow-x: auto;
      padding-bottom: 8px;
    }

    .pill-item {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px 16px;
      background: #f1f3f5;
      border-radius: 24px;
      cursor: pointer;
      white-space: nowrap;
      transition: all 0.3s;
      min-width: fit-content;
    }

    .pill-item:hover {
      background: #e8f5e9;
      transform: translateY(-2px);
    }

    .pill-item img {
      width: 24px;
      height: 24px;
      border-radius: 50%;
      object-fit: cover;
    }

    .pill-item mat-icon {
      color: #4caf50;
      font-size: 18px;
      width: 18px;
      height: 18px;
    }

    /* Search Section */
    .search-section {
      background: white;
      padding: 24px;
      margin: 16px;
      border-radius: 16px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.05);
    }

    .search-container {
      display: flex;
      align-items: center;
      background: #f8f9fa;
      border-radius: 12px;
      padding: 4px 16px;
      border: 2px solid transparent;
      transition: all 0.3s;
    }

    .search-container:focus-within {
      border-color: #66bb6a;
      box-shadow: 0 0 0 3px rgba(102, 187, 106, 0.15);
    }

    .search-icon {
      color: #9e9e9e;
      margin-right: 12px;
    }

    .search-input {
      flex: 1;
      border: none;
      background: none;
      padding: 14px 0;
      font-size: 1rem;
      outline: none;
    }

    .scan-btn {
      color: #66bb6a;
    }

    /* Filter Chips */
    .filter-chips {
      margin-top: 16px;
    }

    .filter-chips mat-chip {
      font-weight: 500;
      cursor: pointer;
      transition: all 0.3s;
    }

    .filter-chips mat-chip[selected] {
      background: #66bb6a !important;
      color: white !important;
    }

    .filter-chips mat-icon {
      font-size: 18px;
      width: 18px;
      height: 18px;
      margin-right: 4px;
    }

    /* Search Results Grid */
    .search-results {
      padding: 0 16px 16px;
    }

    .results-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 16px;
      padding: 0 8px;
    }

    .results-header h3 {
      margin: 0;
      font-size: 1.1rem;
      color: #495057;
    }

    .product-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
      gap: 16px;
    }

    .product-card {
      background: white;
      border-radius: 12px;
      overflow: hidden;
      cursor: pointer;
      transition: all 0.3s;
      box-shadow: 0 2px 8px rgba(0,0,0,0.08);
    }

    .product-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 8px 24px rgba(0,0,0,0.12);
    }

    .product-image {
      position: relative;
      aspect-ratio: 1;
      background: #f8f9fa;
    }

    .product-image img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    .sku-badge {
      position: absolute;
      top: 8px;
      right: 8px;
      background: rgba(0,0,0,0.7);
      color: white;
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 0.75rem;
      font-weight: 600;
    }

    .product-info {
      padding: 12px;
    }

    .product-info h4 {
      margin: 0 0 4px;
      font-size: 0.95rem;
      font-weight: 600;
      color: #212529;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .product-brand {
      margin: 0 0 8px;
      font-size: 0.85rem;
      color: #6c757d;
    }

    .product-meta {
      display: flex;
      gap: 8px;
      margin-bottom: 12px;
    }

    .product-meta span {
      font-size: 0.75rem;
      padding: 2px 6px;
      background: #f1f3f5;
      border-radius: 4px;
      color: #495057;
    }

    .select-btn {
      width: 100%;
      font-weight: 500;
    }

    /* Configuration Section */
    .configuration-section {
      padding: 16px;
    }

    .selected-product-header {
      background: white;
      padding: 20px;
      border-radius: 16px;
      margin-bottom: 16px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      box-shadow: 0 2px 10px rgba(0,0,0,0.05);
    }

    .product-preview {
      display: flex;
      gap: 16px;
      align-items: center;
    }

    .product-preview img {
      width: 80px;
      height: 80px;
      border-radius: 12px;
      object-fit: cover;
      border: 2px solid #e9ecef;
    }

    .product-details h2 {
      margin: 0 0 4px;
      font-size: 1.35rem;
      font-weight: 600;
    }

    .product-details p {
      margin: 0 0 8px;
      color: #6c757d;
    }

    .tags {
      display: flex;
      gap: 8px;
    }

    .tag {
      padding: 4px 10px;
      background: #e8f5e9;
      color: #2e7d32;
      border-radius: 6px;
      font-size: 0.85rem;
      font-weight: 500;
    }

    /* Modern Form */
    .modern-form {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .form-section {
      background: white;
      padding: 24px;
      border-radius: 16px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.05);
    }

    .form-section h3 {
      margin: 0 0 20px;
      font-size: 1.15rem;
      font-weight: 600;
      color: #212529;
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .form-section h3 mat-icon {
      color: #66bb6a;
    }

    /* Pricing Section */
    .price-inputs {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 20px;
    }

    .price-field {
      position: relative;
    }

    .price-field label {
      display: block;
      margin-bottom: 8px;
      font-size: 0.9rem;
      font-weight: 500;
      color: #495057;
    }

    .price-input-group {
      display: flex;
      align-items: center;
      background: #f8f9fa;
      border-radius: 8px;
      border: 2px solid #e9ecef;
      overflow: hidden;
      transition: all 0.3s;
    }

    .price-input-group:focus-within {
      border-color: #66bb6a;
      box-shadow: 0 0 0 3px rgba(102, 187, 106, 0.15);
    }

    .currency {
      padding: 0 12px;
      background: #e9ecef;
      color: #495057;
      font-weight: 600;
      font-size: 1.1rem;
    }

    .price-input-group input {
      flex: 1;
      border: none;
      background: none;
      padding: 12px;
      font-size: 1.1rem;
      font-weight: 600;
      outline: none;
    }

    .main-price .price-input-group {
      background: #f1f8e9;
      border-color: #8bc34a;
    }

    .main-price .currency {
      background: #8bc34a;
      color: white;
    }

    .discount-badge {
      position: absolute;
      top: 0;
      right: 0;
      background: #4caf50;
      color: white;
      padding: 2px 8px;
      border-radius: 4px;
      font-size: 0.75rem;
      font-weight: 600;
    }

    .margin-info {
      display: block;
      margin-top: 4px;
      font-size: 0.85rem;
      color: #4caf50;
      font-weight: 500;
    }

    /* Inventory Section */
    .inventory-controls {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 20px;
      align-items: end;
    }

    .stock-field label {
      display: block;
      margin-bottom: 8px;
      font-size: 0.9rem;
      font-weight: 500;
      color: #495057;
    }

    .stock-input {
      display: flex;
      align-items: center;
      background: #f8f9fa;
      border-radius: 8px;
      border: 2px solid #e9ecef;
      overflow: hidden;
    }

    .stock-input input {
      flex: 1;
      border: none;
      background: none;
      padding: 8px;
      text-align: center;
      font-size: 1.1rem;
      font-weight: 600;
      outline: none;
      width: 80px;
    }

    .stock-input button {
      color: #6c757d;
    }

    .stock-input button:hover {
      color: #66bb6a;
    }

    .toggle-field {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 12px;
      background: #f8f9fa;
      border-radius: 8px;
    }

    .helper-text {
      font-size: 0.85rem;
      color: #6c757d;
    }

    /* Form Actions */
    .form-actions {
      display: flex;
      justify-content: flex-end;
      gap: 12px;
      padding: 24px;
      background: white;
      border-radius: 16px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.05);
    }

    .cancel-btn {
      color: #6c757d;
    }

    .form-actions button {
      font-weight: 500;
      padding: 10px 24px;
    }

    /* Empty State */
    .empty-state {
      text-align: center;
      padding: 60px 24px;
      background: white;
      border-radius: 16px;
      margin: 16px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.05);
    }

    .empty-state img {
      width: 200px;
      margin-bottom: 24px;
    }

    .empty-state h3 {
      margin: 0 0 8px;
      font-size: 1.35rem;
      color: #212529;
    }

    .empty-state p {
      margin: 0 0 24px;
      color: #6c757d;
    }

    /* Loading State */
    .loading-state {
      text-align: center;
      padding: 60px;
      background: white;
      border-radius: 16px;
      margin: 16px;
    }

    .loading-state p {
      margin-top: 16px;
      color: #6c757d;
    }

    /* Responsive */
    @media (max-width: 768px) {
      .product-grid {
        grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
      }

      .selected-product-header {
        flex-direction: column;
        gap: 16px;
        align-items: flex-start;
      }

      .form-actions {
        flex-direction: column;
      }

      .form-actions button {
        width: 100%;
      }
    }

    /* Material Overrides */
    ::ng-deep .mat-form-field-appearance-outline .mat-form-field-wrapper {
      margin: 0;
    }

    ::ng-deep .mat-form-field-appearance-outline .mat-form-field-flex {
      padding: 0 14px;
    }

    ::ng-deep mat-spinner {
      display: inline-block;
      margin-right: 8px;
    }

    /* Green Theme Buttons */
    .green-button {
      color: #66bb6a !important;
    }

    .green-button:hover {
      background: rgba(102, 187, 106, 0.1);
    }

    .green-button-raised,
    .select-btn {
      background: #66bb6a !important;
      color: white !important;
    }

    .green-button-raised:hover,
    .select-btn:hover {
      background: #4caf50 !important;
      box-shadow: 0 4px 12px rgba(76, 175, 80, 0.3);
    }

    .save-button {
      background: #66bb6a !important;
      color: white !important;
    }

    .save-button:hover:not(:disabled) {
      background: #4caf50 !important;
      box-shadow: 0 4px 12px rgba(76, 175, 80, 0.3);
    }

    .save-button:disabled {
      background: #c8e6c9 !important;
      color: rgba(255, 255, 255, 0.7) !important;
    }

    .draft-button {
      background: #81c784 !important;
      color: white !important;
    }

    .draft-button:hover {
      background: #66bb6a !important;
    }
  `]
})
export class AddProductModernComponent implements OnInit {
  searchQuery = '';
  searchResults: any[] = [];
  selectedProduct: any = null;
  productForm!: FormGroup;
  searching = false;
  saving = false;
  selectedCategory = 'all';
  
  recentProducts = [
    { id: 1, name: 'Amul Milk', sku: 'MILK-AMU-500', image: 'assets/products/milk.jpg' },
    { id: 2, name: 'Basmati Rice', sku: 'RICE-BAS-001', image: 'assets/products/rice.jpg' },
    { id: 3, name: 'Tomatoes', sku: 'VEG-TOM-1KG', image: 'assets/products/tomato.jpg' }
  ];

  constructor(
    private fb: FormBuilder,
    private snackBar: MatSnackBar,
    private router: Router
  ) {
    this.initForm();
  }

  ngOnInit(): void {
    // Load recent/popular products
    this.loadRecentProducts();
  }

  initForm(): void {
    this.productForm = this.fb.group({
      price: ['', [Validators.required, Validators.min(0)]],
      originalPrice: [''],
      costPrice: [''],
      stockQuantity: [0, [Validators.required, Validators.min(0)]],
      minStockLevel: [10],
      trackInventory: [true],
      customName: [''],
      customDescription: [''],
      isFeatured: [false],
      // Shop-level multiple barcodes (barcode1 is required)
      barcode1: ['', [Validators.required]],
      barcode2: [''],
      barcode3: ['']
    });
  }

  onSearchChange(): void {
    if (this.searchQuery.length < 2) {
      this.searchResults = [];
      return;
    }

    this.searching = true;
    // Simulate API call
    setTimeout(() => {
      this.searchResults = this.getMockSearchResults();
      this.searching = false;
    }, 500);
  }

  getMockSearchResults(): any[] {
    // This would be replaced with actual API call
    return [
      {
        id: 1,
        sku: 'MILK-AMU-500',
        name: 'Amul Milk 500ml',
        brand: 'Amul',
        category: 'Dairy',
        baseUnit: '500ml',
        image: 'assets/products/milk.jpg'
      },
      {
        id: 2,
        sku: 'RICE-BAS-001',
        name: 'Basmati Rice 1kg',
        brand: 'India Gate',
        category: 'Grocery',
        baseUnit: '1kg',
        image: 'assets/products/rice.jpg'
      }
    ];
  }

  selectProduct(product: any): void {
    this.selectedProduct = product;
    this.searchResults = [];
    
    // Pre-fill some default values
    this.productForm.patchValue({
      stockQuantity: 0,
      trackInventory: true,
      minStockLevel: 10
    });
  }

  changeProduct(): void {
    this.selectedProduct = null;
    this.productForm.reset();
  }

  filterCategory(category: string): void {
    this.selectedCategory = category;
    this.onSearchChange();
  }

  incrementStock(): void {
    const current = this.productForm.get('stockQuantity')?.value || 0;
    this.productForm.patchValue({ stockQuantity: current + 1 });
  }

  decrementStock(): void {
    const current = this.productForm.get('stockQuantity')?.value || 0;
    if (current > 0) {
      this.productForm.patchValue({ stockQuantity: current - 1 });
    }
  }

  calculateDiscount(): number {
    const price = this.productForm.get('price')?.value;
    const originalPrice = this.productForm.get('originalPrice')?.value;
    
    if (originalPrice && price && originalPrice > price) {
      return Math.round(((originalPrice - price) / originalPrice) * 100);
    }
    return 0;
  }

  calculateMargin(): number {
    const price = this.productForm.get('price')?.value;
    const costPrice = this.productForm.get('costPrice')?.value;
    
    if (costPrice && price && price > costPrice) {
      return Math.round(((price - costPrice) / costPrice) * 100);
    }
    return 0;
  }

  openScanner(): void {
    this.snackBar.open('Barcode scanner opening...', 'Close', { duration: 2000 });
    // Implement barcode scanner
  }

  requestNewProduct(): void {
    this.snackBar.open('Requesting new product from admin...', 'Close', { duration: 2000 });
    // Navigate to request form
  }

  loadRecentProducts(): void {
    // Load from API
  }

  saveAsDraft(): void {
    if (this.selectedProduct) {
      this.saving = true;
      // Save as draft API call
      setTimeout(() => {
        this.saving = false;
        this.snackBar.open('Saved as draft', 'Close', { duration: 2000 });
      }, 1000);
    }
  }

  saveProduct(): void {
    if (this.productForm.valid && this.selectedProduct) {
      this.saving = true;
      
      const payload = {
        masterProductId: this.selectedProduct.id,
        ...this.productForm.value
      };
      
      // API call to save product
      setTimeout(() => {
        this.saving = false;
        this.snackBar.open('Product added to your store!', 'Close', { 
          duration: 3000,
          panelClass: ['success-snackbar']
        });
        this.router.navigate(['/shop-owner/products']);
      }, 1500);
    }
  }

  cancel(): void {
    this.router.navigate(['/shop-owner/products']);
  }

  goBack(): void {
    this.router.navigate(['/shop-owner/products']);
  }
}