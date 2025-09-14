import { Component, Input, Output, EventEmitter, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { DocumentService } from '../../../../core/services/document.service';
import { DeliveryPartnerService, DeliveryPartnerDocument, DeliveryPartnerDocumentType, DocumentVerificationStatus } from '../../services/delivery-partner.service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-delivery-partner-documents',
  template: `
    <div class="delivery-documents-container">
      <!-- Route Header (when used as standalone page) -->
      <div class="route-header" *ngIf="routePartnerId">
        <button mat-icon-button (click)="goBack()" class="back-btn">
          <mat-icon>arrow_back</mat-icon>
        </button>
        <div class="header-title">
          <h2>Document Management</h2>
          <p class="subtitle">Manage delivery partner documents</p>
        </div>
      </div>

      <div class="header" [class.embedded]="routePartnerId">
        <h3 *ngIf="!routePartnerId">🚚 Delivery Partner Documents</h3>
        <p class="subtitle" *ngIf="!routePartnerId">Upload required documents for driver verification</p>
      </div>

      <div class="documents-grid">

        <!-- 1. Driver Photo -->
        <div class="document-upload-card">
          <div class="document-header">
            <mat-icon class="document-icon">person</mat-icon>
            <h4>👤 Driver Photo</h4>
            <p>Upload clear photo of delivery partner</p>
          </div>

          <div class="upload-zone" (click)="driverPhotoInput.click()"
               [class.has-file]="driverPhoto">
            <input #driverPhotoInput type="file" (change)="onFileSelected($event, 'DRIVER_PHOTO')"
                   accept=".jpg,.jpeg,.png" style="display: none;">

            <div *ngIf="!driverPhoto" class="upload-placeholder">
              <mat-icon>cloud_upload</mat-icon>
              <span>Click to upload driver photo</span>
              <small>JPG, PNG (Max 5MB)</small>
            </div>

            <div *ngIf="driverPhoto" class="file-preview">
              <mat-icon class="success-icon">check_circle</mat-icon>
              <span>{{ driverPhoto.name }}</span>
              <small>{{ formatFileSize(driverPhoto.size) }}</small>
            </div>
          </div>

          <button mat-raised-button color="primary"
                  (click)="uploadDocument('DRIVER_PHOTO', driverPhoto!)"
                  [disabled]="!driverPhoto || uploading.DRIVER_PHOTO">
            <mat-icon *ngIf="!uploading.DRIVER_PHOTO">upload</mat-icon>
            <mat-progress-spinner *ngIf="uploading.DRIVER_PHOTO" diameter="20"></mat-progress-spinner>
            {{ uploading.DRIVER_PHOTO ? 'Uploading...' : 'Upload Driver Photo' }}
          </button>

          <div class="upload-status" *ngIf="uploadStatus.DRIVER_PHOTO">
            <mat-icon [class]="getStatusClass(uploadStatus.DRIVER_PHOTO)">
              {{ getStatusIcon(uploadStatus.DRIVER_PHOTO) }}
            </mat-icon>
            <span>{{ getStatusText(uploadStatus.DRIVER_PHOTO) }}</span>
          </div>
        </div>

        <!-- 2. Driving License -->
        <div class="document-upload-card">
          <div class="document-header">
            <mat-icon class="document-icon">card_membership</mat-icon>
            <h4>🪪 Driving License</h4>
            <p>Upload valid driving license (front & back)</p>
          </div>

          <div class="license-upload-section">
            <!-- License Front -->
            <div class="license-side">
              <h5>License Front</h5>
              <div class="upload-zone small" (click)="licenseFrontInput.click()"
                   [class.has-file]="licenseFront">
                <input #licenseFrontInput type="file" (change)="onFileSelected($event, 'LICENSE_FRONT')"
                       accept=".jpg,.jpeg,.png,.pdf" style="display: none;">

                <div *ngIf="!licenseFront" class="upload-placeholder">
                  <mat-icon>cloud_upload</mat-icon>
                  <span>Front side</span>
                </div>

                <div *ngIf="licenseFront" class="file-preview">
                  <mat-icon class="success-icon">check_circle</mat-icon>
                  <span>{{ licenseFront.name }}</span>
                </div>
              </div>
            </div>

            <!-- License Back -->
            <div class="license-side">
              <h5>License Back</h5>
              <div class="upload-zone small" (click)="licenseBackInput.click()"
                   [class.has-file]="licenseBack">
                <input #licenseBackInput type="file" (change)="onFileSelected($event, 'LICENSE_BACK')"
                       accept=".jpg,.jpeg,.png,.pdf" style="display: none;">

                <div *ngIf="!licenseBack" class="upload-placeholder">
                  <mat-icon>cloud_upload</mat-icon>
                  <span>Back side</span>
                </div>

                <div *ngIf="licenseBack" class="file-preview">
                  <mat-icon class="success-icon">check_circle</mat-icon>
                  <span>{{ licenseBack.name }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- License Number Input -->
          <mat-form-field appearance="outline" class="license-number-field">
            <mat-label>License Number</mat-label>
            <input matInput [(ngModel)]="licenseNumber" placeholder="Enter license number">
          </mat-form-field>

          <button mat-raised-button color="primary"
                  (click)="uploadLicenseDocuments()"
                  [disabled]="!canUploadLicense() || uploading.DRIVING_LICENSE">
            <mat-icon *ngIf="!uploading.DRIVING_LICENSE">upload</mat-icon>
            <mat-progress-spinner *ngIf="uploading.DRIVING_LICENSE" diameter="20"></mat-progress-spinner>
            {{ uploading.DRIVING_LICENSE ? 'Uploading...' : 'Upload License Documents' }}
          </button>

          <div class="upload-status" *ngIf="uploadStatus.DRIVING_LICENSE">
            <mat-icon [class]="getStatusClass(uploadStatus.DRIVING_LICENSE)">
              {{ getStatusIcon(uploadStatus.DRIVING_LICENSE) }}
            </mat-icon>
            <span>{{ getStatusText(uploadStatus.DRIVING_LICENSE) }}</span>
          </div>
        </div>

        <!-- 3. Vehicle Photo -->
        <div class="document-upload-card">
          <div class="document-header">
            <mat-icon class="document-icon">motorcycle</mat-icon>
            <h4>🏍️ Vehicle Photo</h4>
            <p>Upload clear photo of delivery vehicle</p>
          </div>

          <div class="upload-zone" (click)="vehiclePhotoInput.click()"
               [class.has-file]="vehiclePhoto">
            <input #vehiclePhotoInput type="file" (change)="onFileSelected($event, 'VEHICLE_PHOTO')"
                   accept=".jpg,.jpeg,.png" style="display: none;">

            <div *ngIf="!vehiclePhoto" class="upload-placeholder">
              <mat-icon>cloud_upload</mat-icon>
              <span>Click to upload vehicle photo</span>
              <small>JPG, PNG (Max 5MB)</small>
            </div>

            <div *ngIf="vehiclePhoto" class="file-preview">
              <mat-icon class="success-icon">check_circle</mat-icon>
              <span>{{ vehiclePhoto.name }}</span>
              <small>{{ formatFileSize(vehiclePhoto.size) }}</small>
            </div>
          </div>

          <!-- Vehicle Number Input -->
          <mat-form-field appearance="outline" class="vehicle-number-field">
            <mat-label>Vehicle Number</mat-label>
            <input matInput [(ngModel)]="vehicleNumber" placeholder="Enter vehicle number (e.g., TN01AB1234)">
          </mat-form-field>

          <button mat-raised-button color="primary"
                  (click)="uploadVehicleDocument()"
                  [disabled]="!canUploadVehicle() || uploading.VEHICLE_PHOTO">
            <mat-icon *ngIf="!uploading.VEHICLE_PHOTO">upload</mat-icon>
            <mat-progress-spinner *ngIf="uploading.VEHICLE_PHOTO" diameter="20"></mat-progress-spinner>
            {{ uploading.VEHICLE_PHOTO ? 'Uploading...' : 'Upload Vehicle Photo' }}
          </button>

          <div class="upload-status" *ngIf="uploadStatus.VEHICLE_PHOTO">
            <mat-icon [class]="getStatusClass(uploadStatus.VEHICLE_PHOTO)">
              {{ getStatusIcon(uploadStatus.VEHICLE_PHOTO) }}
            </mat-icon>
            <span>{{ getStatusText(uploadStatus.VEHICLE_PHOTO) }}</span>
          </div>
        </div>

        <!-- 4. RC Book -->
        <div class="document-upload-card">
          <div class="document-header">
            <mat-icon class="document-icon">description</mat-icon>
            <h4>📄 RC Book</h4>
            <p>Upload vehicle registration certificate</p>
          </div>

          <div class="upload-zone" (click)="rcBookInput.click()"
               [class.has-file]="rcBook">
            <input #rcBookInput type="file" (change)="onFileSelected($event, 'RC_BOOK')"
                   accept=".jpg,.jpeg,.png,.pdf" style="display: none;">

            <div *ngIf="!rcBook" class="upload-placeholder">
              <mat-icon>cloud_upload</mat-icon>
              <span>Click to upload RC book</span>
              <small>JPG, PNG, PDF (Max 5MB)</small>
            </div>

            <div *ngIf="rcBook" class="file-preview">
              <mat-icon class="success-icon">check_circle</mat-icon>
              <span>{{ rcBook.name }}</span>
              <small>{{ formatFileSize(rcBook.size) }}</small>
            </div>
          </div>

          <button mat-raised-button color="primary"
                  (click)="uploadDocument('RC_BOOK', rcBook!)"
                  [disabled]="!rcBook || uploading.RC_BOOK">
            <mat-icon *ngIf="!uploading.RC_BOOK">upload</mat-icon>
            <mat-progress-spinner *ngIf="uploading.RC_BOOK" diameter="20"></mat-progress-spinner>
            {{ uploading.RC_BOOK ? 'Uploading...' : 'Upload RC Book' }}
          </button>

          <div class="upload-status" *ngIf="uploadStatus.RC_BOOK">
            <mat-icon [class]="getStatusClass(uploadStatus.RC_BOOK)">
              {{ getStatusIcon(uploadStatus.RC_BOOK) }}
            </mat-icon>
            <span>{{ getStatusText(uploadStatus.RC_BOOK) }}</span>
          </div>
        </div>
      </div>

      <!-- Progress Summary -->
      <div class="upload-summary">
        <h4>Document Verification Progress: {{ getUploadedCount() }}/4 Documents</h4>
        <mat-progress-bar mode="determinate" [value]="getProgressPercentage()"></mat-progress-bar>

        <!-- Verification Status -->
        <div class="verification-checklist">
          <div class="checklist-item" [class]="hasDocument('DRIVER_PHOTO') ? 'completed' : 'pending'">
            <mat-icon>{{ hasDocument('DRIVER_PHOTO') ? 'check_circle' : 'radio_button_unchecked' }}</mat-icon>
            <span>Driver Photo</span>
          </div>
          <div class="checklist-item" [class]="hasDocument('DRIVING_LICENSE') ? 'completed' : 'pending'">
            <mat-icon>{{ hasDocument('DRIVING_LICENSE') ? 'check_circle' : 'radio_button_unchecked' }}</mat-icon>
            <span>Driving License</span>
          </div>
          <div class="checklist-item" [class]="hasDocument('VEHICLE_PHOTO') ? 'completed' : 'pending'">
            <mat-icon>{{ hasDocument('VEHICLE_PHOTO') ? 'check_circle' : 'radio_button_unchecked' }}</mat-icon>
            <span>Vehicle Photo & Number</span>
          </div>
          <div class="checklist-item" [class]="hasDocument('RC_BOOK') ? 'completed' : 'pending'">
            <mat-icon>{{ hasDocument('RC_BOOK') ? 'check_circle' : 'radio_button_unchecked' }}</mat-icon>
            <span>RC Book</span>
          </div>
        </div>

        <div class="completion-status" *ngIf="isAllDocumentsUploaded()">
          <mat-icon class="success">verified</mat-icon>
          <h5>All Documents Uploaded!</h5>
          <p>Your documents are under review. You'll be notified once verification is complete.</p>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .delivery-documents-container {
      padding: 24px;
    }

    .route-header {
      display: flex;
      align-items: center;
      gap: 16px;
      margin-bottom: 24px;
      padding: 20px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      border-radius: 16px;
      color: white;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
    }

    .back-btn {
      color: white;
      background: rgba(255, 255, 255, 0.1);
      border-radius: 50%;
      transition: all 0.3s ease;
    }

    .back-btn:hover {
      background: rgba(255, 255, 255, 0.2);
      transform: scale(1.1);
    }

    .header-title h2 {
      margin: 0 0 4px 0;
      font-size: 24px;
      font-weight: 600;
    }

    .header-title .subtitle {
      margin: 0;
      font-size: 14px;
      opacity: 0.9;
    }

    .header.embedded {
      display: none;
    }

    .header {
      margin-bottom: 24px;
      text-align: center;
    }

    .header h3 {
      margin: 0 0 8px 0;
      color: #1976d2;
      font-size: 24px;
    }

    .subtitle {
      margin: 0;
      color: #666;
      font-size: 16px;
    }

    .documents-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
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
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
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
      font-weight: 600;
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
      min-height: 120px;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .upload-zone.small {
      padding: 20px 15px;
      min-height: 80px;
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
      font-size: 14px;
    }

    .file-preview small {
      color: #666;
      font-size: 12px;
    }

    .license-upload-section {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      margin-bottom: 16px;
    }

    .license-side h5 {
      margin: 0 0 8px 0;
      color: #333;
      font-size: 14px;
      font-weight: 600;
    }

    .license-number-field,
    .vehicle-number-field {
      width: 100%;
      margin-bottom: 16px;
    }

    .upload-status {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      margin-top: 12px;
      padding: 8px;
      border-radius: 4px;
    }

    .upload-status .success {
      color: #4caf50;
    }

    .upload-status .error {
      color: #f44336;
    }

    .upload-status .pending {
      color: #ff9800;
    }

    .upload-summary {
      text-align: center;
      padding: 24px;
      background: #f8f9fa;
      border-radius: 12px;
      border: 1px solid #e9ecef;
    }

    .upload-summary h4 {
      margin: 0 0 16px 0;
      color: #333;
      font-size: 18px;
      font-weight: 600;
    }

    .verification-checklist {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 12px;
      margin: 24px 0;
    }

    .checklist-item {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px;
      border-radius: 8px;
      background: white;
      border: 1px solid #e0e0e0;
    }

    .checklist-item.completed {
      background: #f1f8e9;
      border-color: #4caf50;
    }

    .checklist-item.completed mat-icon {
      color: #4caf50;
    }

    .checklist-item.pending mat-icon {
      color: #9ca3af;
    }

    .checklist-item span {
      color: #333;
      font-weight: 500;
    }

    .completion-status {
      background: #e8f5e8;
      border: 1px solid #4caf50;
      border-radius: 8px;
      padding: 20px;
      margin-top: 20px;
    }

    .completion-status .success {
      color: #4caf50;
      font-size: 48px;
      width: 48px;
      height: 48px;
      margin-bottom: 12px;
    }

    .completion-status h5 {
      margin: 0 0 8px 0;
      color: #2e7d32;
      font-size: 18px;
      font-weight: 600;
    }

    .completion-status p {
      margin: 0;
      color: #2e7d32;
      font-size: 14px;
    }

    button {
      width: 100%;
      margin-bottom: 12px;
    }

    mat-progress-spinner {
      display: inline-block;
    }

    mat-form-field {
      width: 100%;
    }
  `]
})
export class DeliveryPartnerDocumentsComponent implements OnInit {
  @Input() partnerId: number | null = null;
  @Input() readonly = false;
  @Input() isAdmin = false;
  @Output() documentsChanged = new EventEmitter<DeliveryPartnerDocument[]>();

