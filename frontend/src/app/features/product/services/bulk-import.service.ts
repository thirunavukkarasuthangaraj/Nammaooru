import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

export interface BulkImportResult {
  rowNumber: number;
  productName: string;
  status: 'SUCCESS' | 'FAILED' | 'SKIPPED';
  message: string;
  productId?: number;
  imageUploadStatus?: string;
}

export interface BulkImportResponse {
  totalRows: number;
  successCount: number;
  failureCount: number;
  results: BulkImportResult[];
  message: string;
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}

export interface TemplateColumnInfo {
  column: string;
  fieldName: string;
  displayName: string;
  dataType: string;
  required: boolean;
  example: string;
}

export interface TemplateInfo {
  type: string;
  description: string;
  columns: TemplateColumnInfo[];
}

@Injectable({
  providedIn: 'root'
})
export class BulkImportService {
  private apiUrl = `${environment.apiUrl}/products/bulk-import`;

  constructor(private http: HttpClient) {}

  /**
   * Import master products (Super Admin only)
   */
  importMasterProducts(excelFile: File): Observable<ApiResponse<BulkImportResponse>> {
    const formData = new FormData();
    formData.append('file', excelFile);

    return this.http.post<ApiResponse<BulkImportResponse>>(
      `${this.apiUrl}/master`,
      formData
    );
  }

  /**
   * Import shop products (Shop Owner)
   */
  importShopProducts(excelFile: File): Observable<ApiResponse<BulkImportResponse>> {
    const formData = new FormData();
    formData.append('file', excelFile);

    return this.http.post<ApiResponse<BulkImportResponse>>(
      `${this.apiUrl}/shop-products`,
      formData
    );
  }

  /**
   * Get template information
   */
  getTemplateInfo(type: 'master' | 'shop' = 'master'): Observable<ApiResponse<TemplateInfo>> {
    return this.http.get<ApiResponse<TemplateInfo>>(
      `${this.apiUrl}/template-info?type=${type}`
    );
  }

  /**
   * Download sample CSV file
   */
  downloadSampleCSV(): void {
    const csvContent = this.generateSampleCSV();
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);

    link.setAttribute('href', url);
    link.setAttribute('download', 'product_import_template.csv');
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  /**
   * Generate sample CSV content
   */
  private generateSampleCSV(): string {
    const headers = [
      'name', 'description', 'categoryId', 'brand', 'sku', 'barcode',
      'baseUnit', 'baseWeight', 'originalPrice', 'sellingPrice', 'discountPercentage',
      'costPrice', 'stockQuantity', 'minStockLevel', 'maxStockLevel', 'trackInventory',
      'status', 'isFeatured', 'isAvailable', 'tags', 'specifications', 'imagePath', 'imageFolder'
    ];

    const sampleData = [
      [
        'Fresh Tomatoes', 'Organic tomatoes from local farms', '1', 'FreshFarm', '', '',
        'kg', '1', '100', '90', '10', '80', '100', '10', '500', 'TRUE',
        'ACTIVE', 'FALSE', 'TRUE', 'organic,fresh,local', 'Rich in Vitamin C', 'tomato.jpg', 'vegetables'
      ],
      [
        'Red Onions', 'Premium quality red onions', '1', 'FreshFarm', '', '',
        'kg', '1', '80', '70', '12.5', '60', '150', '20', '600', 'TRUE',
        'ACTIVE', 'FALSE', 'TRUE', 'fresh,organic', 'Good for cooking', 'onion.jpg', 'vegetables'
      ],
      [
        'Basmati Rice 1kg', 'Premium aged basmati rice', '2', 'IndiaGate', '', '8901491100014',
        'kg', '1', '200', '180', '10', '160', '200', '20', '1000', 'TRUE',
        'ACTIVE', 'TRUE', 'TRUE', 'premium,aged', 'Aged for 2 years', 'rice.jpg', 'groceries'
      ]
    ];

    const csvRows = [];
    csvRows.push(headers.join(','));

    sampleData.forEach(row => {
      const escapedRow = row.map(cell => {
        // Escape cells that contain commas or quotes
        if (cell.includes(',') || cell.includes('"')) {
          return `"${cell.replace(/"/g, '""')}"`;
        }
        return cell;
      });
      csvRows.push(escapedRow.join(','));
    });

    return csvRows.join('\n');
  }

  /**
   * Validate Excel file before upload
   */
  validateExcelFile(file: File): { valid: boolean; error?: string } {
    // Check file type
    const validTypes = [
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-excel'
    ];

    const validExtensions = ['.xlsx', '.xls'];
    const fileExtension = file.name.substring(file.name.lastIndexOf('.')).toLowerCase();

    if (!validExtensions.includes(fileExtension)) {
      return {
        valid: false,
        error: 'Invalid file format. Please upload an Excel file (.xlsx or .xls)'
      };
    }

    // Check file size (10MB limit)
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (file.size > maxSize) {
      return {
        valid: false,
        error: 'File size exceeds 10MB limit'
      };
    }

    // Check file name
    if (!file.name || file.name.trim() === '') {
      return {
        valid: false,
        error: 'Invalid file name'
      };
    }

    return { valid: true };
  }
}
