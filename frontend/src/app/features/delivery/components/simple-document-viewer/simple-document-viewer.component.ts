import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { DeliveryPartnerService, DeliveryPartnerDocument } from '../../services/delivery-partner.service';
import { environment } from '../../../../../environments/environment';

@Component({
  selector: 'app-simple-document-viewer',
  template: `
    <div class="simple-viewer-container">
      <div class="header">
        <h2>📄 {{ partnerName }} - Uploaded Documents</h2>
        <button mat-raised-button color="primary" (click)="goBack()">
          <mat-icon>arrow_back</mat-icon>
          Back to Users
        </button>
      </div>

      <div class="loading" *ngIf="loading">
        <mat-spinner></mat-spinner>
        <p>Loading documents...</p>
      </div>

      <div class="no-documents" *ngIf="!loading && documents.length === 0">
        <mat-icon>folder_open</mat-icon>
        <h3>No Documents Found</h3>
        <p>This delivery partner hasn't uploaded any documents yet.</p>
      </div>

      <div class="documents-grid" *ngIf="!loading && documents.length > 0">
        <div class="document-item" *ngFor="let document of documents">
          <div class="document-header">
            <h3>{{ getDocumentDisplayName(document.documentType) }}</h3>
            <mat-chip [class]="'status-chip status-' + document.verificationStatus.toLowerCase()">
              {{ document.verificationStatus }}
            </mat-chip>
          </div>

          <div class="document-info">
            <p><strong>Filename:</strong> {{ document.originalFilename }}</p>
            <p><strong>Size:</strong> {{ formatFileSize(document.fileSize) }}</p>
            <p><strong>Uploaded:</strong> {{ document.createdAt | date:'dd/MM/yyyy HH:mm' }}</p>
            <div *ngIf="document.licenseNumber || document.vehicleNumber" class="metadata">
              <p *ngIf="document.licenseNumber"><strong>License Number:</strong> {{ document.licenseNumber }}</p>
              <p *ngIf="document.vehicleNumber"><strong>Vehicle Number:</strong> {{ document.vehicleNumber }}</p>
            </div>
          </div>

          <div class="document-preview">
            <img *ngIf="isImageFile(document.fileType)"
                 [src]="getDocumentUrl(document)"
                 [alt]="document.documentName"
                 class="document-image"
                 (error)="onImageError($event, document)">

            <div *ngIf="!isImageFile(document.fileType)" class="non-image-file">
              <mat-icon>description</mat-icon>
              <p>{{ document.fileType }}</p>
              <a [href]="getDocumentUrl(document)" target="_blank" mat-raised-button color="primary">
                <mat-icon>download</mat-icon>
                Download
              </a>
            </div>
          </div>

          <div class="document-actions">
            <a [href]="getDocumentUrl(document)" target="_blank" mat-raised-button color="primary">
              <mat-icon>open_in_new</mat-icon>
              Open Full Size
            </a>
            <a [href]="getDocumentUrl(document)" download mat-raised-button color="accent">
              <mat-icon>download</mat-icon>
              Download
            </a>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .simple-viewer-container {
      padding: 20px;
      max-width: 1200px;
      margin: 0 auto;
    }

    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 30px;
      padding-bottom: 20px;
      border-bottom: 2px solid #e0e0e0;
    }

    .header h2 {
      margin: 0;
      color: #333;
    }

    .loading {
      text-align: center;
      padding: 40px;
    }

    .loading mat-spinner {
      margin: 0 auto 20px auto;
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
      margin-bottom: 20px;
      color: #ccc;
    }

    .documents-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
      gap: 30px;
      margin-top: 20px;
    }

    .document-item {
      border: 1px solid #ddd;
      border-radius: 12px;
      padding: 20px;
      background: white;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    }

    .document-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 15px;
    }

    .document-header h3 {
      margin: 0;
      color: #333;
      font-size: 18px;
    }

    .status-chip {
      font-size: 12px;
      padding: 4px 12px;
      border-radius: 16px;
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

    .document-info {
      margin-bottom: 20px;
    }

    .document-info p {
      margin: 5px 0;
      font-size: 14px;
      color: #666;
    }

    .metadata {
      margin-top: 10px;
      padding-top: 10px;
      border-top: 1px solid #eee;
    }

    .document-preview {
      margin-bottom: 20px;
      text-align: center;
      min-height: 200px;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #f8f9fa;
      border-radius: 8px;
      padding: 20px;
    }

    .document-image {
      max-width: 100%;
      max-height: 300px;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    }

    .non-image-file {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 10px;
      color: #666;
    }

    .non-image-file mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
    }

    .document-actions {
      display: flex;
      gap: 10px;
      justify-content: center;
    }

    .document-actions a {
      text-decoration: none;
    }
  `]
})
export class SimpleDocumentViewerComponent implements OnInit {
  partnerId!: number;
  partnerName = '';
  documents: DeliveryPartnerDocument[] = [];
  loading = true;

  constructor(
    private route: ActivatedRoute,
    private deliveryPartnerService: DeliveryPartnerService
  ) {}

  ngOnInit() {
    this.route.params.subscribe(params => {
      this.partnerId = +params['id'];
      this.partnerName = params['name'] || 'Delivery Partner';
      this.loadDocuments();
    });
  }

  loadDocuments() {
    this.loading = true;
    this.deliveryPartnerService.getPartnerDocuments(this.partnerId).subscribe({
      next: (response) => {
        this.documents = response.data || [];
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading documents:', error);
        this.loading = false;
      }
    });
  }

  getDocumentDisplayName(documentType: string): string {
    const displayNames: { [key: string]: string } = {
      'DRIVER_PHOTO': 'Driver Photo',
      'DRIVING_LICENSE': 'Driving License',
      'VEHICLE_PHOTO': 'Vehicle Photo',
      'RC_BOOK': 'RC Book'
    };
    return displayNames[documentType] || documentType.replace('_', ' ');
  }

  getDocumentUrl(document: DeliveryPartnerDocument): string {
    const baseUrl = environment.apiUrl || 'http://localhost:8080/api';
    // Use the public view endpoint without authentication requirements
    return `${baseUrl}/delivery/partners/documents/${document.id}/view`;
  }

  isImageFile(fileType?: string): boolean {
    return fileType ? fileType.startsWith('image/') : false;
  }

  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  onImageError(event: any, document: DeliveryPartnerDocument) {
    console.error('Image load error for document:', document.id);
    // Don't hide the image, instead show it with a placeholder
    event.target.alt = 'Image could not be loaded';
    event.target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjE1MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHJlY3Qgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgZmlsbD0iI2VlZWVlZSIvPgo8dGV4dCB4PSI1MCUiIHk9IjUwJSIgZm9udC1mYW1pbHk9IkFyaWFsIiBmb250LXNpemU9IjE0IiBmaWxsPSIjOTk5IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBkeT0iMC4zZW0iPkltYWdlIG5vdCBhdmFpbGFibGU8L3RleHQ+Cjwvc3ZnPg==';
  }

  goBack() {
    window.history.back();
  }
}