  // For route-based usage
  routePartnerId: number | null = null;

  // File selections
  driverPhoto: File | null = null;
  licenseFront: File | null = null;
  licenseBack: File | null = null;
  vehiclePhoto: File | null = null;
  rcBook: File | null = null;

  // Additional fields
  licenseNumber = '';
  vehicleNumber = '';

  // Upload states
  uploading = {
    DRIVER_PHOTO: false,
    DRIVING_LICENSE: false,
    VEHICLE_PHOTO: false,
    RC_BOOK: false
  };

  uploadStatus = {
    DRIVER_PHOTO: '',
    DRIVING_LICENSE: '',
    VEHICLE_PHOTO: '',
    RC_BOOK: ''
  };

  documents: DeliveryPartnerDocument[] = [];

  constructor(
    private documentService: DocumentService,
    private deliveryPartnerService: DeliveryPartnerService,
    private route: ActivatedRoute,
    private router: Router
  ) {}

  ngOnInit() {
    // Check if we're being used as a routed component
    const routeId = this.route.snapshot.paramMap.get('id');
    if (routeId) {
      this.routePartnerId = parseInt(routeId, 10);
      this.isAdmin = true; // Admin view when accessed via route
    }

    this.loadExistingDocuments();
  }

  loadExistingDocuments() {
    const partnerIdToUse = this.partnerId || this.routePartnerId;
    if (partnerIdToUse) {
      this.deliveryPartnerService.getPartnerDocuments(partnerIdToUse).subscribe({
        next: (response) => {
          this.documents = response.data || [];
          this.updateUploadStatus();
        },
        error: (error) => {
          console.error('Error loading documents for partner:', partnerIdToUse, error);
        }
      });
    }
  }

