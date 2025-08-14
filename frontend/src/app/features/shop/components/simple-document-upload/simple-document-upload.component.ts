import { Component, Input, Output, EventEmitter, OnInit } from '@angular/core';
import { DocumentService } from '../../../../core/services/document.service';
import { ShopDocument, DocumentType } from '../../../../core/models/shop.model';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-simple-document-upload',
  template: `
    <div class="simple-upload-container">
      <h3>📄 Upload Required Documents</h3>
      <p class="subtitle">Please upload these 3 essential documents:</p>

      <div class="documents-grid">
        
        <!-- 1. Owner Photo -->
        <div class="document-upload-card">
          <div class="document-header">
            <mat-icon class="document-icon">person</mat-icon>
            <h4>👤 Shop Owner Photo</h4>
            <p>Upload clear photo of shop owner</p>
          </div>
          
          <div class="upload-zone" (click)="ownerPhotoInput.click()" 
               [class.has-file]="ownerPhoto">
            <input #ownerPhotoInput type="file" (change)="onFileSelected($event, 'OWNER_PHOTO')" 
                   accept=".jpg,.jpeg,.png" style="display: none;">
            
            <div *ngIf="!ownerPhoto" class="upload-placeholder">
              <mat-icon>cloud_upload</mat-icon>
              <span>Click to upload</span>
              <small>JPG, PNG (Max 10MB)</small>
            </div>
            
            <div *ngIf="ownerPhoto" class="file-preview">
              <mat-icon class="success-icon">check_circle</mat-icon>
              <span>{{ ownerPhoto.name }}</span>
              <small>{{ formatFileSize(ownerPhoto.size) }}</small>
            </div>
          </div>
          
          <button mat-raised-button color="primary" 
                  (click)="uploadDocument('OWNER_PHOTO', ownerPhoto!)" 
                  [disabled]="!ownerPhoto || uploading.OWNER_PHOTO">
            <mat-icon *ngIf="!uploading.OWNER_PHOTO">upload</mat-icon>
            <mat-progress-spinner *ngIf="uploading.OWNER_PHOTO" diameter="20"></mat-progress-spinner>
            {{ uploading.OWNER_PHOTO ? 'Uploading...' : 'Upload Owner Photo' }}
          </button>
          
          <div class="upload-status" *ngIf="uploadStatus.OWNER_PHOTO">
            <mat-icon [class]="uploadStatus.OWNER_PHOTO === 'success' ? 'success' : 'error'">
              {{ uploadStatus.OWNER_PHOTO === 'success' ? 'check_circle' : 'error' }}
            </mat-icon>
            <span>{{ uploadStatus.OWNER_PHOTO === 'success' ? 'Uploaded Successfully' : 'Upload Failed' }}</span>
          </div>
        </div>

        <!-- 2. Shop Photo -->
        <div class="document-upload-card">
          <div class="document-header">
            <mat-icon class="document-icon">store</mat-icon>
            <h4>🏪 Shop Photo</h4>
            <p>Upload clear photo of your shop</p>
          </div>
          
          <div class="upload-zone" (click)="shopPhotoInput.click()" 
               [class.has-file]="shopPhoto">
            <input #shopPhotoInput type="file" (change)="onFileSelected($event, 'SHOP_PHOTO')" 
                   accept=".jpg,.jpeg,.png" style="display: none;">
            
            <div *ngIf="!shopPhoto" class="upload-placeholder">
              <mat-icon>cloud_upload</mat-icon>
              <span>Click to upload</span>
              <small>JPG, PNG (Max 10MB)</small>
            </div>
            
            <div *ngIf="shopPhoto" class="file-preview">
              <mat-icon class="success-icon">check_circle</mat-icon>
              <span>{{ shopPhoto.name }}</span>
              <small>{{ formatFileSize(shopPhoto.size) }}</small>
            </div>
          </div>
          
          <button mat-raised-button color="primary" 
                  (click)="uploadDocument('SHOP_PHOTO', shopPhoto!)" 
                  [disabled]="!shopPhoto || uploading.SHOP_PHOTO">
            <mat-icon *ngIf="!uploading.SHOP_PHOTO">upload</mat-icon>
            <mat-progress-spinner *ngIf="uploading.SHOP_PHOTO" diameter="20"></mat-progress-spinner>
            {{ uploading.SHOP_PHOTO ? 'Uploading...' : 'Upload Shop Photo' }}
          </button>
          
          <div class="upload-status" *ngIf="uploadStatus.SHOP_PHOTO">
            <mat-icon [class]="uploadStatus.SHOP_PHOTO === 'success' ? 'success' : 'error'">
              {{ uploadStatus.SHOP_PHOTO === 'success' ? 'check_circle' : 'error' }}
            </mat-icon>
            <span>{{ uploadStatus.SHOP_PHOTO === 'success' ? 'Uploaded Successfully' : 'Upload Failed' }}</span>
          </div>
        </div>

        <!-- 3. FSSAI Certificate -->
        <div class="document-upload-card">
          <div class="document-header">
            <mat-icon class="document-icon">verified_user</mat-icon>
            <h4>🏛️ FSSAI Certificate</h4>
            <p>Food Safety certification document</p>
          </div>
          
          <div class="upload-zone" (click)="fssaiInput.click()" 
               [class.has-file]="fssaiCert">
            <input #fssaiInput type="file" (change)="onFileSelected($event, 'FSSAI_CERTIFICATE')" 
                   accept=".pdf,.jpg,.jpeg,.png" style="display: none;">
            
            <div *ngIf="!fssaiCert" class="upload-placeholder">
              <mat-icon>cloud_upload</mat-icon>
              <span>Click to upload</span>
              <small>PDF, JPG, PNG (Max 10MB)</small>
            </div>
            
            <div *ngIf="fssaiCert" class="file-preview">
              <mat-icon class="success-icon">check_circle</mat-icon>
              <span>{{ fssaiCert.name }}</span>
              <small>{{ formatFileSize(fssaiCert.size) }}</small>
            </div>
          </div>
          
          <button mat-raised-button color="primary" 
                  (click)="uploadDocument('FSSAI_CERTIFICATE', fssaiCert!)" 
                  [disabled]="!fssaiCert || uploading.FSSAI_CERTIFICATE">
            <mat-icon *ngIf="!uploading.FSSAI_CERTIFICATE">upload</mat-icon>
            <mat-progress-spinner *ngIf="uploading.FSSAI_CERTIFICATE" diameter="20"></mat-progress-spinner>
            {{ uploading.FSSAI_CERTIFICATE ? 'Uploading...' : 'Upload FSSAI Certificate' }}
          </button>
          
          <div class="upload-status" *ngIf="uploadStatus.FSSAI_CERTIFICATE">
            <mat-icon [class]="uploadStatus.FSSAI_CERTIFICATE === 'success' ? 'success' : 'error'">
              {{ uploadStatus.FSSAI_CERTIFICATE === 'success' ? 'check_circle' : 'error' }}
            </mat-icon>
            <span>{{ uploadStatus.FSSAI_CERTIFICATE === 'success' ? 'Uploaded Successfully' : 'Upload Failed' }}</span>
          </div>
        </div>
      </div>

      <!-- Progress Summary -->
      <div class="upload-summary">
        <h4>Upload Progress: {{ getUploadedCount() }}/3 Documents</h4>
        <mat-progress-bar mode="determinate" [value]="getProgressPercentage()"></mat-progress-bar>
      </div>
    </div>
  `,
  styles: [`
    .simple-upload-container {
      padding: 24px;
    }

    .simple-upload-container h3 {
      margin: 0 0 8px 0;
      color: #1976d2;
      font-size: 24px;
      text-align: center;
    }

    .subtitle {
      text-align: center;
      color: #666;
      margin-bottom: 32px;
    }

    .documents-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 24px;
      margin-bottom: 32px;
    }

    .document-upload-card {
      background: white;
      border: 2px solid #e0e0e0;
      border-radius: 12px;
      padding: 20px;
      text-align: center;
      transition: all 0.3s ease;
    }

    .document-upload-card:hover {
      border-color: #1976d2;
      box-shadow: 0 4px 12px rgba(25, 118, 210, 0.15);
    }

    .document-header {
      margin-bottom: 20px;
    }

    .document-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      color: #1976d2;
      margin-bottom: 12px;
    }

    .document-header h4 {
      margin: 0 0 8px 0;
      color: #333;
      font-size: 18px;
    }

    .document-header p {
      margin: 0;
      color: #666;
      font-size: 14px;
    }

    .upload-zone {
      border: 2px dashed #ccc;
      border-radius: 8px;
      padding: 30px 20px;
      margin-bottom: 20px;
      cursor: pointer;
      transition: all 0.3s ease;
    }

    .upload-zone:hover {
      border-color: #1976d2;
      background-color: #f5f5f5;
    }

    .upload-zone.has-file {
      border-color: #4caf50;
      background-color: #f1f8e9;
    }

    .upload-placeholder {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
    }

    .upload-placeholder mat-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
      color: #999;
    }

    .upload-placeholder span {
      color: #333;
      font-weight: 500;
    }

    .upload-placeholder small {
      color: #999;
      font-size: 12px;
    }

    .file-preview {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 4px;
    }

    .success-icon {
      color: #4caf50;
      font-size: 32px;
      width: 32px;
      height: 32px;
    }

    .file-preview span {
      color: #333;
      font-weight: 500;
      word-break: break-all;
      max-width: 100%;
    }

    .file-preview small {
      color: #666;
      font-size: 12px;
    }

    .upload-status {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      margin-top: 12px;
    }

    .upload-status .success {
      color: #4caf50;
    }

    .upload-status .error {
      color: #f44336;
    }

    .upload-summary {
      text-align: center;
      padding: 20px;
      background: #f5f5f5;
      border-radius: 8px;
    }

    .upload-summary h4 {
      margin: 0 0 16px 0;
      color: #333;
    }

    button {
      width: 100%;
    }

    mat-progress-spinner {
      display: inline-block;
    }
  `]
})
export class SimpleDocumentUploadComponent implements OnInit {
  @Input() shopId!: number;
  @Input() businessType!: string;
  @Output() documentsChanged = new EventEmitter<any>();

