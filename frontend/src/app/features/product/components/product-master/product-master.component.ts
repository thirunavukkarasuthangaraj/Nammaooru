import { Component } from '@angular/core';

@Component({
  selector: 'app-product-master',
  template: `
    <div class="product-master-container">
      <router-outlet></router-outlet>
    </div>
  `,
  styles: [`
    .product-master-container {
      min-height: 100vh;
      background: #f5f5f7;
    }
  `]
})
export class ProductMasterComponent {}