  private updateUploadStatus() {
    // Update upload status based on existing documents
    this.documents.forEach(doc => {
      if (doc.documentType === 'DRIVER_PHOTO') {
        this.uploadStatus.DRIVER_PHOTO = 'success';
      } else if (doc.documentType === 'DRIVING_LICENSE') {
        this.uploadStatus.DRIVING_LICENSE = 'success';
        this.licenseNumber = doc.licenseNumber || '';
      } else if (doc.documentType === 'VEHICLE_PHOTO') {
        this.uploadStatus.VEHICLE_PHOTO = 'success';
        this.vehicleNumber = doc.vehicleNumber || '';
      } else if (doc.documentType === 'RC_BOOK') {
        this.uploadStatus.RC_BOOK = 'success';
      }
    });
  }

  onFileSelected(event: any, type: string) {
    const file = event.target.files[0];
    if (file && this.validateFile(file, type)) {
      switch (type) {
        case 'DRIVER_PHOTO':
          this.driverPhoto = file;
          this.uploadStatus.DRIVER_PHOTO = '';
          break;
        case 'LICENSE_FRONT':
          this.licenseFront = file;
          break;
        case 'LICENSE_BACK':
          this.licenseBack = file;
          break;
        case 'VEHICLE_PHOTO':
          this.vehiclePhoto = file;
          this.uploadStatus.VEHICLE_PHOTO = '';
          break;
        case 'RC_BOOK':
          this.rcBook = file;
          this.uploadStatus.RC_BOOK = '';
          break;
      }
    }
  }

