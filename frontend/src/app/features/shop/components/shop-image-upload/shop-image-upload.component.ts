import { Component, Input, Output, EventEmitter } from '@angular/core';
import { HttpClient, HttpEventType } from '@angular/common/http';
import { environment } from '@environments/environment';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-shop-image-upload',
  template: `
    <div class="image-upload-container">
      <mat-card>
        <mat-card-header>
          <mat-card-title>Shop Images</mat-card-title>
          <mat-card-subtitle>Upload images for your shop (Logo, Banner, Gallery)</mat-card-subtitle>
        </mat-card-header>
        
        <mat-card-content>
          <div class="upload-section">
            <div class="upload-area" (click)="fileInput.click()" 
                 (dragover)="onDragOver($event)" 
                 (dragleave)="onDragLeave($event)"
                 (drop)="onDrop($event)"
                 [class.drag-over]="isDragOver">
              <mat-icon class="upload-icon">cloud_upload</mat-icon>
              <h4>Drag & Drop Images Here</h4>
              <p>Or click to select files</p>
              <p class="upload-info">Supported: JPG, PNG, GIF, WEBP (Max 10MB each)</p>
              
              <input #fileInput type="file" multiple accept="image/*" 
                     (change)="onFileSelected($event)" style="display: none;">
            </div>

            <div class="upload-controls">
              <mat-form-field>
                <mat-label>Image Type</mat-label>
                <mat-select [(value)]="selectedImageType">
                  <mat-option value="LOGO">Logo</mat-option>
                  <mat-option value="BANNER">Banner</mat-option>
                  <mat-option value="GALLERY">Gallery</mat-option>
                </mat-select>
              </mat-form-field>

              <mat-checkbox [(ngModel)]="isPrimary" *ngIf="selectedImageType !== 'LOGO'">
                Set as Primary Image
              </mat-checkbox>
            </div>
          </div>

          <div class="image-preview" *ngIf="selectedFiles.length > 0">
            <h4>Selected Images ({{selectedFiles.length}})</h4>
            <div class="preview-grid">
              <div class="preview-item" *ngFor="let file of selectedFiles; let i = index">
                <img [src]="getImagePreview(file)" [alt]="file.name">
                <div class="preview-overlay">
                  <div class="preview-info">
                    <p class="file-name">{{file.name}}</p>
                    <p class="file-size">{{formatFileSize(file.size)}}</p>
                  </div>
                  <button mat-icon-button (click)="removeFile(i)" class="remove-btn">
                    <mat-icon>close</mat-icon>
                  </button>
                </div>
              </div>
            </div>
          </div>

          <div class="existing-images" *ngIf="existingImages.length > 0">
            <h4>Current Images</h4>
            <div class="existing-grid">
              <div class="existing-item" *ngFor="let image of existingImages">
                <img [src]="image.imageUrl" [alt]="image.imageType">
                <div class="existing-overlay">
                  <div class="existing-info">
                    <mat-chip [class]="'type-' + image.imageType.toLowerCase()">
                      {{image.imageType}}
                    </mat-chip>
                    <mat-chip *ngIf="image.isPrimary" class="primary-chip">Primary</mat-chip>
                  </div>
                  <button mat-icon-button (click)="deleteExistingImage(image)" class="delete-btn">
                    <mat-icon>delete</mat-icon>
                  </button>
                </div>
              </div>
            </div>
          </div>

          <div class="upload-progress" *ngIf="uploadProgress > 0 && uploadProgress < 100">
            <mat-progress-bar mode="determinate" [value]="uploadProgress"></mat-progress-bar>
            <p>Uploading... {{uploadProgress}}%</p>
          </div>
        </mat-card-content>

        <mat-card-actions>
          <button mat-button (click)="clearSelection()">Clear Selection</button>
          <button mat-raised-button color="primary" 
                  (click)="uploadImages()" 
                  [disabled]="selectedFiles.length === 0 || uploading">
            <mat-icon *ngIf="uploading">refresh</mat-icon>
            Upload Images ({{selectedFiles.length}})
          </button>
        </mat-card-actions>
      </mat-card>
    </div>
  `,
  styles: [`
    .image-upload-container {
      width: 100%;
    }

    .upload-section {
      margin-bottom: 30px;
    }

    .upload-area {
      border: 2px dashed #ccc;
      border-radius: 8px;
      padding: 40px 20px;
      text-align: center;
      cursor: pointer;
      transition: all 0.3s ease;
      margin-bottom: 20px;
    }

    .upload-area:hover, .upload-area.drag-over {
      border-color: #1976d2;
      background-color: #f5f5f5;
    }

    .upload-icon {
      font-size: 48px;
      height: 48px;
      width: 48px;
      color: #ccc;
      margin-bottom: 10px;
    }

    .upload-area h4 {
      margin: 10px 0 5px 0;
      color: #333;
    }

    .upload-area p {
      margin: 5px 0;
      color: #666;
    }

    .upload-info {
      font-size: 12px;
      color: #999;
    }

    .upload-controls {
      display: flex;
      align-items: center;
      gap: 20px;
      flex-wrap: wrap;
    }

    .image-preview, .existing-images {
      margin: 30px 0;
    }

    .preview-grid, .existing-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
      gap: 15px;
      margin-top: 15px;
    }

    .preview-item, .existing-item {
      position: relative;
      border-radius: 8px;
      overflow: hidden;
      aspect-ratio: 1;
    }

    .preview-item img, .existing-item img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    .preview-overlay, .existing-overlay {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0,0,0,0.7);
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      padding: 10px;
      opacity: 0;
      transition: opacity 0.3s ease;
    }

    .preview-item:hover .preview-overlay,
    .existing-item:hover .existing-overlay {
      opacity: 1;
    }

    .preview-info, .existing-info {
      color: white;
    }

    .file-name {
      font-size: 12px;
      margin: 0;
      word-break: break-all;
    }

    .file-size {
      font-size: 11px;
      margin: 2px 0 0 0;
      opacity: 0.8;
    }

    .remove-btn, .delete-btn {
      align-self: flex-end;
      color: white;
    }

    .type-logo { background-color: #4CAF50; }
    .type-banner { background-color: #2196F3; }
    .type-gallery { background-color: #FF9800; }
    
    .primary-chip {
      background-color: #E91E63;
      color: white;
      margin-left: 5px;
    }

    .upload-progress {
      margin: 20px 0;
      text-align: center;
    }

    .upload-progress p {
      margin-top: 10px;
      color: #666;
    }
  `]
})
export class ShopImageUploadComponent {
  @Input() shopId: number | null = null;
  @Input() existingImages: any[] = [];
  @Output() imagesUploaded = new EventEmitter<any[]>();
  @Output() imageDeleted = new EventEmitter<any>();

