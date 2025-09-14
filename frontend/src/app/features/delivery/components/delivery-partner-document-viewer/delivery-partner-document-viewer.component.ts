import { Component, Inject, OnInit } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { DeliveryPartnerService, DeliveryPartnerDocument, DocumentVerificationStatus } from '../../services/delivery-partner.service';
import { environment } from '../../../../../environments/environment';
import Swal from 'sweetalert2';

export interface DocumentViewerData {
  partnerId: number;
  partnerName: string;
  documents: DeliveryPartnerDocument[];
  isAdmin: boolean;
}

@Component({
  selector: 'app-delivery-partner-document-viewer',
  template: `
    <div class="document-viewer-container">
      <div class="dialog-header">
        <h2>📄 {{ data.partnerName }} - Documents</h2>
        <button mat-icon-button (click)="closeDialog()" class="close-btn">
          <mat-icon>close</mat-icon>
        </button>
      </div>

      <div class="dialog-content">
        <div class="documents-grid" *ngIf="documents.length > 0">
          <div class="document-card" *ngFor="let document of documents">
            <div class="document-header">
              <div class="document-info">
                <h4>{{ getDocumentDisplayName(document.documentType) }}</h4>
                <p class="document-filename">{{ document.originalFilename }}</p>
                <div class="document-meta">
                  <span class="file-size">{{ formatFileSize(document.fileSize) }}</span>
                  <span class="upload-date">{{ document.createdAt | date:'dd/MM/yyyy HH:mm' }}</span>
                </div>

                <!-- Additional metadata -->
                <div class="metadata" *ngIf="document.licenseNumber || document.vehicleNumber">
                  <span *ngIf="document.licenseNumber" class="metadata-item">
                    <mat-icon>card_membership</mat-icon>
                    License: {{ document.licenseNumber }}
                  </span>
                  <span *ngIf="document.vehicleNumber" class="metadata-item">
                    <mat-icon>motorcycle</mat-icon>
                    Vehicle: {{ document.vehicleNumber }}
                  </span>
                </div>
              </div>

              <!-- Verification Status -->
              <div class="verification-status">
                <mat-chip [class]="'status-chip status-' + document.verificationStatus.toLowerCase()">
                  <mat-icon class="status-icon">{{ getStatusIcon(document.verificationStatus) }}</mat-icon>
                  {{ document.verificationStatus }}
                </mat-chip>
              </div>
            </div>

            <div class="document-preview">
              <!-- Image Preview -->
              <div class="image-preview" *ngIf="isImageFile(document.fileType)">
                <img [src]="getFullImageUrl(document)"
                     [alt]="document.documentName"
                     (click)="openFullImage(document)"
                     class="preview-image">
              </div>

              <!-- PDF Preview -->
              <div class="pdf-preview" *ngIf="isPdfFile(document.fileType)">
                <mat-icon class="file-icon">picture_as_pdf</mat-icon>
                <span>PDF Document</span>
              </div>

              <!-- Other File Types -->
              <div class="other-file-preview" *ngIf="!isImageFile(document.fileType) && !isPdfFile(document.fileType)">
                <mat-icon class="file-icon">description</mat-icon>
                <span>{{ document.fileType }}</span>
              </div>
            </div>

            <div class="document-actions">
              <button mat-raised-button color="primary" (click)="downloadDocument(document)">
                <mat-icon>download</mat-icon>
                Download
              </button>

              <button mat-raised-button color="accent" (click)="viewFullDocument(document)">
                <mat-icon>visibility</mat-icon>
                View
              </button>

              <!-- Admin Verification Actions -->
              <div class="admin-actions" *ngIf="data.isAdmin && document.verificationStatus === 'PENDING'">
                <button mat-raised-button color="primary" (click)="verifyDocument(document, 'VERIFIED')">
                  <mat-icon>check_circle</mat-icon>
                  Approve
                </button>
                <button mat-raised-button color="warn" (click)="verifyDocument(document, 'REJECTED')">
                  <mat-icon>cancel</mat-icon>
                  Reject
                </button>
              </div>
            </div>

            <!-- Verification Notes -->
            <div class="verification-notes" *ngIf="document.verificationNotes">
              <h5>Admin Notes:</h5>
              <p>{{ document.verificationNotes }}</p>
              <small>Verified by: {{ document.verifiedBy }} on {{ document.verifiedAt | date:'dd/MM/yyyy HH:mm' }}</small>
            </div>
          </div>
        </div>

        <!-- No Documents Message -->
        <div class="no-documents" *ngIf="documents.length === 0">
          <mat-icon>folder_open</mat-icon>
          <h3>No Documents Found</h3>
          <p>This delivery partner hasn't uploaded any documents yet.</p>
          <button mat-raised-button color="primary" (click)="closeDialog('manage')">
            <mat-icon>upload_file</mat-icon>
            Manage Documents
          </button>
        </div>
      </div>

      <!-- Document Summary -->
      <div class="document-summary" *ngIf="documents.length > 0">
        <h4>Document Summary</h4>
        <div class="summary-stats">
          <div class="stat-item">
            <span class="stat-value">{{ documents.length }}</span>
            <span class="stat-label">Total Documents</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">{{ getVerifiedCount() }}</span>
            <span class="stat-label">Verified</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">{{ getPendingCount() }}</span>
            <span class="stat-label">Pending</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">{{ getRejectedCount() }}</span>
            <span class="stat-label">Rejected</span>
          </div>
        </div>

        <div class="completion-status">
          <div class="progress-info">
            <span>Verification Progress: {{ getVerificationPercentage() }}%</span>
            <mat-progress-bar mode="determinate" [value]="getVerificationPercentage()"></mat-progress-bar>
          </div>
        </div>
      </div>

      <div class="dialog-actions">
        <button mat-button (click)="closeDialog()">Close</button>
        <button mat-raised-button color="primary" (click)="refreshDocuments()">
          <mat-icon>refresh</mat-icon>
          Refresh
        </button>
      </div>
    </div>
  `,
  styles: [`
    .document-viewer-container {
      display: flex;
      flex-direction: column;
      height: 100%;
      max-height: 80vh;
    }

    .dialog-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 20px 24px;
      border-bottom: 1px solid #e0e0e0;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      margin: -24px -24px 0 -24px;
    }

    .dialog-header h2 {
      margin: 0;
      font-size: 20px;
      font-weight: 600;
    }

    .close-btn {
      color: white;
    }

    .dialog-content {
      flex: 1;
      overflow-y: auto;
      padding: 20px 0;
    }

    .documents-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
      gap: 20px;
      margin-bottom: 20px;
    }

    .document-card {
      border: 1px solid #e0e0e0;
      border-radius: 12px;
      padding: 16px;
      background: white;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      transition: all 0.3s ease;
    }

    .document-card:hover {
      box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
      transform: translateY(-2px);
    }

    .document-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 16px;
    }

    .document-info h4 {
      margin: 0 0 4px 0;
      color: #333;
      font-size: 16px;
      font-weight: 600;
    }

    .document-filename {
      margin: 0 0 8px 0;
      color: #666;
      font-size: 12px;
      word-break: break-all;
    }

    .document-meta {
      display: flex;
      gap: 12px;
      font-size: 11px;
      color: #999;
    }

    .metadata {
      display: flex;
      flex-direction: column;
      gap: 4px;
      margin-top: 8px;
    }

    .metadata-item {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 12px;
      color: #666;
    }

    .metadata-item mat-icon {
      font-size: 14px;
      width: 14px;
      height: 14px;
    }

    .verification-status .status-chip {
      font-size: 11px;
      height: 24px;
      padding: 0 8px;
    }

    .status-chip.status-verified {
      background: #e8f5e8;
      color: #2e7d32;
    }

    .status-chip.status-pending {
      background: #fff3e0;
      color: #f57c00;
    }

    .status-chip.status-rejected {
      background: #ffebee;
      color: #c62828;
    }

    .status-icon {
      font-size: 14px;
      width: 14px;
      height: 14px;
      margin-right: 4px;
    }

    .document-preview {
      margin-bottom: 16px;
      text-align: center;
      min-height: 120px;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #f8f9fa;
      border-radius: 8px;
    }

    .preview-image {
      max-width: 100%;
      max-height: 120px;
      border-radius: 4px;
      cursor: pointer;
      transition: transform 0.3s ease;
    }

    .preview-image:hover {
      transform: scale(1.05);
    }

    .pdf-preview,
    .other-file-preview {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      color: #666;
    }

    .file-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      color: #999;
    }

    .document-actions {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }

    .admin-actions {
      display: flex;
      gap: 8px;
      margin-left: auto;
    }

    .verification-notes {
      margin-top: 16px;
      padding: 12px;
      background: #f8f9fa;
      border-radius: 8px;
      border-left: 4px solid #1976d2;
    }

    .verification-notes h5 {
      margin: 0 0 8px 0;
      color: #333;
      font-size: 14px;
      font-weight: 600;
    }

    .verification-notes p {
      margin: 0 0 8px 0;
      color: #666;
      font-size: 14px;
    }

    .verification-notes small {
      color: #999;
      font-size: 12px;
    }

    .no-documents {
      text-align: center;
      padding: 40px;
      color: #666;
    }

    .no-documents mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      margin-bottom: 16px;
      color: #ccc;
    }

    .document-summary {
      border-top: 1px solid #e0e0e0;
      padding: 20px 0;
      margin-top: 20px;
    }

    .summary-stats {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(100px, 1fr));
      gap: 16px;
      margin-bottom: 16px;
    }

    .stat-item {
      text-align: center;
      padding: 12px;
      background: #f8f9fa;
      border-radius: 8px;
    }

    .stat-value {
      display: block;
      font-size: 24px;
      font-weight: 600;
      color: #1976d2;
    }

    .stat-label {
      display: block;
      font-size: 12px;
      color: #666;
      margin-top: 4px;
    }

    .completion-status {
      margin-top: 16px;
    }

    .progress-info {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .progress-info span {
      font-weight: 500;
      color: #333;
    }

    .dialog-actions {
      display: flex;
      justify-content: flex-end;
      gap: 12px;
      padding-top: 20px;
      border-top: 1px solid #e0e0e0;
    }

    .dialog-actions button {
      min-width: 100px;
    }
  `]
})
export class DeliveryPartnerDocumentViewerComponent implements OnInit {
  documents: DeliveryPartnerDocument[] = [];

