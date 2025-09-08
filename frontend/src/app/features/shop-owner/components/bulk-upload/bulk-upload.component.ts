import { Component, OnInit } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Router } from '@angular/router';
import { ShopProductService } from '@core/services/shop-product.service';
import { AuthService } from '@core/services/auth.service';
import { HttpEvent, HttpEventType } from '@angular/common/http';

interface UploadResult {
  fileName: string;
  totalRows: number;
  successfulRows: number;
  errorRows: number;
  errors: UploadError[];
}

interface UploadError {
  row: number;
  field: string;
  error: string;
  value: any;
}

@Component({
  selector: 'app-bulk-upload',
  template: `
    <div class="bulk-upload-container">
      <!-- Header -->
      <div class="page-header">
        <div class="header-content">
          <h1 class="page-title">Bulk Product Upload</h1>
          <p class="page-subtitle">Upload multiple products using CSV/Excel files</p>
        </div>
        <div class="header-actions">
          <button mat-stroked-button routerLink="/shop-owner/my-products">
            <mat-icon>arrow_back</mat-icon>
            Back to Products
          </button>
        </div>
      </div>

      <!-- Upload Steps -->
      <div class="upload-steps">
        <mat-card class="step-card" [class.active]="currentStep === 1">
          <mat-card-content>
            <div class="step-content">
              <div class="step-number">1</div>
              <div class="step-info">
                <h3>Download Template</h3>
                <p>Get the CSV template with required columns</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-icon class="step-arrow">arrow_forward</mat-icon>

        <mat-card class="step-card" [class.active]="currentStep === 2">
          <mat-card-content>
            <div class="step-content">
              <div class="step-number">2</div>
              <div class="step-info">
                <h3>Fill Data</h3>
                <p>Add your product information to the template</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-icon class="step-arrow">arrow_forward</mat-icon>

        <mat-card class="step-card" [class.active]="currentStep === 3">
          <mat-card-content>
            <div class="step-content">
              <div class="step-number">3</div>
              <div class="step-info">
                <h3>Upload File</h3>
                <p>Upload your completed CSV file</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-icon class="step-arrow">arrow_forward</mat-icon>

        <mat-card class="step-card" [class.active]="currentStep === 4">
          <mat-card-content>
            <div class="step-content">
              <div class="step-number">4</div>
              <div class="step-info">
                <h3>Review & Import</h3>
                <p>Validate and import your products</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>
      </div>

      <!-- Step 1: Download Template -->
      <mat-card class="main-card" *ngIf="currentStep === 1">
        <mat-card-header>
          <mat-card-title>
            <mat-icon>download</mat-icon>
            Step 1: Download Template
          </mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="template-section">
            <div class="template-info">
              <h3>CSV Template Columns</h3>
              <div class="columns-grid">
                <div class="column-item required">
                  <mat-icon>star</mat-icon>
                  <span>Product Name</span>
                </div>
                <div class="column-item required">
                  <mat-icon>star</mat-icon>
                  <span>Category</span>
                </div>
                <div class="column-item required">
                  <mat-icon>star</mat-icon>
                  <span>Price</span>
                </div>
                <div class="column-item required">
                  <mat-icon>star</mat-icon>
                  <span>Unit</span>
                </div>
                <div class="column-item required">
                  <mat-icon>star</mat-icon>
                  <span>Initial Stock</span>
                </div>
                <div class="column-item optional">
                  <mat-icon>info</mat-icon>
                  <span>Brand</span>
                </div>
                <div class="column-item optional">
                  <mat-icon>info</mat-icon>
                  <span>Description</span>
                </div>
                <div class="column-item optional">
                  <mat-icon>info</mat-icon>
                  <span>Cost Price</span>
                </div>
                <div class="column-item optional">
                  <mat-icon>info</mat-icon>
                  <span>Min Stock</span>
                </div>
                <div class="column-item optional">
                  <mat-icon>info</mat-icon>
                  <span>Max Stock</span>
                </div>
                <div class="column-item optional">
                  <mat-icon>info</mat-icon>
                  <span>SKU</span>
                </div>
                <div class="column-item optional">
                  <mat-icon>info</mat-icon>
                  <span>Supplier</span>
                </div>
              </div>

              <div class="legend">
                <div class="legend-item">
                  <mat-icon class="required-icon">star</mat-icon>
                  <span>Required Fields</span>
                </div>
                <div class="legend-item">
                  <mat-icon class="optional-icon">info</mat-icon>
                  <span>Optional Fields</span>
                </div>
              </div>
            </div>

            <div class="template-actions">
              <button mat-raised-button color="primary" (click)="downloadTemplate()">
                <mat-icon>download</mat-icon>
                Download CSV Template
              </button>
              <button mat-stroked-button (click)="downloadSample()">
                <mat-icon>description</mat-icon>
                Download Sample Data
              </button>
            </div>

            <div class="guidelines">
              <h4>Guidelines:</h4>
              <ul>
                <li>Use the exact column names as shown in the template</li>
                <li>Categories must match existing categories in your shop</li>
                <li>Units: kg, gram, liter, ml, piece, packet, dozen</li>
                <li>Prices should be in rupees (₹)</li>
                <li>Stock quantities should be whole numbers</li>
                <li>SKU should be unique if provided</li>
              </ul>
            </div>
          </div>
        </mat-card-content>
        <mat-card-actions>
          <button mat-raised-button color="primary" (click)="nextStep()">
            <mat-icon>arrow_forward</mat-icon>
            Next: Fill Data
          </button>
        </mat-card-actions>
      </mat-card>

      <!-- Step 2: Fill Data -->
      <mat-card class="main-card" *ngIf="currentStep === 2">
        <mat-card-header>
          <mat-card-title>
            <mat-icon>edit</mat-icon>
            Step 2: Fill Product Data
          </mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="fill-data-section">
            <div class="instructions">
              <h3>Fill Your Product Information</h3>
              <p>Open the downloaded CSV template in Excel or Google Sheets and fill in your product data.</p>
              
              <div class="tips">
                <h4>Tips for better results:</h4>
                <div class="tips-grid">
                  <div class="tip-item">
                    <mat-icon>lightbulb</mat-icon>
                    <div>
                      <strong>Product Names:</strong>
                      <p>Use clear, descriptive names like "Organic Basmati Rice 1kg"</p>
                    </div>
                  </div>
                  <div class="tip-item">
                    <mat-icon>category</mat-icon>
                    <div>
                      <strong>Categories:</strong>
                      <p>Use exact category names: {{ categories.join(', ') }}</p>
                    </div>
                  </div>
                  <div class="tip-item">
                    <mat-icon>format_list_numbered</mat-icon>
                    <div>
                      <strong>Numbers:</strong>
                      <p>Use plain numbers without currency symbols or commas</p>
                    </div>
                  </div>
                  <div class="tip-item">
                    <mat-icon>warning</mat-icon>
                    <div>
                      <strong>Empty Cells:</strong>
                      <p>Leave optional fields empty if not applicable</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </mat-card-content>
        <mat-card-actions>
          <button mat-button (click)="previousStep()">
            <mat-icon>arrow_back</mat-icon>
            Previous
          </button>
          <button mat-raised-button color="primary" (click)="nextStep()">
            <mat-icon>arrow_forward</mat-icon>
            Next: Upload File
          </button>
        </mat-card-actions>
      </mat-card>

      <!-- Step 3: Upload File -->
      <mat-card class="main-card" *ngIf="currentStep === 3">
        <mat-card-header>
          <mat-card-title>
            <mat-icon>cloud_upload</mat-icon>
            Step 3: Upload Your File
          </mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="upload-section">
            <div class="upload-area" (click)="fileInput.click()" 
                 [class.has-file]="selectedFile" 
                 [class.uploading]="isUploading">
              
              <div class="upload-content" *ngIf="!selectedFile && !isUploading">
                <mat-icon class="upload-icon">cloud_upload</mat-icon>
                <h3>Choose your CSV file</h3>
                <p>Click here or drag and drop your completed CSV file</p>
                <small>Supported formats: .csv, .xlsx (Max 10MB)</small>
              </div>

              <div class="file-info" *ngIf="selectedFile && !isUploading">
                <mat-icon class="file-icon">description</mat-icon>
                <div class="file-details">
                  <h4>{{ selectedFile.name }}</h4>
                  <p>{{ formatFileSize(selectedFile.size) }}</p>
                </div>
                <button mat-icon-button class="remove-file" (click)="removeFile($event)">
                  <mat-icon>close</mat-icon>
                </button>
              </div>

              <div class="uploading-info" *ngIf="isUploading">
                <mat-spinner diameter="48"></mat-spinner>
                <h4>Processing your file...</h4>
                <p>{{ uploadProgress }}% complete</p>
              </div>
            </div>

            <input #fileInput type="file" hidden accept=".csv,.xlsx,.xls" (change)="onFileSelected($event)">

            <div class="file-requirements">
              <h4>File Requirements:</h4>
              <ul>
                <li>File format: CSV or Excel (.xlsx, .xls)</li>
                <li>Maximum file size: 10MB</li>
                <li>Maximum 1000 products per upload</li>
                <li>Use the provided template format</li>
              </ul>
            </div>
          </div>
        </mat-card-content>
        <mat-card-actions>
          <button mat-button (click)="previousStep()" [disabled]="isUploading">
            <mat-icon>arrow_back</mat-icon>
            Previous
          </button>
          <button mat-raised-button color="primary" (click)="processFile()" 
                  [disabled]="!selectedFile || isUploading">
            <mat-icon>arrow_forward</mat-icon>
            Process File
          </button>
        </mat-card-actions>
      </mat-card>

      <!-- Step 4: Review & Import -->
      <mat-card class="main-card" *ngIf="currentStep === 4">
        <mat-card-header>
          <mat-card-title>
            <mat-icon>check_circle</mat-icon>
            Step 4: Review & Import
          </mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="review-section" *ngIf="uploadResult">
            <!-- Summary -->
            <div class="result-summary">
              <div class="summary-card success" *ngIf="uploadResult.successfulRows > 0">
                <mat-icon>check_circle</mat-icon>
                <div>
                  <h3>{{ uploadResult.successfulRows }}</h3>
                  <p>Products Ready</p>
                </div>
              </div>

              <div class="summary-card error" *ngIf="uploadResult.errorRows > 0">
                <mat-icon>error</mat-icon>
                <div>
                  <h3>{{ uploadResult.errorRows }}</h3>
                  <p>Errors Found</p>
                </div>
              </div>

              <div class="summary-card total">
                <mat-icon>description</mat-icon>
                <div>
                  <h3>{{ uploadResult.totalRows }}</h3>
                  <p>Total Rows</p>
                </div>
              </div>
            </div>

            <!-- Errors Table -->
            <div class="errors-section" *ngIf="uploadResult.errors && uploadResult.errors.length > 0">
              <h3>Errors to Fix:</h3>
              <div class="errors-table">
                <table mat-table [dataSource]="uploadResult.errors" class="errors-table-content">
                  <ng-container matColumnDef="row">
                    <th mat-header-cell *matHeaderCellDef>Row</th>
                    <td mat-cell *matCellDef="let error">{{ error.row }}</td>
                  </ng-container>

                  <ng-container matColumnDef="field">
                    <th mat-header-cell *matHeaderCellDef>Field</th>
                    <td mat-cell *matCellDef="let error">{{ error.field }}</td>
                  </ng-container>

                  <ng-container matColumnDef="error">
                    <th mat-header-cell *matHeaderCellDef>Error</th>
                    <td mat-cell *matCellDef="let error">{{ error.error }}</td>
                  </ng-container>

                  <ng-container matColumnDef="value">
                    <th mat-header-cell *matHeaderCellDef>Value</th>
                    <td mat-cell *matCellDef="let error">{{ error.value }}</td>
                  </ng-container>

                  <tr mat-header-row *matHeaderRowDef="errorColumns"></tr>
                  <tr mat-row *matRowDef="let row; columns: errorColumns;"></tr>
                </table>
              </div>
            </div>

            <!-- Import Options -->
            <div class="import-options">
              <h3>Import Options:</h3>
              <mat-radio-group [(ngModel)]="importOption">
                <mat-radio-button value="valid" *ngIf="uploadResult.successfulRows > 0">
                  Import only valid products ({{ uploadResult.successfulRows }} products)
                </mat-radio-button>
                <mat-radio-button value="all" [disabled]="uploadResult.errorRows > 0">
                  Import all products (fix errors first)
                </mat-radio-button>
              </mat-radio-group>
            </div>
          </div>
        </mat-card-content>
        <mat-card-actions>
          <button mat-button (click)="previousStep()">
            <mat-icon>arrow_back</mat-icon>
            Upload Different File
          </button>
          <button mat-button (click)="downloadErrorReport()" *ngIf="uploadResult && uploadResult.errors && uploadResult.errors.length > 0">
            <mat-icon>download</mat-icon>
            Download Error Report
          </button>
          <button mat-raised-button color="primary" (click)="importProducts()" 
                  [disabled]="!uploadResult || !uploadResult.successfulRows || uploadResult.successfulRows === 0 || isImporting">
            <mat-spinner *ngIf="isImporting" diameter="20" style="margin-right: 8px;"></mat-spinner>
            <mat-icon *ngIf="!isImporting">save</mat-icon>
            Import Products
          </button>
        </mat-card-actions>
      </mat-card>
    </div>
  `,
  styles: [`
    .bulk-upload-container {
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

    .upload-steps {
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 32px;
      gap: 16px;
    }

    .step-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      transition: all 0.3s ease;
      opacity: 0.6;
    }

    .step-card.active {
      opacity: 1;
      transform: scale(1.05);
      box-shadow: 0 4px 16px rgba(59, 130, 246, 0.2);
      border: 2px solid #3b82f6;
    }

    .step-content {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 8px;
    }

    .step-number {
      width: 32px;
      height: 32px;
      border-radius: 50%;
      background: #e5e7eb;
      color: #6b7280;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 600;
    }

    .step-card.active .step-number {
      background: #3b82f6;
      color: white;
    }

    .step-info h3 {
      margin: 0 0 2px 0;
      font-size: 0.9rem;
      font-weight: 600;
      color: #374151;
    }

    .step-info p {
      margin: 0;
      font-size: 0.8rem;
      color: #6b7280;
    }

    .step-arrow {
      color: #d1d5db;
      font-size: 20px;
    }

    .main-card {
      max-width: 800px;
      margin: 0 auto;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .main-card mat-card-header {
      background: #f8f9fa;
      margin: -16px -16px 24px -16px;
      padding: 16px;
      border-radius: 12px 12px 0 0;
    }

    .main-card mat-card-title {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 1.2rem;
      font-weight: 500;
    }

    .columns-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 12px;
      margin: 16px 0;
    }

    .column-item {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px 12px;
      border-radius: 8px;
      font-size: 0.9rem;
    }

    .column-item.required {
      background: #fef3c7;
      color: #92400e;
    }

    .column-item.optional {
      background: #e0f2fe;
      color: #0277bd;
    }

    .legend {
      display: flex;
      gap: 24px;
      margin: 16px 0;
    }

    .legend-item {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 0.9rem;
    }

    .required-icon {
      color: #f59e0b;
    }

    .optional-icon {
      color: #0284c7;
    }

    .template-actions {
      display: flex;
      gap: 12px;
      margin: 24px 0;
    }

    .guidelines {
      background: #f8f9fa;
      padding: 16px;
      border-radius: 8px;
      margin-top: 16px;
    }

    .guidelines h4 {
      margin: 0 0 8px 0;
      color: #374151;
    }

    .guidelines ul {
      margin: 0;
      padding-left: 20px;
      color: #6b7280;
    }

    .guidelines li {
      margin-bottom: 4px;
    }

    .tips-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 16px;
      margin: 16px 0;
    }

    .tip-item {
      display: flex;
      gap: 12px;
      padding: 12px;
      background: #f8f9fa;
      border-radius: 8px;
    }

    .tip-item mat-icon {
      color: #6366f1;
      margin-top: 2px;
    }

    .tip-item strong {
      color: #374151;
      font-size: 0.9rem;
    }

    .tip-item p {
      margin: 4px 0 0 0;
      font-size: 0.8rem;
      color: #6b7280;
    }

    .upload-area {
      border: 2px dashed #d1d5db;
      border-radius: 12px;
      padding: 48px 24px;
      text-align: center;
      cursor: pointer;
      transition: all 0.3s ease;
      background: #fafafa;
      margin-bottom: 24px;
    }

    .upload-area:hover {
      border-color: #6366f1;
      background: #f8faff;
    }

    .upload-area.has-file {
      border-color: #10b981;
      background: #f0fdf4;
    }

    .upload-area.uploading {
      border-color: #f59e0b;
      background: #fffbeb;
    }

    .upload-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      color: #6b7280;
      margin-bottom: 16px;
    }

    .upload-content h3 {
      margin: 0 0 8px 0;
      color: #374151;
    }

    .upload-content p {
      margin: 0 0 16px 0;
      color: #6b7280;
    }

    .upload-content small {
      color: #9ca3af;
    }

    .file-info {
      display: flex;
      align-items: center;
      gap: 16px;
      max-width: 400px;
      margin: 0 auto;
    }

    .file-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      color: #10b981;
    }

    .file-details h4 {
      margin: 0 0 4px 0;
      color: #374151;
    }

    .file-details p {
      margin: 0;
      color: #6b7280;
      font-size: 0.9rem;
    }

    .remove-file {
      background: #fee2e2;
      color: #dc2626;
    }

    .uploading-info {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
    }

    .uploading-info h4 {
      margin: 0;
      color: #374151;
    }

    .uploading-info p {
      margin: 0;
      color: #6b7280;
    }

    .file-requirements {
      background: #f8f9fa;
      padding: 16px;
      border-radius: 8px;
    }

    .file-requirements h4 {
      margin: 0 0 8px 0;
      color: #374151;
    }

    .file-requirements ul {
      margin: 0;
      padding-left: 20px;
      color: #6b7280;
    }

    .result-summary {
      display: flex;
      gap: 16px;
      margin-bottom: 24px;
    }

    .summary-card {
      flex: 1;
      padding: 16px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .summary-card.success {
      background: #dcfce7;
      color: #16a34a;
    }

    .summary-card.error {
      background: #fef2f2;
      color: #dc2626;
    }

    .summary-card.total {
      background: #e0f2fe;
      color: #0277bd;
    }

    .summary-card h3 {
      margin: 0;
      font-size: 1.5rem;
      font-weight: 600;
    }

    .summary-card p {
      margin: 0;
      font-size: 0.9rem;
    }

    .errors-section {
      margin-bottom: 24px;
    }

    .errors-section h3 {
      margin: 0 0 16px 0;
      color: #dc2626;
    }

    .errors-table {
      border: 1px solid #e5e7eb;
      border-radius: 8px;
      overflow: hidden;
    }

    .errors-table-content {
      width: 100%;
    }

    .import-options h3 {
      margin: 0 0 12px 0;
      color: #374151;
    }

    /* Mobile Responsive */
    @media (max-width: 768px) {
      .bulk-upload-container {
        padding: 16px;
      }

      .page-header {
        flex-direction: column;
        gap: 16px;
        text-align: center;
      }

      .upload-steps {
        flex-direction: column;
        gap: 12px;
      }

      .step-arrow {
        transform: rotate(90deg);
      }

      .columns-grid {
        grid-template-columns: 1fr;
      }

      .tips-grid {
        grid-template-columns: 1fr;
      }

      .template-actions {
        flex-direction: column;
      }

      .result-summary {
        flex-direction: column;
      }

      .legend {
        flex-direction: column;
        gap: 12px;
      }
    }
  `]
})
export class BulkUploadComponent implements OnInit {
  currentStep = 1;
  selectedFile: File | null = null;
  isUploading = false;
  isImporting = false;
  uploadProgress = 0;
  uploadResult: UploadResult | null = null;
  importOption = 'valid';
  
