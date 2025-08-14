import { Component, Input, Output, EventEmitter, OnInit } from '@angular/core';
import { HttpClient, HttpEventType } from '@angular/common/http';
import { MatSnackBar } from '@angular/material/snack-bar';
import { ProductImage } from '../../../../core/models/product.model';
import { CdkDragDrop, moveItemInArray } from '@angular/cdk/drag-drop';

@Component({
  selector: 'app-product-image-upload',
  template: `
    <div class="image-upload-container">
      <div class="upload-header">
        <h3>{{ title }}</h3>
        <div class="upload-info">
          <p>Upload up to 10 images (max 5MB each). Supported formats: JPG, PNG, GIF, WebP</p>
        </div>
      </div>

      <!-- File Upload Area -->
      <div class="upload-area" 
           [class.drag-over]="isDragOver"
           (dragover)="onDragOver($event)"
           (dragleave)="onDragLeave($event)"
           (drop)="onDrop($event)"
           (click)="fileInput.click()">
        
        <input #fileInput
               type="file"
               multiple
               accept="image/*"
               (change)="onFilesSelected($event)"
               style="display: none;">

        <div class="upload-content">
          <mat-icon class="upload-icon">cloud_upload</mat-icon>
          <h4>Drop images here or click to browse</h4>
          <p>Choose multiple images to upload</p>
        </div>
      </div>

      <!-- Upload Progress -->
      <div *ngIf="uploadProgress > 0 && uploadProgress < 100" class="upload-progress">
        <mat-progress-bar [value]="uploadProgress"></mat-progress-bar>
        <p>Uploading... {{ uploadProgress }}%</p>
      </div>

      <!-- Image Gallery -->
      <div *ngIf="images.length > 0" class="image-gallery">
        <h4>{{ images.length }} Image{{ images.length > 1 ? 's' : '' }}</h4>
        
        <div class="images-grid" cdkDropList (cdkDropListDropped)="onImageReorder($event)">
          <div *ngFor="let image of images; trackBy: trackByImageId; let i = index"
               class="image-item"
               cdkDrag
               [class.primary]="image.isPrimary">
            
            <div class="image-container">
              <img [src]="getImageUrl(image)" 
                   [alt]="image.altText || 'Product image'"
                   (error)="onImageError($event)">
              
              <!-- Primary Badge -->
              <div *ngIf="image.isPrimary" class="primary-badge">
                <mat-chip color="primary">Primary</mat-chip>
              </div>
              
              <!-- Image Actions -->
              <div class="image-actions">
                <button mat-icon-button 
                        color="primary"
                        matTooltip="Set as primary image"
                        *ngIf="!image.isPrimary"
                        (click)="setPrimaryImage(image)">
                  <mat-icon>star_border</mat-icon>
                </button>
                
                <button mat-icon-button 
                        color="accent"
                        matTooltip="Edit image details"
                        (click)="editImage(image)">
                  <mat-icon>edit</mat-icon>
                </button>
                
                <button mat-icon-button 
                        color="warn"
                        matTooltip="Delete image"
                        (click)="deleteImage(image)">
                  <mat-icon>delete</mat-icon>
                </button>
              </div>
            </div>
            
            <!-- Image Info -->
            <div class="image-info">
              <mat-form-field appearance="outline" class="alt-text-field">
                <mat-label>Alt text</mat-label>
                <input matInput 
                       [(ngModel)]="image.altText"
                       (blur)="updateImageDetails(image)"
                       placeholder="Describe this image">
              </mat-form-field>
            </div>
            
            <!-- Drag Handle -->
            <div class="drag-handle" cdkDragHandle>
              <mat-icon>drag_indicator</mat-icon>
            </div>
          </div>
        </div>
        
        <!-- No Images State -->
        <div *ngIf="images.length === 0" class="no-images">
          <mat-icon>photo_library</mat-icon>
          <p>No images uploaded yet</p>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .image-upload-container {
      width: 100%;
    }

    .upload-header {
      margin-bottom: 16px;
    }

    .upload-header h3 {
      margin: 0 0 8px 0;
      color: #333;
    }

    .upload-info p {
      font-size: 14px;
      color: #666;
      margin: 0;
    }

    .upload-area {
      border: 2px dashed #ddd;
      border-radius: 8px;
      padding: 40px 20px;
      text-align: center;
      cursor: pointer;
      transition: all 0.3s ease;
      background: #fafafa;
    }

    .upload-area:hover, .upload-area.drag-over {
      border-color: #3f51b5;
      background: #f5f7ff;
    }

    .upload-content {
      pointer-events: none;
    }

    .upload-icon {
      font-size: 48px;
      height: 48px;
      width: 48px;
      color: #999;
      margin-bottom: 16px;
    }

    .upload-content h4 {
      margin: 0 0 8px 0;
      color: #333;
    }

    .upload-content p {
      margin: 0;
      color: #666;
      font-size: 14px;
    }

    .upload-progress {
      margin: 16px 0;
    }

    .upload-progress p {
      margin: 8px 0 0 0;
      text-align: center;
      font-size: 14px;
      color: #666;
    }

    .image-gallery {
      margin-top: 24px;
    }

    .image-gallery h4 {
      margin: 0 0 16px 0;
      color: #333;
    }

    .images-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 16px;
    }

    .image-item {
      border: 1px solid #e0e0e0;
      border-radius: 8px;
      overflow: hidden;
      background: #fff;
      transition: all 0.3s ease;
      position: relative;
    }

    .image-item:hover {
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    }

    .image-item.primary {
      border-color: #3f51b5;
      box-shadow: 0 0 0 2px rgba(63, 81, 181, 0.2);
    }

    .image-container {
      position: relative;
      aspect-ratio: 1;
      overflow: hidden;
    }

    .image-container img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      display: block;
    }

    .primary-badge {
      position: absolute;
      top: 8px;
      left: 8px;
    }

    .image-actions {
      position: absolute;
      top: 8px;
      right: 8px;
      display: flex;
      gap: 4px;
      opacity: 0;
      transition: opacity 0.3s ease;
      background: rgba(255,255,255,0.9);
      border-radius: 20px;
      padding: 4px;
    }

    .image-item:hover .image-actions {
      opacity: 1;
    }

    .image-info {
      padding: 16px;
    }

    .alt-text-field {
      width: 100%;
    }

    .drag-handle {
      position: absolute;
      bottom: 8px;
      right: 8px;
      cursor: grab;
      background: rgba(255,255,255,0.9);
      border-radius: 4px;
      padding: 4px;
      opacity: 0;
      transition: opacity 0.3s ease;
    }

    .image-item:hover .drag-handle {
      opacity: 1;
    }

    .drag-handle:active {
      cursor: grabbing;
    }

    .no-images {
      text-align: center;
      padding: 40px;
      color: #999;
    }

    .no-images mat-icon {
      font-size: 48px;
      height: 48px;
      width: 48px;
      margin-bottom: 16px;
    }

    .cdk-drag-preview {
      box-sizing: border-box;
      border-radius: 8px;
      box-shadow: 0 5px 5px -3px rgba(0, 0, 0, 0.2),
                  0 8px 10px 1px rgba(0, 0, 0, 0.14),
                  0 3px 14px 2px rgba(0, 0, 0, 0.12);
    }

    .cdk-drag-placeholder {
      opacity: 0;
    }

    .cdk-drag-animating {
      transition: transform 250ms cubic-bezier(0, 0, 0.2, 1);
    }

    .images-grid.cdk-drop-list-dragging .image-item:not(.cdk-drag-placeholder) {
      transition: transform 250ms cubic-bezier(0, 0, 0.2, 1);
    }

    @media (max-width: 768px) {
      .images-grid {
        grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
        gap: 12px;
      }

      .upload-area {
        padding: 30px 15px;
      }

      .image-info {
        padding: 12px;
      }
    }
  `]
})
export class ProductImageUploadComponent implements OnInit {
  @Input() title = 'Product Images';
  @Input() productId!: number;
  @Input() shopId?: number; // For shop products
  @Input() productType: 'master' | 'shop' = 'master';
  @Input() images: ProductImage[] = [];
  @Output() imagesChange = new EventEmitter<ProductImage[]>();
  @Output() imagesUploaded = new EventEmitter<ProductImage[]>();