  validateFile(file: File, type: string): boolean {
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (file.size > maxSize) {
      Swal.fire({
        title: 'File Too Large',
        text: 'File size must be less than 5MB',
        icon: 'error'
      });
      return false;
    }
    return true;
  }

  canUploadLicense(): boolean {
    return !!(this.licenseFront && this.licenseBack && this.licenseNumber.trim());
  }

  canUploadVehicle(): boolean {
    return !!(this.vehiclePhoto && this.vehicleNumber.trim());
  }

  uploadDocument(type: string, file: File) {
    const partnerIdToUse = this.partnerId || this.routePartnerId;
    if (!file || !partnerIdToUse) return;

    const documentType = type as keyof typeof DeliveryPartnerDocumentType;
    const typedType = DeliveryPartnerDocumentType[documentType];
    const displayName = this.getDisplayName(type);

    this.uploading[type as keyof typeof this.uploading] = true;

    this.deliveryPartnerService.uploadPartnerDocument(
      partnerIdToUse,
      typedType,
      displayName,
      file
    ).subscribe({
      next: (result) => {
        if (result.type === 'progress') {
          // Handle progress if needed
        } else if (result.type === 'complete') {
          this.uploading[type as keyof typeof this.uploading] = false;
          this.uploadStatus[type as keyof typeof this.uploadStatus] = 'success';

          Swal.fire({
            title: 'Success!',
            text: `${displayName} uploaded successfully`,
            icon: 'success',
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
          icon: 'error'
        });
      }
    });
  }

  uploadLicenseDocuments() {
    if (!this.canUploadLicense()) return;

    const partnerIdToUse = this.partnerId || this.routePartnerId;
    if (!partnerIdToUse) return;

    this.uploading.DRIVING_LICENSE = true;

    // Upload license front and back as separate documents with metadata
    const metadata = { licenseNumber: this.licenseNumber };

    this.deliveryPartnerService.uploadPartnerDocument(
      partnerIdToUse,
      DeliveryPartnerDocumentType.DRIVING_LICENSE,
      'Driving License',
      this.licenseFront!,
      metadata
    ).subscribe({
      next: (result) => {
        if (result.type === 'complete') {
          this.uploading.DRIVING_LICENSE = false;
          this.uploadStatus.DRIVING_LICENSE = 'success';

          Swal.fire({
            title: 'Success!',
            text: 'Driving license documents uploaded successfully',
            icon: 'success',
            timer: 2000
          });

          this.documentsChanged.emit();
        }
      },
      error: (error) => {
        this.uploading.DRIVING_LICENSE = false;
        this.uploadStatus.DRIVING_LICENSE = 'error';

        Swal.fire({
          title: 'Upload Failed',
          text: 'Failed to upload driving license documents. Please try again.',
          icon: 'error'
        });
      }
    });
  }

  uploadVehicleDocument() {
    if (!this.canUploadVehicle()) return;

    const partnerIdToUse = this.partnerId || this.routePartnerId;
    if (!partnerIdToUse) return;

    this.uploading.VEHICLE_PHOTO = true;
    const metadata = { vehicleNumber: this.vehicleNumber };

    this.deliveryPartnerService.uploadPartnerDocument(
      partnerIdToUse,
      DeliveryPartnerDocumentType.VEHICLE_PHOTO,
      'Vehicle Photo',
      this.vehiclePhoto!,
      metadata
    ).subscribe({
      next: (result) => {
        if (result.type === 'complete') {
          this.uploading.VEHICLE_PHOTO = false;
          this.uploadStatus.VEHICLE_PHOTO = 'success';

          Swal.fire({
            title: 'Success!',
            text: 'Vehicle photo and details uploaded successfully',
            icon: 'success',
            timer: 2000
          });

          this.documentsChanged.emit();
        }
      },
      error: (error) => {
        this.uploading.VEHICLE_PHOTO = false;
        this.uploadStatus.VEHICLE_PHOTO = 'error';

        Swal.fire({
          title: 'Upload Failed',
          text: 'Failed to upload vehicle document. Please try again.',
          icon: 'error'
        });
      }
    });
  }

  getDisplayName(type: string): string {
    switch (type) {
      case 'DRIVER_PHOTO': return 'Driver Photo';
      case 'DRIVING_LICENSE': return 'Driving License';
      case 'VEHICLE_PHOTO': return 'Vehicle Photo';
      case 'RC_BOOK': return 'RC Book';
      default: return type;
    }
  }

  hasDocument(type: string): boolean {
    return this.uploadStatus[type as keyof typeof this.uploadStatus] === 'success';
  }

  getUploadedCount(): number {
    let count = 0;
    if (this.uploadStatus.DRIVER_PHOTO === 'success') count++;
    if (this.uploadStatus.DRIVING_LICENSE === 'success') count++;
    if (this.uploadStatus.VEHICLE_PHOTO === 'success') count++;
    if (this.uploadStatus.RC_BOOK === 'success') count++;
    return count;
  }

  getProgressPercentage(): number {
    return (this.getUploadedCount() / 4) * 100;
  }

  isAllDocumentsUploaded(): boolean {
    return this.getUploadedCount() === 4;
  }

  getStatusClass(status: string): string {
    switch (status) {
      case 'success': return 'success';
      case 'error': return 'error';
      default: return 'pending';
    }
  }

  getStatusIcon(status: string): string {
    switch (status) {
      case 'success': return 'check_circle';
      case 'error': return 'error';
      default: return 'pending';
    }
  }

  getStatusText(status: string): string {
    switch (status) {
      case 'success': return 'Uploaded Successfully';
      case 'error': return 'Upload Failed';
      default: return 'Upload Pending';
    }
  }

  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  goBack(): void {
    this.router.navigate(['/users']);
  }
}