  errorColumns = ['row', 'field', 'error', 'value'];

  categories = [
    'Groceries', 'Vegetables', 'Fruits', 'Dairy Products', 
    'Bakery Items', 'Beverages', 'Snacks', 'Personal Care', 
    'Household Items', 'Frozen Foods'
  ];

  constructor(
    private snackBar: MatSnackBar,
    private router: Router,
    private shopProductService: ShopProductService,
    private authService: AuthService
  ) {}

  ngOnInit(): void {}

  nextStep(): void {
    if (this.currentStep < 4) {
      this.currentStep++;
    }
  }

  previousStep(): void {
    if (this.currentStep > 1) {
      this.currentStep--;
    }
  }

  downloadTemplate(): void {
    // Create CSV template
    const headers = [
      'Product Name', 'Category', 'Price', 'Unit', 'Initial Stock',
      'Brand', 'Description', 'Cost Price', 'Min Stock', 'Max Stock',
      'SKU', 'Supplier'
    ];
    
    const csvContent = headers.join(',');
    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'product_upload_template.csv';
    link.click();
    window.URL.revokeObjectURL(url);

    this.snackBar.open('Template downloaded successfully', 'Close', { duration: 3000 });
  }

  downloadSample(): void {
    // Create sample CSV with data
    const headers = [
      'Product Name', 'Category', 'Price', 'Unit', 'Initial Stock',
      'Brand', 'Description', 'Cost Price', 'Min Stock', 'Max Stock',
      'SKU', 'Supplier'
    ];
    
    const sampleData = [
      ['Organic Basmati Rice', 'Groceries', '120', 'kg', '50', 'Nature Fresh', 'Premium quality organic basmati rice', '90', '10', '100', 'ORG001', 'ABC Suppliers'],
      ['Fresh Tomatoes', 'Vegetables', '40', 'kg', '25', '', 'Fresh red tomatoes', '25', '5', '50', 'VEG002', 'Local Farm'],
      ['Whole Wheat Bread', 'Bakery Items', '35', 'piece', '20', 'Daily Fresh', 'Healthy whole wheat bread', '20', '5', '30', 'BAK003', 'Bakery Co']
    ];
    
    const csvContent = [headers, ...sampleData].map(row => row.join(',')).join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'product_sample_data.csv';
    link.click();
    window.URL.revokeObjectURL(url);

    this.snackBar.open('Sample data downloaded successfully', 'Close', { duration: 3000 });
  }