  isDragOver = false;
  uploadProgress = 0;

  constructor(
    private http: HttpClient,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadImages();
  }

  onDragOver(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragOver = true;
  }

  onDragLeave(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragOver = false;
  }

  onDrop(event: DragEvent): void {
    event.preventDefault();
    event.stopPropagation();
    this.isDragOver = false;

    const files = event.dataTransfer?.files;
    if (files) {
      this.uploadFiles(Array.from(files));
    }
  }

  onFilesSelected(event: any): void {
    const files = event.target.files;
    if (files) {
      this.uploadFiles(Array.from(files));
    }
  }

  private uploadFiles(files: File[]): void {
    if (files.length === 0) return;

    // Validate files
    const validFiles = files.filter(file => this.validateFile(file));
    if (validFiles.length === 0) return;

    const formData = new FormData();
    validFiles.forEach(file => {
      formData.append('images', file);
    });

    const url = this.productType === 'master' 
      ? `/api/products/images/master/${this.productId}`
      : `/api/products/images/shop/${this.shopId}/${this.productId}`;

    this.uploadProgress = 0;

    this.http.post<any>(url, formData, {
      reportProgress: true,
      observe: 'events'
    }).subscribe({
      next: (event) => {
        if (event.type === HttpEventType.UploadProgress) {
          this.uploadProgress = Math.round(100 * event.loaded / (event.total || 1));
        } else if (event.type === HttpEventType.Response) {
          this.uploadProgress = 100;
          const uploadedImages = event.body.data;
          this.images.push(...uploadedImages);
          this.imagesChange.emit(this.images);
          this.imagesUploaded.emit(uploadedImages);
          this.snackBar.open(`${uploadedImages.length} images uploaded successfully`, 'Close', { duration: 3000 });
          
          setTimeout(() => {
            this.uploadProgress = 0;
          }, 1000);
        }
      },
      error: (error) => {
        console.error('Upload failed:', error);
        this.uploadProgress = 0;
        this.snackBar.open('Upload failed. Please try again.', 'Close', { duration: 3000 });
      }
    });
  }

