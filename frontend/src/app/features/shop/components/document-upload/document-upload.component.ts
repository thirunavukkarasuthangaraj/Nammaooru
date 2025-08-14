import { Component, Input, Output, EventEmitter, OnInit } from '@angular/core';
import { DocumentService } from '../../../../core/services/document.service';
import { ShopDocument, DocumentType, DocumentVerificationStatus } from '../../../../core/models/shop.model';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-document-upload',
  template: `
    <div class="document-upload-container">
      <div class="header">
        <h3>📄 Shop Documents</h3>
        <p class="subtitle">Upload required documents for verification</p>
      </div>

      <!-- Upload Section -->
      <div class="upload-section" *ngIf="!readonly">
        <div class="upload-form">
          <div class="form-row">
            <mat-form-field appearance="outline" class="document-type-field">
              <mat-label>Document Type</mat-label>
              <mat-select [(ngModel)]="selectedDocumentType" (selectionChange)="onDocumentTypeChange()">
                <mat-option *ngFor="let type of availableDocuments" [value]="type">
                  {{ getDocumentDisplayName(type) }}
                </mat-option>
              </mat-select>
            </mat-form-field>

            <mat-form-field appearance="outline" class="document-name-field">
              <mat-label>Document Name</mat-label>
              <input matInput [(ngModel)]="documentName" placeholder="Enter document name">
            </mat-form-field>
          </div>

          <div class="file-upload-section">
            <input type="file" #fileInput (change)="onFileSelected($event)" 
                   accept=".pdf,.jpg,.jpeg,.png,.docx,.doc" style="display: none;">
            
            <div class="file-drop-zone" 
                 (click)="fileInput.click()"
                 (dragover)="onDragOver($event)"
                 (dragleave)="onDragLeave($event)"
                 (drop)="onDrop($event)"
                 [class.drag-over]="isDragOver">
              <div class="upload-content">
                <mat-icon class="upload-icon">cloud_upload</mat-icon>
                <p class="upload-text">
                  <span *ngIf="!selectedFile">Click to browse or drag & drop your document here</span>
                  <span *ngIf="selectedFile" class="file-selected">
                    📄 {{ selectedFile.name }} ({{ formatFileSize(selectedFile.size) }})
                  </span>
                </p>
                <p class="upload-hint">Supported: PDF, JPG, PNG, DOCX (Max 10MB)</p>
              </div>
            </div>
          </div>

          <div class="upload-actions">
            <button mat-raised-button color="primary" 
                    (click)="uploadDocument()" 
                    [disabled]="!canUpload() || uploading">
              <mat-icon *ngIf="!uploading">upload</mat-icon>
              <mat-progress-spinner *ngIf="uploading" diameter="20" mode="indeterminate"></mat-progress-spinner>
              {{ uploading ? 'Uploading...' : 'Upload Document' }}
            </button>
            
            <button mat-stroked-button (click)="clearSelection()" *ngIf="selectedFile">
              <mat-icon>clear</mat-icon>
              Clear
            </button>
          </div>

          <!-- Upload Progress -->
          <div class="upload-progress" *ngIf="uploadProgress > 0 && uploadProgress < 100">
            <mat-progress-bar mode="determinate" [value]="uploadProgress"></mat-progress-bar>
            <span class="progress-text">{{ uploadProgress }}%</span>
          </div>
        </div>
      </div>

      <!-- Documents List -->
      <div class="documents-list">
        <h4>Uploaded Documents</h4>
        
        <div class="documents-grid">
          <div *ngFor="let doc of documents" class="document-card">
            <div class="document-header">
              <div class="document-info">
                <h5>{{ getDocumentDisplayName(doc.documentType) }}</h5>
                <p class="document-name">{{ doc.documentName }}</p>
              </div>
              <div class="document-status">
                <mat-chip [ngClass]="getStatusClass(doc.verificationStatus)">
                  {{ getStatusIcon(doc.verificationStatus) }} {{ doc.verificationStatus }}
                </mat-chip>
              </div>
            </div>

            <div class="document-details">
              <p><strong>File:</strong> {{ doc.originalFilename }}</p>
              <p><strong>Size:</strong> {{ formatFileSize(doc.fileSize) }}</p>
              <p><strong>Uploaded:</strong> {{ doc.createdAt | date:'MMM dd, yyyy' }}</p>
              <p *ngIf="doc.verificationNotes"><strong>Notes:</strong> {{ doc.verificationNotes }}</p>
            </div>

            <div class="document-actions">
              <button mat-icon-button (click)="downloadDocument(doc)" matTooltip="Download">
                <mat-icon>download</mat-icon>
              </button>
              
              <button mat-icon-button (click)="deleteDocument(doc)" 
                      *ngIf="!readonly" color="warn" matTooltip="Delete">
                <mat-icon>delete</mat-icon>
              </button>

              <button mat-icon-button (click)="verifyDocument(doc)" 
                      *ngIf="!readonly && isAdmin" matTooltip="Verify">
                <mat-icon>verified</mat-icon>
              </button>
            </div>
          </div>
        </div>

        <div class="no-documents" *ngIf="documents.length === 0">
          <mat-icon>folder_open</mat-icon>
          <p>No documents uploaded yet</p>
          <small>Upload required documents to complete shop verification</small>
        </div>
      </div>

      <!-- Required Documents Checklist -->
      <div class="required-documents" *ngIf="requiredDocuments.length > 0">
        <h4>Required Documents Checklist</h4>
        <div class="checklist">
          <div *ngFor="let reqDoc of requiredDocuments" class="checklist-item">
            <mat-icon [class]="hasDocument(reqDoc) ? 'check-icon' : 'missing-icon'">
              {{ hasDocument(reqDoc) ? 'check_circle' : 'radio_button_unchecked' }}
            </mat-icon>
            <span [class]="hasDocument(reqDoc) ? 'completed' : 'pending'">
              {{ getDocumentDisplayName(reqDoc) }}
            </span>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .document-upload-container {
      padding: 0;
    }

    .header {
      margin-bottom: 24px;
    }

    .header h3 {
      margin: 0 0 4px 0;
      color: #1f2937;
      font-size: 20px;
      font-weight: 600;
    }

    .subtitle {
      margin: 0;
      color: #6b7280;
      font-size: 14px;
    }

    .upload-section {
      background: white;
      padding: 24px;
      border-radius: 8px;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      margin-bottom: 24px;
    }

    .form-row {
      display: flex;
      gap: 16px;
      margin-bottom: 16px;
    }

    .document-type-field, .document-name-field {
      flex: 1;
    }

    .file-drop-zone {
      border: 2px dashed #d1d5db;
      border-radius: 8px;
      padding: 40px;
      text-align: center;
      cursor: pointer;
      transition: all 0.3s ease;
      margin-bottom: 16px;
    }

    .file-drop-zone:hover, .file-drop-zone.drag-over {
      border-color: #3b82f6;
      background-color: #f0f9ff;
    }

    .upload-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      color: #9ca3af;
      margin-bottom: 16px;
    }

    .upload-text {
      margin: 0 0 8px 0;
      color: #374151;
      font-size: 16px;
    }

    .file-selected {
      color: #059669;
      font-weight: 500;
    }

    .upload-hint {
      margin: 0;
      color: #6b7280;
      font-size: 14px;
    }

    .upload-actions {
      display: flex;
      gap: 12px;
      align-items: center;
    }

    .upload-progress {
      margin-top: 16px;
      position: relative;
    }

    .progress-text {
      position: absolute;
      top: -20px;
      right: 0;
      font-size: 12px;
      color: #6b7280;
    }

    .documents-list h4, .required-documents h4 {
      margin: 0 0 16px 0;
      color: #1f2937;
      font-size: 18px;
      font-weight: 600;
    }

    .documents-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }

    .document-card {
      background: white;
      border: 1px solid #e5e7eb;
      border-radius: 8px;
      padding: 16px;
      transition: box-shadow 0.3s ease;
    }

    .document-card:hover {
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    }

    .document-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 12px;
    }

    .document-info h5 {
      margin: 0 0 4px 0;
      color: #1f2937;
      font-size: 16px;
      font-weight: 600;
    }

    .document-name {
      margin: 0;
      color: #6b7280;
      font-size: 14px;
    }

    .document-details {
      margin-bottom: 12px;
    }

    .document-details p {
      margin: 4px 0;
      font-size: 14px;
      color: #374151;
    }

    .document-actions {
      display: flex;
      justify-content: flex-end;
      gap: 8px;
    }

    .status-verified {
      background-color: #d1fae5;
      color: #065f46;
    }

    .status-pending {
      background-color: #fef3c7;
      color: #92400e;
    }

    .status-rejected {
      background-color: #fee2e2;
      color: #991b1b;
    }

    .no-documents {
      text-align: center;
      padding: 40px;
      color: #6b7280;
    }

    .no-documents mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      margin-bottom: 16px;
    }

    .checklist {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
      gap: 12px;
    }

    .checklist-item {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px;
      border-radius: 4px;
    }

    .check-icon {
      color: #059669;
    }

    .missing-icon {
      color: #9ca3af;
    }

    .completed {
      color: #059669;
      text-decoration: line-through;
    }

    .pending {
      color: #374151;
    }

    .required-documents {
      background: white;
      padding: 24px;
      border-radius: 8px;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    }
  `]
})
export class DocumentUploadComponent implements OnInit {
  @Input() shopId!: number;
  @Input() businessType!: string;
  @Input() readonly = false;
  @Input() isAdmin = false;
  @Output() documentsChanged = new EventEmitter<ShopDocument[]>();

