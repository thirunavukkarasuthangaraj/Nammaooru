const fs = require('fs');
const path = require('path');

// List of all components that need to be created
const components = [
  // Financial Management
  'financial-management/components/revenue-analytics/revenue-analytics',
  'financial-management/components/commission-management/commission-management',
  'financial-management/components/payout-management/payout-management',
  'financial-management/components/transaction-history/transaction-history',
  'financial-management/components/financial-reports/financial-reports',
  'financial-management/components/tax-management/tax-management',
  'financial-management/components/refund-management/refund-management',
  'financial-management/components/settlement-tracking/settlement-tracking',
  
  // Inventory Management
  'inventory-management/components/inventory-dashboard/inventory-dashboard',
  'inventory-management/components/product-catalog/product-catalog',
  'inventory-management/components/stock-management/stock-management',
  'inventory-management/components/inventory-alerts/inventory-alerts',
  'inventory-management/components/bulk-upload/bulk-upload',
  'inventory-management/components/product-form/product-form',
  'inventory-management/components/stock-adjustment/stock-adjustment',
  'inventory-management/components/inventory-reports/inventory-reports',
  'inventory-management/components/low-stock-alerts/low-stock-alerts',
  'inventory-management/components/category-management/category-management',
];

const basePath = './frontend/src/app/features/';

function createComponent(componentPath) {
  const fullPath = path.join(basePath, componentPath);
  const dir = path.dirname(fullPath);
  const fileName = path.basename(fullPath);
  const className = fileName.split('-').map(word => 
    word.charAt(0).toUpperCase() + word.slice(1)
  ).join('') + 'Component';
  
  // Create directory if it doesn't exist
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  
  // Create TypeScript file
  const tsContent = `import { Component } from '@angular/core';

@Component({
  selector: 'app-${fileName}',
  templateUrl: './${fileName}.component.html',
  styleUrls: ['./${fileName}.component.scss']
})
export class ${className} {
  constructor() {}
}`;
  
  // Create HTML file
  const htmlContent = `<div class="${fileName} chennai-dashboard">
  <mat-card class="chennai-card">
    <mat-card-header>
      <mat-card-title>${className.replace('Component', '')} Dashboard</mat-card-title>
    </mat-card-header>
    <mat-card-content>
      <p>This is the ${fileName} component.</p>
      <!-- Add your content here -->
    </mat-card-content>
  </mat-card>
</div>`;
  
  // Create SCSS file
  const scssContent = `.${fileName} {
  padding: var(--chennai-spacing-lg);
  
  .chennai-card {
    margin-bottom: var(--chennai-spacing-lg);
  }
}`;
  
  // Write files
  fs.writeFileSync(`${fullPath}.component.ts`, tsContent);
  fs.writeFileSync(`${fullPath}.component.html`, htmlContent);
  fs.writeFileSync(`${fullPath}.component.scss`, scssContent);
  
  console.log(`Created: ${componentPath}`);
}

// Create all components
components.forEach(createComponent);

console.log('All components created successfully!');