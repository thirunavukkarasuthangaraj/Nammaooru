import { Component } from '@angular/core';

@Component({
  selector: 'app-product-master',
  template: `
    <div class="product-master-container">
      <mat-toolbar color="primary" class="product-toolbar">
        <mat-icon>inventory</mat-icon>
        <span class="toolbar-spacer"></span>
        <h1>Product Management</h1>
        <span class="flex-spacer"></span>
        
        <button mat-icon-button [matMenuTriggerFor]="menu" matTooltip="Quick Actions">
          <mat-icon>more_vert</mat-icon>
        </button>
        
        <mat-menu #menu="matMenu">
          <button mat-menu-item routerLink="/products/master/new">
            <mat-icon>add</mat-icon>
            <span>New Master Product</span>
          </button>
          <button mat-menu-item routerLink="/products/categories/new">
            <mat-icon>category</mat-icon>
            <span>New Category</span>
          </button>
          <mat-divider></mat-divider>
          <button mat-menu-item routerLink="/products/categories">
            <mat-icon>account_tree</mat-icon>
            <span>Manage Categories</span>
          </button>
        </mat-menu>
      </mat-toolbar>

      <nav mat-tab-nav-bar class="product-nav" backgroundColor="primary">
        <a mat-tab-link 
           routerLink="/products/dashboard"
           routerLinkActive="active-link"
           [routerLinkActiveOptions]="{exact: true}">
          <mat-icon class="tab-icon">dashboard</mat-icon>
          Dashboard
        </a>
        
        <a mat-tab-link 
           routerLink="/products/master"
           routerLinkActive="active-link">
          <mat-icon class="tab-icon">inventory_2</mat-icon>
          Master Products
        </a>
        
        <a mat-tab-link 
           routerLink="/products/categories"
           routerLinkActive="active-link">
          <mat-icon class="tab-icon">category</mat-icon>
          Categories
        </a>
      </nav>

      <div class="product-content">
        <router-outlet></router-outlet>
      </div>
    </div>
  `,
  styles: [`
    .product-master-container {
      height: 100vh;
      display: flex;
      flex-direction: column;
    }

    .product-toolbar {
      flex-shrink: 0;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .toolbar-spacer {
      width: 16px;
    }

    .flex-spacer {
      flex: 1;
    }

    .product-nav {
      flex-shrink: 0;
      border-bottom: 1px solid rgba(0,0,0,0.1);
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
    }

    .product-nav a {
      color: rgba(255, 255, 255, 0.8) !important;
    }

    .product-nav a.active-link {
      color: white !important;
      background-color: rgba(255, 255, 255, 0.1);
    }

    .tab-icon {
      margin-right: 8px;
      font-size: 20px;
    }

    .active-link {
      opacity: 1 !important;
    }

    .product-content {
      flex: 1;
      overflow-y: auto;
      padding: 0;
      background-color: #fafafa;
    }

    @media (max-width: 768px) {
      .product-nav a {
        min-width: auto;
        padding: 0 12px;
      }
      
      .tab-icon {
        margin-right: 4px;
        font-size: 18px;
      }
    }
  `]
})
export class ProductMasterComponent {}