  documents: ShopDocument[] = [];
  requiredDocuments: DocumentType[] = [];
  availableDocuments: DocumentType[] = [];
  
  selectedDocumentType!: DocumentType;
  documentName = '';
  selectedFile: File | null = null;
  uploading = false;
  uploadProgress = 0;
  isDragOver = false;

  constructor(private documentService: DocumentService) {}

  ngOnInit() {
    this.loadRequiredDocuments();
    this.loadDocuments();
  }

  loadRequiredDocuments() {
    this.requiredDocuments = this.documentService.getRequiredDocuments(this.businessType);
    this.availableDocuments = [...this.requiredDocuments, DocumentType.OTHER];
  }

  loadDocuments() {
    if (this.shopId) {
      this.documentService.getShopDocuments(this.shopId).subscribe({
        next: (docs) => {
          this.documents = docs;
          this.documentsChanged.emit(docs);
        },
        error: (error) => console.error('Error loading documents:', error)
      });
    }
  }

  onDocumentTypeChange() {
    if (this.selectedDocumentType) {
      this.documentName = this.getDocumentDisplayName(this.selectedDocumentType);
    }
  }

  onFileSelected(event: any) {
    const file = event.target.files[0];
    if (file) {
      this.selectedFile = file;
    }
  }

  onDragOver(event: DragEvent) {
    event.preventDefault();
    this.isDragOver = true;
  }