  private validateFile(file: File): boolean {
    // Check file type
    if (!file.type.startsWith('image/')) {
      this.snackBar.open(`${file.name} is not a valid image file`, 'Close', { duration: 3000 });
      return false;
    }

    // Check file size (5MB limit)
    const maxSize = 5 * 1024 * 1024;
    if (file.size > maxSize) {
      this.snackBar.open(`${file.name} is too large (max 5MB)`, 'Close', { duration: 3000 });
      return false;
    }

    return true;
  }

  private loadImages(): void {
    const url = this.productType === 'master' 
      ? `/api/products/images/master/${this.productId}`
      : `/api/products/images/shop/${this.shopId}/${this.productId}`;

    this.http.get<any>(url).subscribe({
      next: (response) => {
        this.images = response.data || [];
        this.imagesChange.emit(this.images);
      },
      error: (error) => {
        console.error('Failed to load images:', error);
      }
    });
  }

  getImageUrl(image: ProductImage): string {
    return image.imageUrl;
  }

  onImageError(event: any): void {
    event.target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTIxIDMuMDE2QzIxIDIuNDU2IDIwLjU0NCAyIDIwIDJINEMzLjQ1NiAyIDMgMi40NTYgMyAzLjAxNlY5TDE5IDlWMy4wMTZaIiBmaWxsPSIjRTBFMEUwIi8+CjxwYXRoIGQ9Ik0zIDlMMjEgOVYyMC45ODRDMjEgMjEuNTQ0IDIwLjU0NCAyMiAyMCAyMkg0QzMuNDU2IDIyIDMgMjEuNTQ0IDMgMjAuOTg0VjlaIiBmaWxsPSIjRjVGNUY1Ii8+CjxjaXJjbGUgY3g9IjcuNSIgY3k9IjYuNSIgcj0iMS41IiBmaWxsPSIjRDBEMEQwIi8+CjxwYXRoIGQ9Ik0zIDE5TDggMTRMMTEgMTdMMTcgMTFMMjEgMTVWMjBIMlYxOUgzWiIgZmlsbD0iI0QwRDBEMCIvPgo8L3N2Zz4K';
  }

  setPrimaryImage(image: ProductImage): void {
    this.http.patch<any>(`/api/products/images/${image.id}/primary`, {}).subscribe({
      next: (response) => {
        // Update local state
        this.images.forEach(img => img.isPrimary = false);
        const updatedImage = this.images.find(img => img.id === image.id);
        if (updatedImage) {
          updatedImage.isPrimary = true;
        }
        this.imagesChange.emit(this.images);
        this.snackBar.open('Primary image updated', 'Close', { duration: 2000 });
      },
      error: (error) => {
        console.error('Failed to set primary image:', error);
        this.snackBar.open('Failed to update primary image', 'Close', { duration: 3000 });
      }
    });
  }

  editImage(image: ProductImage): void {
    // Could open a dialog for editing image details
    console.log('Edit image:', image);
  }

  deleteImage(image: ProductImage): void {
    if (confirm('Are you sure you want to delete this image?')) {
      this.http.delete<any>(`/api/products/images/${image.id}`).subscribe({
        next: () => {
          this.images = this.images.filter(img => img.id !== image.id);
          this.imagesChange.emit(this.images);
          this.snackBar.open('Image deleted successfully', 'Close', { duration: 2000 });
        },
        error: (error) => {
          console.error('Failed to delete image:', error);
          this.snackBar.open('Failed to delete image', 'Close', { duration: 3000 });
        }
      });
    }
  }

  updateImageDetails(image: ProductImage): void {
    this.http.put<any>(`/api/products/images/${image.id}`, {
      altText: image.altText
    }).subscribe({
      next: (response) => {
        // Image details updated
      },
      error: (error) => {
        console.error('Failed to update image details:', error);
      }
    });
  }

  onImageReorder(event: CdkDragDrop<ProductImage[]>): void {
    if (event.previousIndex !== event.currentIndex) {
      moveItemInArray(this.images, event.previousIndex, event.currentIndex);
      
      // Update sort order
      this.images.forEach((img, index) => {
        img.sortOrder = index;
      });
      
      const imageIds = this.images.map(img => img.id);
      this.http.post<any>(`/api/products/images/${this.images[0].id}/reorder`, imageIds).subscribe({
        next: () => {
          this.imagesChange.emit(this.images);
        },
        error: (error) => {
          console.error('Failed to reorder images:', error);
          // Revert the change
          this.loadImages();
        }
      });
    }
  }

  trackByImageId(index: number, image: ProductImage): number {
    return image.id;
  }
}