  // File selections
  ownerPhoto: File | null = null;
  shopPhoto: File | null = null;
  fssaiCert: File | null = null;

  // Upload states
  uploading = {
    OWNER_PHOTO: false,
    SHOP_PHOTO: false,
    FSSAI_CERTIFICATE: false
  };

  uploadStatus = {
    OWNER_PHOTO: '',
    SHOP_PHOTO: '',
    FSSAI_CERTIFICATE: ''
  };

  constructor(private documentService: DocumentService) {}

  ngOnInit() {
    // Check if documents already exist
    this.loadExistingDocuments();
  }

  loadExistingDocuments() {
    if (this.shopId) {
      this.documentService.getShopDocuments(this.shopId).subscribe({
        next: (docs) => {
          docs.forEach(doc => {
            if (doc.documentType === DocumentType.OWNER_PHOTO) {
              this.uploadStatus.OWNER_PHOTO = 'success';
            } else if (doc.documentType === DocumentType.SHOP_PHOTO) {
              this.uploadStatus.SHOP_PHOTO = 'success';
            } else if (doc.documentType === DocumentType.FSSAI_CERTIFICATE) {
              this.uploadStatus.FSSAI_CERTIFICATE = 'success';
            }
          });
        },
        error: (error) => console.error('Error loading documents:', error)
      });
    }
  }