  onDragLeave(event: DragEvent) {
    event.preventDefault();
    this.isDragOver = false;
  }

  onDrop(event: DragEvent) {
    event.preventDefault();
    this.isDragOver = false;
    
    const files = event.dataTransfer?.files;
    if (files && files.length > 0) {
      this.selectedFile = files[0];
    }
  }

  canUpload(): boolean {
    return !!(this.selectedDocumentType && this.documentName && this.selectedFile);
  }

  uploadDocument() {
    if (!this.canUpload()) return;

    this.uploading = true;
    this.uploadProgress = 0;

    this.documentService.uploadDocument(
      this.shopId,
      this.selectedDocumentType,
      this.documentName,
      this.selectedFile!
    ).subscribe({
      next: (result) => {
        if (result.type === 'progress') {
          this.uploadProgress = result.progress;
        } else if (result.type === 'complete') {
          this.uploading = false;
          this.uploadProgress = 100;
          
          Swal.fire({
            title: 'Success!',
            text: 'Document uploaded successfully',
            icon: 'success',
            confirmButtonColor: '#3085d6'
          });

          this.clearSelection();
          this.loadDocuments();
        }
      },
      error: (error) => {
        this.uploading = false;
        console.error('Upload error:', error);
        
        Swal.fire({
          title: 'Upload Failed',
          text: 'Failed to upload document. Please try again.',
          icon: 'error',
          confirmButtonColor: '#3085d6'
        });
      }
    });
  }

  clearSelection() {
    this.selectedFile = null;
    this.selectedDocumentType = undefined as any;
    this.documentName = '';
    this.uploadProgress = 0;
  }

  downloadDocument(doc: ShopDocument) {
    this.documentService.downloadDocument(doc.id).subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = doc.originalFilename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
      },
      error: (error) => {
        console.error('Download error:', error);
        Swal.fire({
          title: 'Download Failed',
          text: 'Failed to download document',
          icon: 'error',
          confirmButtonColor: '#3085d6'
        });
      }
    });
  }

  deleteDocument(doc: ShopDocument) {
    Swal.fire({
      title: 'Delete Document',
      text: `Are you sure you want to delete "${doc.documentName}"?`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, delete it!'
    }).then((result) => {
      if (result.isConfirmed) {
        this.documentService.deleteDocument(doc.id).subscribe({
          next: () => {
            Swal.fire({
              title: 'Deleted!',
              text: 'Document deleted successfully',
              icon: 'success',
              confirmButtonColor: '#3085d6'
            });
            this.loadDocuments();
          },
          error: (error) => {
            console.error('Delete error:', error);
            Swal.fire({
              title: 'Delete Failed',
              text: 'Failed to delete document',
              icon: 'error',
              confirmButtonColor: '#3085d6'
            });
          }
        });
      }
    });
  }

  verifyDocument(doc: ShopDocument) {
    // Implementation for document verification modal
    console.log('Verify document:', doc);
  }

  hasDocument(documentType: DocumentType): boolean {
    return this.documents.some(doc => doc.documentType === documentType && 
                               doc.verificationStatus !== DocumentVerificationStatus.REJECTED);
  }

  getDocumentDisplayName(documentType: DocumentType): string {
    return this.documentService.getDocumentDisplayName(documentType);
  }

  getStatusClass(status: DocumentVerificationStatus): string {
    return `status-${status.toLowerCase()}`;
  }

  getStatusIcon(status: DocumentVerificationStatus): string {
    switch (status) {
      case DocumentVerificationStatus.VERIFIED: return '✅';
      case DocumentVerificationStatus.REJECTED: return '❌';
      case DocumentVerificationStatus.EXPIRED: return '⏰';
      default: return '⏳';
    }
  }

  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }
}