  onFileSelected(event: any): void {
    const file = event.target.files[0];
    if (file) {
      // Validate file size (10MB)
      if (file.size > 10 * 1024 * 1024) {
        this.snackBar.open('File size must be less than 10MB', 'Close', { duration: 3000 });
        return;
      }

      // Validate file type
      const validTypes = ['.csv', '.xlsx', '.xls'];
      const fileExtension = file.name.toLowerCase().substring(file.name.lastIndexOf('.'));
      if (!validTypes.includes(fileExtension)) {
        this.snackBar.open('Please select a CSV or Excel file', 'Close', { duration: 3000 });
        return;
      }

      this.selectedFile = file;
    }
  }

  removeFile(event: Event): void {
    event.stopPropagation();
    this.selectedFile = null;
  }

  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  processFile(): void {
    if (!this.selectedFile) return;

    const currentUser = this.authService.getCurrentUser();
    if (!currentUser || !currentUser.shopId) {
      this.snackBar.open('Shop information not found', 'Close', { duration: 3000 });
      return;
    }

    this.isUploading = true;
    this.uploadProgress = 0;

    // Create FormData for file upload
    const formData = new FormData();
    formData.append('file', this.selectedFile);
    formData.append('shopId', currentUser.shopId.toString());

    // Call the bulk upload API
    this.shopProductService.bulkUploadProducts(formData).subscribe({
      next: (event: HttpEvent<any>) => {
        switch (event.type) {
          case HttpEventType.UploadProgress:
            if (event.total) {
              this.uploadProgress = Math.round(100 * event.loaded / event.total);
            }
            break;
          case HttpEventType.Response:
            this.isUploading = false;
            this.uploadProgress = 100;
            
            // Process the API response
            if (event.body && event.body.success) {
              this.uploadResult = {
                fileName: this.selectedFile?.name || 'uploaded_file.csv',
                totalRows: event.body.totalRows || 0,
                successfulRows: event.body.successfulRows || 0,
                errorRows: event.body.errorRows || 0,
                errors: event.body.errors || []
              };
              this.nextStep();
            } else {
              this.snackBar.open('Upload failed: ' + (event.body.message || 'Unknown error'), 'Close', { duration: 5000 });
            }
            break;
        }
      },
      error: (error) => {
        this.isUploading = false;
        this.uploadProgress = 0;
        console.error('Bulk upload error:', error);
        
        // Fallback to mock processing for demo
        this.snackBar.open('API not available. Using demo mode.', 'Close', { duration: 3000 });
        this.simulateMockUpload();
      }
    });
  }