  onFileSelected(event: any, type: string) {
    const file = event.target.files[0];
    if (file) {
      if (type === 'OWNER_PHOTO') {
        this.ownerPhoto = file;
        this.uploadStatus.OWNER_PHOTO = '';
      } else if (type === 'SHOP_PHOTO') {
        this.shopPhoto = file;
        this.uploadStatus.SHOP_PHOTO = '';
      } else if (type === 'FSSAI_CERTIFICATE') {
        this.fssaiCert = file;
        this.uploadStatus.FSSAI_CERTIFICATE = '';
      }
    }
  }

  uploadDocument(type: string, file: File) {
    if (!file || !this.shopId) return;

    const documentType = type as keyof typeof DocumentType;
    const typedType = DocumentType[documentType];
    const displayName = this.getDisplayName(type);

    this.uploading[type as keyof typeof this.uploading] = true;

    this.documentService.uploadDocument(
      this.shopId,
      typedType,
      displayName,
      file
    ).subscribe({
      next: (result) => {
        if (result.type === 'complete') {
          this.uploading[type as keyof typeof this.uploading] = false;
          this.uploadStatus[type as keyof typeof this.uploadStatus] = 'success';
          
          Swal.fire({
            title: 'Success!',
            text: `${displayName} uploaded successfully`,
            icon: 'success',
            confirmButtonColor: '#3085d6',
            timer: 2000
          });

          this.documentsChanged.emit();
        }
      },
      error: (error) => {
        this.uploading[type as keyof typeof this.uploading] = false;
        this.uploadStatus[type as keyof typeof this.uploadStatus] = 'error';
        
        Swal.fire({
          title: 'Upload Failed',
          text: `Failed to upload ${displayName}. Please try again.`,
          icon: 'error',
          confirmButtonColor: '#3085d6'
        });
      }
    });
  }

  getDisplayName(type: string): string {
    switch (type) {
      case 'OWNER_PHOTO': return 'Shop Owner Photo';
      case 'SHOP_PHOTO': return 'Shop Photo';
      case 'FSSAI_CERTIFICATE': return 'FSSAI Food Safety Certificate';
      default: return type;
    }
  }

  getUploadedCount(): number {
    let count = 0;
    if (this.uploadStatus.OWNER_PHOTO === 'success') count++;
    if (this.uploadStatus.SHOP_PHOTO === 'success') count++;
    if (this.uploadStatus.FSSAI_CERTIFICATE === 'success') count++;
    return count;
  }

  getProgressPercentage(): number {
    return (this.getUploadedCount() / 3) * 100;
  }

  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }
}