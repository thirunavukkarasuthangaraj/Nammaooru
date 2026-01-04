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
   * Generate sample CSV content - Standard Template Format
   *
   * Column Mapping (matches backend BulkProductImportService):
   * A(0):  name           - Product name (required)
   * B(1):  nameTamil      - Tamil name
   * C(2):  description    - Product description
   * D(3):  category       - Category name (auto-created if not exists)
   * E(4):  brand          - Brand name
   * F(5):  sku            - SKU code (used to find existing products)
   * G(6):  searchQuery    - (SKIP - for internal use)
   * H(7):  downloadLink   - (SKIP - for internal use)
   * I(8):  baseUnit       - Unit of measurement (kg, piece, etc.)
   * J(9):  baseWeight     - Weight value
   * K(10): originalPrice  - MRP/Original price
   * L(11): sellingPrice   - Selling price
   * M(12): discountPct    - Discount percentage
   * N(13): costPrice      - Cost price
   * O(14): stockQuantity  - Current stock
   * P(15): minStockLevel  - Minimum stock alert level
   * Q(16): maxStockLevel  - Maximum stock level
   * R(17): trackInventory - Track inventory (TRUE/FALSE)
   * S(18): status         - ACTIVE/INACTIVE
   * T(19): isFeatured     - Featured product (TRUE/FALSE)
   * U(20): isAvailable    - Available for sale (TRUE/FALSE)
   * V(21): reserved       - (SKIP - reserved for future use)
   * W(22): tags           - Comma-separated tags
   * X(23): specifications - Product specifications
   * Y(24): imagePath      - Image filename (e.g., product.jpg)
   * Z(25): imageFolder    - Subfolder under /uploads/products/master/
   */
  private generateSampleCSV(): string {
    // Standard header format - 26 columns (A to Z)
    const headers = [
      'name',           // A(0) - Required
      'nameTamil',      // B(1)
      'description',    // C(2)
      'category',       // D(3) - Required (auto-created if not exists)
      'brand',          // E(4)
      'sku',            // F(5)
      'searchQuery',    // G(6) - SKIP
      'downloadLink',   // H(7) - SKIP
      'baseUnit',       // I(8)
      'baseWeight',     // J(9)
      'originalPrice',  // K(10)
      'sellingPrice',   // L(11)
      'discountPct',    // M(12)
      'costPrice',      // N(13)
      'stockQuantity',  // O(14)
      'minStockLevel',  // P(15)
      'maxStockLevel',  // Q(16)
      'trackInventory', // R(17)
      'status',         // S(18)
      'isFeatured',     // T(19)
      'isAvailable',    // U(20)
      'reserved',       // V(21) - SKIP
      'tags',           // W(22)
      'specifications', // X(23)
      'imagePath',      // Y(24) - Image filename
      'imageFolder'     // Z(25) - Subfolder name
    ];

    // Sample data rows
    const sampleData = [
      [
        'Fresh Tomatoes',           // name
        'தக்காளி',                  // nameTamil
        'Organic tomatoes from local farms',  // description
        'Vegetables',               // category
        'FreshFarm',                // brand
        'VEG-TOM-001',              // sku
        '',                         // searchQuery (skip)
        '',                         // downloadLink (skip)
        'kg',                       // baseUnit
        '1',                        // baseWeight
        '100',                      // originalPrice
        '90',                       // sellingPrice
        '10',                       // discountPct
        '80',                       // costPrice
        '100',                      // stockQuantity
        '10',                       // minStockLevel
        '500',                      // maxStockLevel
        'TRUE',                     // trackInventory
        'ACTIVE',                   // status
        'FALSE',                    // isFeatured
        'TRUE',                     // isAvailable
        '',                         // reserved (skip)
        'organic,fresh,local',      // tags
        'Rich in Vitamin C',        // specifications
        'tomato.jpg',               // imagePath
        'vegetables'                // imageFolder
      ],
      [
        'Basmati Rice 1kg',
        'பாசுமதி அரிசி',
        'Premium aged basmati rice',
        'Groceries',
        'IndiaGate',
        'GRO-RICE-001',
        '',
        '',
        'kg',
        '1',
        '200',
        '180',
        '10',
        '160',
        '200',
        '20',
        '1000',
        'TRUE',
        'ACTIVE',
        'TRUE',
        'TRUE',
        '',
        'premium,aged,basmati',
        'Aged for 2 years',
        'rice.jpg',
        'groceries'
      ],
      [
        'Amul Butter 500g',
        'அமுல் வெண்ணெய்',
        'Fresh dairy butter',
        'Dairy Products',
        'Amul',
        'DAI-BUT-001',
        '',
        '',
        'gram',
        '500',
        '280',
        '260',
        '7',
        '240',
        '50',
        '10',
        '200',
        'TRUE',
        'ACTIVE',
        'FALSE',
        'TRUE',
        '',
        'dairy,butter,fresh',
        'Keep refrigerated',
        'butter.jpg',
        'dairy'
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