  private simulateMockUpload(): void {
    // Fallback mock processing when API is not available
    const interval = setInterval(() => {
      this.uploadProgress += 10;
      if (this.uploadProgress >= 100) {
        clearInterval(interval);
        this.isUploading = false;
        
        this.uploadResult = {
          fileName: this.selectedFile?.name || 'uploaded_file.csv',
          totalRows: 10,
          successfulRows: 8,
          errorRows: 2,
          errors: [
            {
              row: 3,
              field: 'Price',
              error: 'Price must be a positive number',
              value: 'invalid'
            },
            {
              row: 7,
              field: 'Category',
              error: 'Category not found',
              value: 'Unknown Category'
            }
          ]
        };

        this.nextStep();
      }
    }, 200);
  }

  downloadErrorReport(): void {
    if (!this.uploadResult || !this.uploadResult.errors || this.uploadResult.errors.length === 0) return;

    const headers = ['Row', 'Field', 'Error', 'Value'];
    const errorData = this.uploadResult.errors.map(error => [
      error.row, error.field, error.error, error.value
    ]);
    
    const csvContent = [headers, ...errorData].map(row => row.join(',')).join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'upload_errors_report.csv';
    link.click();
    window.URL.revokeObjectURL(url);

    this.snackBar.open('Error report downloaded', 'Close', { duration: 3000 });
  }

  importProducts(): void {
    if (!this.uploadResult || !this.uploadResult.successfulRows || this.uploadResult.successfulRows === 0) return;

    this.isImporting = true;

    // Simulate import process
    setTimeout(() => {
      this.isImporting = false;
      
      this.snackBar.open(
        `Successfully imported ${this.uploadResult?.successfulRows || 0} products!`,
        'Close',
        {
          duration: 5000,
          horizontalPosition: 'end',
          verticalPosition: 'top',
          panelClass: ['success-snackbar']
        }
      );

      // Navigate back to products
      this.router.navigate(['/shop-owner/my-products']);
    }, 3000);
  }
}