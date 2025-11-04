import { Component, OnInit } from '@angular/core';
import { BulkImportService, BulkImportResponse, BulkImportResult } from '../../services/bulk-import.service';
import { MatSnackBar } from '@angular/material/snack-bar';
import { AuthService } from '../../../../core/services/auth.service';

@Component({
  selector: 'app-product-bulk-import',
  templateUrl: './product-bulk-import.component.html',
  styleUrls: ['./product-bulk-import.component.scss']
})
export class ProductBulkImportComponent implements OnInit {
  selectedFile: File | null = null;
  isUploading = false;
  uploadProgress = 0;
  importResults: BulkImportResponse | null = null;
  showResults = false;
  isSuperAdmin = false;
  isShopOwner = false;

  // Table columns for results
  displayedColumns: string[] = ['rowNumber', 'productName', 'status', 'message', 'imageStatus'];

  constructor(
    private bulkImportService: BulkImportService,
    private snackBar: MatSnackBar,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    this.checkUserRole();
  }

  checkUserRole(): void {
    this.isSuperAdmin = this.authService.isSuperAdmin() || this.authService.isAdmin();
    this.isShopOwner = this.authService.isShopOwner();
  }

  onFileSelected(event: any): void {
    const file = event.target.files[0];
    if (file) {
      // Validate file
      const validation = this.bulkImportService.validateExcelFile(file);
      if (!validation.valid) {
        this.snackBar.open(validation.error || 'Invalid file', 'Close', { duration: 5000 });
        return;
      }

      this.selectedFile = file;
      this.importResults = null;
      this.showResults = false;
    }
  }

  removeFile(): void {
    this.selectedFile = null;
    this.importResults = null;
    this.showResults = false;
  }

  uploadFile(): void {
    if (!this.selectedFile) {
      this.snackBar.open('Please select a file first', 'Close', { duration: 3000 });
      return;
    }

    this.isUploading = true;
    this.uploadProgress = 0;

    // Determine which import method to use based on user role
    const importMethod = this.isSuperAdmin
      ? this.bulkImportService.importMasterProducts(this.selectedFile)
      : this.bulkImportService.importShopProducts(this.selectedFile);

    importMethod.subscribe({
      next: (response) => {
        this.isUploading = false;
        this.uploadProgress = 100;

        if (response.success) {
          this.importResults = response.data;
          this.showResults = true;

          const message = `Import completed! Success: ${response.data.successCount}, Failed: ${response.data.failureCount}`;
          this.snackBar.open(message, 'Close', {
            duration: 5000,
            panelClass: response.data.failureCount === 0 ? ['success-snackbar'] : ['warning-snackbar']
          });
        } else {
          this.snackBar.open(response.message || 'Import failed', 'Close', {
            duration: 5000,
            panelClass: ['error-snackbar']
          });
        }
      },
      error: (error) => {
        this.isUploading = false;
        this.uploadProgress = 0;

        const errorMessage = error.error?.message || error.message || 'Upload failed. Please try again.';
        this.snackBar.open(errorMessage, 'Close', {
          duration: 5000,
          panelClass: ['error-snackbar']
        });
      }
    });
  }

  downloadSampleCSV(): void {
    this.bulkImportService.downloadSampleCSV();
    this.snackBar.open('Sample CSV downloaded', 'Close', { duration: 3000 });
  }

  getTemplateInfo(): void {
    const type = this.isSuperAdmin ? 'master' : 'shop';
    this.bulkImportService.getTemplateInfo(type).subscribe({
      next: (response) => {
        if (response.success) {
          console.log('Template Info:', response.data);
          // You can display this in a dialog if needed
          this.snackBar.open('Template info loaded. Check console for details.', 'Close', { duration: 3000 });
        }
      },
      error: (error) => {
        console.error('Error fetching template info:', error);
      }
    });
  }

  getStatusClass(status: string): string {
    switch (status) {
      case 'SUCCESS':
        return 'status-success';
      case 'FAILED':
        return 'status-failed';
      case 'SKIPPED':
        return 'status-skipped';
      default:
        return '';
    }
  }

  getStatusIcon(status: string): string {
    switch (status) {
      case 'SUCCESS':
        return 'check_circle';
      case 'FAILED':
        return 'error';
      case 'SKIPPED':
        return 'info';
      default:
        return 'help';
    }
  }

  resetUpload(): void {
    this.selectedFile = null;
    this.importResults = null;
    this.showResults = false;
    this.uploadProgress = 0;
  }

  exportResults(): void {
    if (!this.importResults) return;

    const csvContent = this.generateResultsCSV();
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);

    link.setAttribute('href', url);
    link.setAttribute('download', `import_results_${new Date().getTime()}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    this.snackBar.open('Results exported', 'Close', { duration: 3000 });
  }

  private generateResultsCSV(): string {
    if (!this.importResults) return '';

    const headers = ['Row Number', 'Product Name', 'Status', 'Message', 'Image Status'];
    const rows = this.importResults.results.map(result => [
      result.rowNumber,
      result.productName,
      result.status,
      result.message,
      result.imageUploadStatus || 'N/A'
    ]);

    const csvRows = [];
    csvRows.push(headers.join(','));

    rows.forEach(row => {
      const escapedRow = row.map(cell => {
        const cellStr = String(cell);
        if (cellStr.includes(',') || cellStr.includes('"')) {
          return `"${cellStr.replace(/"/g, '""')}"`;
        }
        return cellStr;
      });
      csvRows.push(escapedRow.join(','));
    });

    return csvRows.join('\n');
  }
}