  selectedFiles: File[] = [];
  selectedImageType = 'GALLERY';
  isPrimary = false;
  isDragOver = false;
  uploading = false;
  uploadProgress = 0;

  constructor(private http: HttpClient) {}

  onFileSelected(event: any) {
    const files = Array.from(event.target.files) as File[];
    this.addFiles(files);
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
    
    const files = Array.from(event.dataTransfer?.files || []) as File[];
    this.addFiles(files);
  }

  private addFiles(files: File[]) {
    const validFiles = files.filter(file => {
      const isValidType = file.type.startsWith('image/');
      const isValidSize = file.size <= 10 * 1024 * 1024; // 10MB
      
      if (!isValidType) {
        console.warn(`${file.name} is not a valid image file`);
        return false;
      }
      
      if (!isValidSize) {
        console.warn(`${file.name} is too large (max 10MB)`);
        return false;
      }
      
      return true;
    });

    this.selectedFiles.push(...validFiles);
  }

  removeFile(index: number) {
    this.selectedFiles.splice(index, 1);
  }

  clearSelection() {
    this.selectedFiles = [];
    this.uploadProgress = 0;
  }

  getImagePreview(file: File): string {
    return URL.createObjectURL(file);
  }

  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  uploadImages() {
    if (!this.shopId || this.selectedFiles.length === 0) return;

    this.uploading = true;
    this.uploadProgress = 0;

    // Upload each file
    const uploadPromises = this.selectedFiles.map(file => {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('imageType', this.selectedImageType);
      formData.append('isPrimary', this.isPrimary.toString());

      return this.http.post<any>(
        `${environment.apiUrl}/shops/${this.shopId}/images`,
        formData,
        {
          reportProgress: true,
          observe: 'events'
        }
      );
    });

    // Handle all uploads
    let completedCount = 0;
    uploadPromises.forEach(upload => {
      upload.subscribe({
        next: (event: any) => {
          if (event.type === HttpEventType.UploadProgress) {
            const percentDone = Math.round(100 * event.loaded / (event.total || 1));
            this.uploadProgress = Math.round((completedCount + percentDone / this.selectedFiles.length) * 100 / this.selectedFiles.length);
          } else if (event.type === HttpEventType.Response) {
            completedCount++;
            if (completedCount === this.selectedFiles.length) {
              this.completeUpload();
            }
          }
        },
        error: (error) => {
          console.error('Upload failed:', error);
          this.uploading = false;
          this.uploadProgress = 0;
          Swal.fire({
            title: 'Upload Failed',
            text: 'Failed to upload images. Please try again.',
            icon: 'error',
            confirmButtonText: 'OK'
          });
        }
      });
    });
  }

  private completeUpload() {
    // Simulate successful upload
    const uploadedImages = this.selectedFiles.map((file, index) => ({
      id: Date.now() + index,
      shopId: this.shopId,
      imageUrl: this.getImagePreview(file),
      imageType: this.selectedImageType,
      isPrimary: this.isPrimary && index === 0,
      createdAt: new Date().toISOString()
    }));

    this.imagesUploaded.emit(uploadedImages);
    this.clearSelection();
    this.uploading = false;
    this.uploadProgress = 0;
  }

  deleteExistingImage(image: any) {
    Swal.fire({
      title: 'Delete Image',
      text: 'Are you sure you want to delete this image?',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, delete',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.imageDeleted.emit(image);
        Swal.fire('Deleted!', 'Image has been deleted.', 'success');
      }
    });
  }
}