  constructor(
    public dialogRef: MatDialogRef<DeliveryPartnerDocumentViewerComponent>,
    @Inject(MAT_DIALOG_DATA) public data: DocumentViewerData,
    private deliveryPartnerService: DeliveryPartnerService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit() {
    this.documents = this.data.documents || [];
  }

  closeDialog(result?: string): void {
    this.dialogRef.close(result);
  }

  refreshDocuments(): void {
    this.deliveryPartnerService.getPartnerDocuments(this.data.partnerId).subscribe({
      next: (response) => {
        this.documents = response.data || [];
        this.snackBar.open('Documents refreshed successfully', 'Close', { duration: 2000 });
      },
      error: (error) => {
        console.error('Error refreshing documents:', error);
        this.snackBar.open('Error refreshing documents', 'Close', { duration: 3000 });
      }
    });
  }

  downloadDocument(document: DeliveryPartnerDocument): void {
    this.deliveryPartnerService.downloadPartnerDocument(this.data.partnerId, document.id!).subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const a = window.document.createElement('a');
        a.href = url;
        a.download = document.originalFilename;
        a.click();
        window.URL.revokeObjectURL(url);
      },
      error: (error) => {
        console.error('Error downloading document:', error);
        this.snackBar.open('Error downloading document', 'Close', { duration: 3000 });
      }
    });
  }

  viewFullDocument(document: DeliveryPartnerDocument): void {
    if (this.isImageFile(document.fileType)) {
      this.openFullImage(document);
    } else {
      // For PDFs and other files, open in new tab
      const url = this.getFullImageUrl(document);
      window.open(url, '_blank');
    }
  }

  openFullImage(document: DeliveryPartnerDocument): void {
    Swal.fire({
      imageUrl: this.getFullImageUrl(document),
      imageAlt: document.documentName,
      showConfirmButton: false,
      showCloseButton: true,
      width: 'auto',
      customClass: {
        image: 'swal-image-full'
      }
    });
  }

  verifyDocument(document: DeliveryPartnerDocument, status: string): void {
    if (!this.data.isAdmin) return;

    const isApproval = status === 'VERIFIED';
    const actionText = isApproval ? 'approve' : 'reject';
    const statusValue = status as DocumentVerificationStatus;

    Swal.fire({
      title: `${isApproval ? 'Approve' : 'Reject'} Document`,
      text: `Are you sure you want to ${actionText} this ${this.getDocumentDisplayName(document.documentType)}?`,
      input: 'textarea',
      inputPlaceholder: `Enter notes for ${actionText}ing this document...`,
      showCancelButton: true,
      confirmButtonText: isApproval ? 'Approve' : 'Reject',
      confirmButtonColor: isApproval ? '#4caf50' : '#f44336',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.deliveryPartnerService.verifyPartnerDocument(
          this.data.partnerId,
          document.id!,
          statusValue,
          result.value || undefined
        ).subscribe({
          next: (response) => {
            // Update the document in the local array
            const index = this.documents.findIndex(d => d.id === document.id);
            if (index !== -1) {
              this.documents[index] = response.data;
            }

            this.snackBar.open(
              `Document ${actionText}ed successfully`,
              'Close',
              { duration: 3000 }
            );
          },
          error: (error) => {
            console.error(`Error ${actionText}ing document:`, error);
            this.snackBar.open(`Error ${actionText}ing document`, 'Close', { duration: 3000 });
          }
        });
      }
    });
  }

  // Helper methods
  getDocumentDisplayName(documentType: string): string {
    return this.deliveryPartnerService.getDocumentDisplayName(documentType as any);
  }

  isImageFile(fileType: string | undefined): boolean {
    if (!fileType) return false;
    return fileType.startsWith('image/');
  }

  isPdfFile(fileType: string | undefined): boolean {
    if (!fileType) return false;
    return fileType === 'application/pdf';
  }

  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  getStatusIcon(status: string): string {
    switch (status) {
      case 'VERIFIED': return 'check_circle';
      case 'REJECTED': return 'cancel';
      case 'PENDING': return 'schedule';
      default: return 'help';
    }
  }

  getVerifiedCount(): number {
    return this.documents.filter(d => d.verificationStatus === 'VERIFIED').length;
  }

  getPendingCount(): number {
    return this.documents.filter(d => d.verificationStatus === 'PENDING').length;
  }

  getRejectedCount(): number {
    return this.documents.filter(d => d.verificationStatus === 'REJECTED').length;
  }

  getVerificationPercentage(): number {
    if (this.documents.length === 0) return 0;
    return Math.round((this.getVerifiedCount() / this.documents.length) * 100);
  }

  getFullImageUrl(document: DeliveryPartnerDocument): string {
    if (!document.downloadUrl) return '';

    // If downloadUrl is already a full URL (starts with http), return as is
    if (document.downloadUrl.startsWith('http')) {
      return document.downloadUrl;
    }

    // Otherwise, prepend the API base URL
    return environment.apiUrl + document.downloadUrl;
  }
}