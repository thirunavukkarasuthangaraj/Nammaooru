import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { ShopService } from '../../../../core/services/shop.service';
import { DocumentService } from '../../../../core/services/document.service';
import { Shop } from '../../../../core/models/shop.model';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-shop-approval',
  template: `
    <div class="approval-container">
      <!-- Header -->
      <div class="approval-header">
        <div class="header-content">
          <button mat-icon-button (click)="goBack()" class="back-button">
            <mat-icon>arrow_back</mat-icon>
          </button>
          <div class="title-section">
            <h1 class="page-title">Shop Verification & Approval</h1>
            <p class="page-subtitle">Review shop details and documents before approval</p>
          </div>
        </div>
        <div class="status-indicator" [ngClass]="getStatusClass(shop?.status)">
          <mat-icon>{{ getStatusIcon(shop?.status) }}</mat-icon>
          <span>{{ getStatusDisplay(shop?.status) }}</span>
        </div>
      </div>

      <div class="approval-content" *ngIf="shop && !loading">
        <!-- Shop Information Card -->
        <mat-card class="info-card">
          <mat-card-header>
            <div mat-card-avatar class="shop-avatar">
              <img *ngIf="getShopLogo()" [src]="getShopLogo()" [alt]="shop.name" />
              <mat-icon *ngIf="!getShopLogo()">store</mat-icon>
            </div>
            <mat-card-title>{{ shop.name }}</mat-card-title>
            <mat-card-subtitle>{{ shop.businessName }}</mat-card-subtitle>
          </mat-card-header>
          <mat-card-content>
            <div class="info-grid">
              <div class="info-section">
                <h3><mat-icon>business</mat-icon> Business Details</h3>
                <div class="info-item">
                  <span class="label">Business Type:</span>
                  <mat-chip [ngClass]="getBusinessTypeClass(shop.businessType)">
                    {{ getBusinessTypeDisplay(shop.businessType) }}
                  </mat-chip>
                </div>
                <div class="info-item">
                  <span class="label">Registration Date:</span>
                  <span>{{ shop.createdAt | date:'MMM dd, yyyy' }}</span>
                </div>
                <div class="info-item">
                  <span class="label">GST Number:</span>
                  <span>{{ shop.gstNumber || 'Not provided' }}</span>
                </div>
                <div class="info-item">
                  <span class="label">License Number:</span>
                  <span>{{ shop.gstNumber || shop.panNumber || 'Not provided' }}</span>
                </div>
              </div>

              <div class="info-section">
                <h3><mat-icon>person</mat-icon> Owner Information</h3>
                <div class="info-item">
                  <span class="label">Owner Name:</span>
                  <span>{{ shop.ownerName }}</span>
                </div>
                <div class="info-item">
                  <span class="label">Email:</span>
                  <span>{{ shop.ownerEmail || 'Not provided' }}</span>
                </div>
                <div class="info-item">
                  <span class="label">Phone:</span>
                  <span>{{ shop.ownerPhone || 'Not provided' }}</span>
                </div>
                <div class="info-item">
                  <span class="label">Alternate Phone:</span>
                  <span>Not provided</span>
                </div>
              </div>

              <div class="info-section">
                <h3><mat-icon>location_on</mat-icon> Location Details</h3>
                <div class="info-item">
                  <span class="label">Address:</span>
                  <span>{{ shop.addressLine1 }}</span>
                </div>
                <div class="info-item">
                  <span class="label">City, State:</span>
                  <span>{{ shop.city }}, {{ shop.state }}</span>
                </div>
                <div class="info-item">
                  <span class="label">Postal Code:</span>
                  <span>{{ shop.postalCode }}</span>
                </div>
                <div class="info-item">
                  <span class="label">Country:</span>
                  <span>{{ shop.country || 'India' }}</span>
                </div>
              </div>

              <div class="info-section">
                <h3><mat-icon>local_shipping</mat-icon> Service Information</h3>
                <div class="info-item">
                  <span class="label">Delivery Available:</span>
                  <mat-chip [ngClass]="(shop.deliveryRadius && shop.deliveryRadius > 0) ? 'status-available' : 'status-unavailable'">
                    {{ (shop.deliveryRadius && shop.deliveryRadius > 0) ? 'Yes' : 'No' }}
                  </mat-chip>
                </div>
                <div class="info-item" *ngIf="shop.deliveryRadius && shop.deliveryRadius > 0">
                  <span class="label">Delivery Fee:</span>
                  <span>₹{{ shop.deliveryFee || 0 }}</span>
                </div>
                <div class="info-item" *ngIf="shop.deliveryRadius && shop.deliveryRadius > 0">
                  <span class="label">Delivery Radius:</span>
                  <span>{{ shop.deliveryRadius || 0 }} km</span>
                </div>
                <div class="info-item">
                  <span class="label">Min Order Amount:</span>
                  <span>₹{{ shop.minOrderAmount || 0 }}</span>
                </div>
                <div class="info-item">
                  <span class="label">Operating Hours:</span>
                  <span>{{ getOperatingHours() }}</span>
                </div>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <!-- Shop Statistics Card -->
        <mat-card class="stats-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>analytics</mat-icon>
              Shop Statistics
            </mat-card-title>
            <mat-card-subtitle>Performance metrics and overview</mat-card-subtitle>
          </mat-card-header>
          <mat-card-content>
            <div class="stats-grid">
              <div class="stat-item">
                <div class="stat-icon">
                  <mat-icon color="primary">inventory</mat-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-number">{{ shopStats.totalProducts || 0 }}</div>
                  <div class="stat-label">Total Products</div>
                </div>
              </div>
              
              <div class="stat-item">
                <div class="stat-icon">
                  <mat-icon color="accent">shopping_cart</mat-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-number">{{ shopStats.totalOrders || 0 }}</div>
                  <div class="stat-label">Total Orders</div>
                </div>
              </div>
              
              <div class="stat-item">
                <div class="stat-icon">
                  <mat-icon style="color: #10b981;">currency_rupee</mat-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-number">₹{{ shopStats.totalRevenue || 0 | number:'1.0-0' }}</div>
                  <div class="stat-label">Total Revenue</div>
                </div>
              </div>
              
              <div class="stat-item">
                <div class="stat-icon">
                  <mat-icon style="color: #f59e0b;">star</mat-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-number">{{ shopStats.averageRating || 0 | number:'1.1-1' }}</div>
                  <div class="stat-label">Average Rating</div>
                </div>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <!-- Documents Verification Card -->
        <mat-card class="documents-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>description</mat-icon>
              Document Verification
            </mat-card-title>
            <mat-card-subtitle>
              Review all uploaded documents 
              <span class="documents-count" *ngIf="documents.length > 0">
                ({{ getVerifiedDocuments() }}/{{ documents.length }} verified)
              </span>
            </mat-card-subtitle>
          </mat-card-header>
          <mat-card-content>
            <div class="verification-progress" *ngIf="documents.length > 0">
              <div class="progress-bar">
                <div class="progress-fill" [style.width.%]="getVerificationProgress()"></div>
              </div>
              <div class="progress-text">{{ getVerificationProgress() | number:'1.0-0' }}% Complete</div>
            </div>

            <div class="documents-grid" *ngIf="documents.length > 0; else noDocuments">
              <div class="document-item" 
                   *ngFor="let document of documents; trackBy: trackDocument"
                   [ngClass]="'document-' + getDocumentStatusClass(document.verificationStatus)">
                <div class="document-header">
                  <div class="document-type">
                    <div class="document-icon" [ngClass]="getDocumentStatusClass(document.verificationStatus)">
                      <mat-icon>{{ getDocumentIcon(document.documentType) }}</mat-icon>
                    </div>
                    <div class="document-details">
                      <span class="document-name">{{ getDocumentDisplayName(document.documentType) }}</span>
                      <span class="document-size" *ngIf="document.fileSize">{{ formatFileSize(document.fileSize) }}</span>
                    </div>
                  </div>
                  <div class="document-status" [ngClass]="getDocumentStatusClass(document.verificationStatus)">
                    <mat-icon>{{ getDocumentStatusIcon(document.verificationStatus) }}</mat-icon>
                    <span>{{ getDocumentStatusDisplay(document.verificationStatus) }}</span>
                  </div>
                </div>
                
                <div class="document-meta" *ngIf="document.uploadedAt || document.verifiedAt">
                  <div class="meta-item" *ngIf="document.uploadedAt">
                    <mat-icon>upload</mat-icon>
                    <span>Uploaded: {{ document.uploadedAt | date:'MMM dd, yyyy' }}</span>
                  </div>
                  <div class="meta-item" *ngIf="document.verifiedAt">
                    <mat-icon>verified</mat-icon>
                    <span>Verified: {{ document.verifiedAt | date:'MMM dd, yyyy' }}</span>
                  </div>
                </div>

                <!-- Document Image Preview -->
                <div class="document-preview" *ngIf="getDocumentImageUrl(document.id)">
                  <img [src]="getDocumentImageUrl(document.id)" 
                       [alt]="document.documentName"
                       class="document-image"
                       (click)="viewDocument(document)">
                  <div class="preview-overlay">
                    <mat-icon>zoom_in</mat-icon>
                    <span>Click to view full size</span>
                  </div>
                </div>

                <!-- Verification Actions directly below image -->
                <div class="document-verification-actions" 
                     *ngIf="document.verificationStatus === 'PENDING' && shop?.status === 'PENDING'">
                  <button mat-raised-button 
                          (click)="verifyDocument(document)" 
                          color="primary"
                          class="verify-btn">
                    <mat-icon>check_circle</mat-icon>
                    Verify Document
                  </button>
                  <button mat-raised-button 
                          (click)="rejectDocument(document)" 
                          color="warn"
                          class="reject-btn">
                    <mat-icon>cancel</mat-icon>
                    Reject Document
                  </button>
                </div>

                <div class="document-notes" *ngIf="document.verificationNotes">
                  <mat-icon>note</mat-icon>
                  <span>{{ document.verificationNotes }}</span>
                </div>

                <div class="document-actions">
                  <button mat-stroked-button (click)="viewDocument(document)" color="primary">
                    <mat-icon>visibility</mat-icon>
                    View Document
                  </button>
                  <button mat-stroked-button (click)="downloadDocument(document)" color="accent">
                    <mat-icon>download</mat-icon>
                    Download
                  </button>
                </div>
              </div>
            </div>
            
            <ng-template #noDocuments>
              <div class="no-documents">
                <mat-icon>folder_open</mat-icon>
                <h3>No documents uploaded yet</h3>
                <p>The shop owner hasn't uploaded any verification documents</p>
                <button mat-raised-button color="primary" (click)="requestDocuments()">
                  <mat-icon>email</mat-icon>
                  Request Documents
                </button>
              </div>
            </ng-template>
          </mat-card-content>
        </mat-card>

        <!-- Approval Actions -->
        <mat-card class="actions-card" *ngIf="shop.status === 'PENDING'">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>how_to_vote</mat-icon>
              Approval Decision
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="approval-actions">
              <button mat-raised-button color="primary" (click)="approveShop()" class="approve-btn">
                <mat-icon>check_circle</mat-icon>
                Approve Shop
              </button>
              <button mat-raised-button color="warn" (click)="rejectShop()" class="reject-btn">
                <mat-icon>cancel</mat-icon>
                Reject Shop
              </button>
              <button mat-stroked-button (click)="requestMoreInfo()" class="info-btn">
                <mat-icon>info</mat-icon>
                Request More Information
              </button>
            </div>
          </mat-card-content>
        </mat-card>

        <!-- Status History -->
        <mat-card class="history-card" *ngIf="statusHistory.length > 0">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>history</mat-icon>
              Status History
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="history-timeline">
              <div class="timeline-item" *ngFor="let item of statusHistory">
                <div class="timeline-marker" [ngClass]="getStatusClass(item.status)">
                  <mat-icon>{{ getStatusIcon(item.status) }}</mat-icon>
                </div>
                <div class="timeline-content">
                  <div class="timeline-title">{{ getStatusDisplay(item.status) }}</div>
                  <div class="timeline-date">{{ item.timestamp | date:'MMM dd, yyyy - HH:mm' }}</div>
                  <div class="timeline-note" *ngIf="item.notes">{{ item.notes }}</div>
                </div>
              </div>
            </div>
          </mat-card-content>
        </mat-card>
      </div>

      <!-- Loading State -->
      <div class="loading-container" *ngIf="loading">
        <mat-spinner diameter="50"></mat-spinner>
        <p>Loading shop details...</p>
      </div>
    </div>
  `,
  styles: [`
    .approval-container {
      padding: 24px;
      max-width: 1200px;
      margin: 0 auto;
      min-height: calc(100vh - 100px);
    }

    .approval-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 32px;
      padding: 24px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      border-radius: 16px;
      color: white;
      box-shadow: 0 8px 32px rgba(102, 126, 234, 0.3);
    }

    .header-content {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .back-button {
      color: white !important;
    }

    .title-section h1 {
      margin: 0;
      font-size: 28px;
      font-weight: 700;
    }

    .title-section p {
      margin: 4px 0 0 0;
      opacity: 0.9;
      font-size: 16px;
    }

    .status-indicator {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px 20px;
      border-radius: 24px;
      font-weight: 600;
      background: rgba(255, 255, 255, 0.15);
      backdrop-filter: blur(10px);
    }

    .status-indicator.status-pending {
      background: rgba(251, 191, 36, 0.2);
      color: #fbbf24;
    }

    .status-indicator.status-approved {
      background: rgba(16, 185, 129, 0.2);
      color: #10b981;
    }

    .status-indicator.status-rejected {
      background: rgba(239, 68, 68, 0.2);
      color: #ef4444;
    }

    .approval-content {
      display: flex;
      flex-direction: column;
      gap: 24px;
    }

    .info-card, .documents-card, .actions-card, .history-card, .stats-card {
      border-radius: 16px;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
      border: 1px solid #e5e7eb;
    }

    .shop-avatar {
      width: 60px !important;
      height: 60px !important;
      border-radius: 12px !important;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
      display: flex !important;
      align-items: center !important;
      justify-content: center !important;
      color: white !important;
    }

    .shop-avatar img {
      width: 100%;
      height: 100%;
      border-radius: 12px;
      object-fit: cover;
    }

    .info-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 24px;
      margin-top: 16px;
    }

    .info-section h3 {
      display: flex;
      align-items: center;
      gap: 8px;
      margin: 0 0 16px 0;
      font-size: 18px;
      font-weight: 600;
      color: #1f2937;
    }

    .info-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px 0;
      border-bottom: 1px solid #f3f4f6;
    }

    .info-item:last-child {
      border-bottom: none;
    }

    .info-item .label {
      font-weight: 500;
      color: #6b7280;
    }

    .documents-count {
      font-weight: 600;
      color: #667eea;
    }

    .verification-progress {
      margin-bottom: 24px;
      padding: 16px;
      background: #f8fafc;
      border-radius: 12px;
      border: 1px solid #e2e8f0;
    }

    .progress-bar {
      width: 100%;
      height: 8px;
      background: #e5e7eb;
      border-radius: 4px;
      overflow: hidden;
      margin-bottom: 8px;
    }

    .progress-fill {
      height: 100%;
      background: linear-gradient(90deg, #10b981 0%, #059669 100%);
      transition: width 0.3s ease;
    }

    .progress-text {
      text-align: center;
      font-size: 14px;
      font-weight: 600;
      color: #1f2937;
    }

    .documents-grid {
      display: flex;
      flex-direction: column;
      gap: 20px;
    }

    .document-item {
      padding: 20px;
      border: 2px solid #e5e7eb;
      border-radius: 16px;
      background: #ffffff;
      transition: all 0.3s ease;
    }

    .document-item:hover {
      transform: translateY(-2px);
      box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
    }

    .document-item.document-verified {
      border-color: #10b981;
      background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%);
    }

    .document-item.document-pending {
      border-color: #f59e0b;
      background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%);
    }

    .document-item.document-rejected {
      border-color: #ef4444;
      background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%);
    }

    .document-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 16px;
    }

    .document-type {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .document-icon {
      width: 48px;
      height: 48px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #f1f5f9;
      border: 2px solid #e2e8f0;
    }

    .document-icon.verified {
      background: #dcfce7;
      border-color: #10b981;
      color: #166534;
    }

    .document-icon.pending {
      background: #fef3c7;
      border-color: #f59e0b;
      color: #d97706;
    }

    .document-icon.rejected {
      background: #fee2e2;
      border-color: #ef4444;
      color: #dc2626;
    }

    .document-details {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .document-name {
      font-weight: 600;
      color: #1f2937;
      font-size: 16px;
    }

    .document-size {
      font-size: 12px;
      color: #6b7280;
    }

    .document-status {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 14px;
      font-weight: 600;
      padding: 8px 16px;
      border-radius: 20px;
      white-space: nowrap;
    }

    .document-status.verified {
      background: #dcfce7;
      color: #166534;
      border: 1px solid #10b981;
    }

    .document-status.pending {
      background: #fef3c7;
      color: #d97706;
      border: 1px solid #f59e0b;
    }

    .document-status.rejected {
      background: #fee2e2;
      color: #dc2626;
      border: 1px solid #ef4444;
    }

    .document-meta {
      display: flex;
      gap: 20px;
      margin-bottom: 12px;
      flex-wrap: wrap;
    }

    .meta-item {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 12px;
      color: #6b7280;
    }

    .meta-item mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    .document-notes {
      display: flex;
      align-items: flex-start;
      gap: 8px;
      padding: 12px;
      background: rgba(107, 114, 128, 0.1);
      border-radius: 8px;
      margin-bottom: 16px;
      font-size: 14px;
      color: #4b5563;
    }

    .document-notes mat-icon {
      font-size: 18px;
      width: 18px;
      height: 18px;
      margin-top: 2px;
      flex-shrink: 0;
    }

    .document-actions {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
    }

    .document-actions button {
      padding: 8px 16px;
      font-size: 14px;
      font-weight: 500;
    }

    .document-verification-actions {
      display: flex;
      gap: 12px;
      justify-content: center;
      margin: 16px 0;
      padding: 16px;
      background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
      border-radius: 12px;
      border: 2px solid #dee2e6;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    }

    .document-verification-actions .verify-btn {
      background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
      color: white;
      font-weight: 600;
      padding: 12px 24px;
      border-radius: 8px;
      box-shadow: 0 3px 12px rgba(40, 167, 69, 0.3);
      transition: all 0.3s ease;
    }

    .document-verification-actions .verify-btn:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 20px rgba(40, 167, 69, 0.4);
    }

    .document-verification-actions .reject-btn {
      background: linear-gradient(135deg, #dc3545 0%, #e74c3c 100%);
      color: white;
      font-weight: 600;
      padding: 12px 24px;
      border-radius: 8px;
      box-shadow: 0 3px 12px rgba(220, 53, 69, 0.3);
      transition: all 0.3s ease;
    }

    .document-verification-actions .reject-btn:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 20px rgba(220, 53, 69, 0.4);
    }

    .document-preview {
      position: relative;
      margin: 16px 0;
      border: 2px dashed #e0e0e0;
      border-radius: 8px;
      overflow: hidden;
      cursor: pointer;
      transition: all 0.3s ease;
    }

    .document-preview:hover {
      border-color: #2196f3;
      transform: scale(1.02);
    }

    .document-image {
      width: 100%;
      height: 200px;
      object-fit: cover;
      display: block;
    }

    .preview-overlay {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0, 0, 0, 0.7);
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      color: white;
      opacity: 0;
      transition: opacity 0.3s ease;
    }

    .document-preview:hover .preview-overlay {
      opacity: 1;
    }

    .preview-overlay mat-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
      margin-bottom: 8px;
    }

    .preview-overlay span {
      font-size: 14px;
      font-weight: 500;
    }

    .no-documents {
      text-align: center;
      padding: 60px 40px;
      color: #9ca3af;
    }

    .no-documents mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      margin-bottom: 20px;
      color: #d1d5db;
    }

    .no-documents h3 {
      margin: 0 0 8px 0;
      color: #6b7280;
      font-size: 20px;
    }

    .no-documents p {
      margin: 0 0 24px 0;
      color: #9ca3af;
    }

    .approval-actions {
      display: flex;
      gap: 16px;
      justify-content: center;
      flex-wrap: wrap;
    }

    .approve-btn {
      background: linear-gradient(135deg, #10b981 0%, #059669 100%) !important;
      color: white !important;
      padding: 12px 32px !important;
      font-weight: 600 !important;
    }

    .reject-btn {
      background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%) !important;
      color: white !important;
      padding: 12px 32px !important;
      font-weight: 600 !important;
    }

    .info-btn {
      color: #667eea !important;
      border-color: #667eea !important;
      padding: 12px 32px !important;
      font-weight: 600 !important;
    }

    .history-timeline {
      display: flex;
      flex-direction: column;
      gap: 20px;
    }

    .timeline-item {
      display: flex;
      align-items: flex-start;
      gap: 16px;
    }

    .timeline-marker {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      margin-top: 4px;
    }

    .timeline-marker.status-pending {
      background: #fef3c7;
      color: #d97706;
    }

    .timeline-marker.status-approved {
      background: #dcfce7;
      color: #166534;
    }

    .timeline-marker.status-rejected {
      background: #fee2e2;
      color: #dc2626;
    }

    .timeline-content {
      flex: 1;
    }

    .timeline-title {
      font-weight: 600;
      color: #1f2937;
      margin-bottom: 4px;
    }

    .timeline-date {
      font-size: 12px;
      color: #6b7280;
      margin-bottom: 8px;
    }

    .timeline-note {
      font-size: 14px;
      color: #4b5563;
      background: #f9fafb;
      padding: 8px 12px;
      border-radius: 8px;
      border-left: 3px solid #e5e7eb;
    }

    .loading-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 60px;
      color: #6b7280;
    }

    .loading-container p {
      margin-top: 16px;
      font-size: 16px;
    }

    .business-type-grocery {
      background-color: #dcfce7;
      color: #166534;
      border: none;
    }

    .business-type-pharmacy {
      background-color: #dbeafe;
      color: #1e40af;
      border: none;
    }

    .business-type-restaurant {
      background-color: #faf5ff;
      color: #7c2d12;
      border: none;
    }

    .business-type-general {
      background-color: #f8fafc;
      color: #64748b;
      border: none;
    }

    .status-available {
      background-color: #dcfce7;
      color: #166534;
      border: none;
    }

    .status-unavailable {
      background-color: #fee2e2;
      color: #dc2626;
      border: none;
    }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 20px;
      margin-top: 16px;
    }

    .stat-item {
      display: flex;
      align-items: center;
      gap: 16px;
      padding: 20px;
      background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
      border-radius: 12px;
      border: 1px solid #e2e8f0;
      transition: all 0.3s ease;
    }

    .stat-item:hover {
      transform: translateY(-2px);
      box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
    }

    .stat-icon {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 48px;
      height: 48px;
      border-radius: 12px;
      background: rgba(255, 255, 255, 0.8);
      flex-shrink: 0;
    }

    .stat-content {
      flex: 1;
    }

    .stat-number {
      font-size: 24px;
      font-weight: 700;
      color: #1f2937;
      margin-bottom: 4px;
    }

    .stat-label {
      font-size: 14px;
      color: #6b7280;
      font-weight: 500;
    }

    @media (max-width: 768px) {
      .approval-container {
        padding: 16px;
      }

      .approval-header {
        flex-direction: column;
        gap: 16px;
        text-align: center;
        padding: 20px;
      }

      .header-content {
        flex-direction: column;
        gap: 12px;
      }

      .title-section h1 {
        font-size: 24px;
      }

      .title-section p {
        font-size: 14px;
      }

      .info-grid {
        grid-template-columns: 1fr;
        gap: 16px;
      }

      .stats-grid {
        grid-template-columns: repeat(2, 1fr);
        gap: 12px;
      }

      .stat-item {
        padding: 16px;
        flex-direction: column;
        text-align: center;
        gap: 12px;
      }

      .stat-number {
        font-size: 20px;
      }

      .approval-actions {
        flex-direction: column;
        gap: 12px;
      }

      .approval-actions button {
        width: 100%;
        justify-content: center;
      }

      .document-header {
        flex-direction: column;
        gap: 12px;
        align-items: flex-start;
      }

      .document-status {
        align-self: flex-start;
      }

      .document-actions {
        flex-direction: column;
        width: 100%;
      }

      .document-actions button {
        width: 100%;
        justify-content: center;
      }

      .document-verification-actions {
        flex-direction: column;
        gap: 8px;
        padding: 12px;
      }

      .document-verification-actions .verify-btn,
      .document-verification-actions .reject-btn {
        width: 100%;
        padding: 12px 16px;
        font-size: 16px;
      }

      .document-meta {
        flex-direction: column;
        gap: 8px;
      }

      .timeline-item {
        flex-direction: column;
        gap: 8px;
      }

      .timeline-marker {
        align-self: flex-start;
      }

      .no-documents {
        padding: 40px 20px;
      }

      .no-documents mat-icon {
        font-size: 48px;
        width: 48px;
        height: 48px;
      }

      .verification-progress {
        padding: 12px;
      }
    }

    @media (max-width: 480px) {
      .approval-container {
        padding: 12px;
      }

      .approval-header {
        padding: 16px;
        margin-bottom: 20px;
      }

      .title-section h1 {
        font-size: 20px;
      }

      .stats-grid {
        grid-template-columns: 1fr;
      }

      .stat-item {
        padding: 12px;
      }

      .document-type {
        flex-direction: column;
        gap: 8px;
        text-align: center;
      }

      .document-icon {
        align-self: center;
      }

      .info-item {
        flex-direction: column;
        gap: 4px;
        align-items: flex-start;
        padding: 8px 0;
      }

      .info-item .label {
        font-size: 12px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
      }
    }
  `]
})
export class ShopApprovalComponent implements OnInit {
  shop: Shop | null = null;
  documents: any[] = [];
  documentImageUrls: { [documentId: number]: string } = {};
  statusHistory: any[] = [];
  shopStats: any = {
    totalProducts: 0,
    totalOrders: 0,
    totalRevenue: 0,
    averageRating: 0
  };
  loading = true;
  shopId!: number;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private shopService: ShopService,
    private documentService: DocumentService
  ) {}

  ngOnInit() {
    this.shopId = +this.route.snapshot.params['shopId'];
    this.loadShopDetails();
    this.loadDocuments();
    this.loadStatusHistory();
    this.loadShopStats();
  }

  private loadShopDetails() {
    this.shopService.getShop(this.shopId).subscribe({
      next: (shop) => {
        this.shop = shop;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading shop:', error);
        this.loading = false;
        Swal.fire({
          title: 'Error!',
          text: 'Failed to load shop details',
          icon: 'error',
          confirmButtonText: 'OK'
        });
      }
    });
  }

  private loadDocuments() {
    this.documentService.getShopDocuments(this.shopId).subscribe({
      next: (documents) => {
        this.documents = documents;
        console.log('Loaded real documents:', documents);
        // Load image URLs for documents
        this.loadDocumentImages();
      },
      error: (error) => {
        console.error('Error loading documents:', error);
        this.documents = [];
        // Show error message instead of fake data
        Swal.fire({
          title: 'Authentication Error',
          text: 'Unable to load documents. Please refresh and login again.',
          icon: 'warning',
          confirmButtonText: 'OK'
        });
      }
    });
  }

  private loadDocumentImages() {
    this.documents.forEach(document => {
      if (document.fileType?.startsWith('image/')) {
        this.loadDocumentImageUrl(document.id);
      }
    });
  }

  private loadDocumentImageUrl(documentId: number) {
    this.documentService.downloadDocument(documentId).subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        this.documentImageUrls[documentId] = url;
      },
      error: (error) => {
        console.error('Error loading document image:', error);
      }
    });
  }

  getDocumentImageUrl(documentId: number): string | null {
    return this.documentImageUrls[documentId] || null;
  }

  private loadStatusHistory() {
    // Mock status history - replace with actual API call
    this.statusHistory = [
      {
        status: 'PENDING',
        timestamp: new Date(),
        notes: 'Shop registration submitted for review'
      }
    ];
  }

  private loadShopStats() {
    // Mock statistics - replace with actual API call
    this.shopStats = {
      totalProducts: Math.floor(Math.random() * 200) + 50,
      totalOrders: Math.floor(Math.random() * 500) + 100,
      totalRevenue: Math.floor(Math.random() * 100000) + 25000,
      averageRating: (Math.random() * 2 + 3).toFixed(1)
    };
  }

  goBack() {
    this.router.navigate(['/shops']);
  }

  approveShop() {
    if (!this.shop) return;

    Swal.fire({
      title: 'Approve Shop',
      text: `Are you sure you want to approve "${this.shop.name}"?`,
      input: 'textarea',
      inputLabel: 'Approval Notes (Optional)',
      inputPlaceholder: 'Enter any notes for the approval...',
      icon: 'question',
      showCancelButton: true,
      confirmButtonColor: '#10b981',
      cancelButtonColor: '#6b7280',
      confirmButtonText: 'Yes, approve it!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed && this.shop) {
        const notes = result.value?.trim();
        this.shopService.approveShop(this.shop.id, notes).subscribe({
          next: () => {
            Swal.fire({
              title: 'Approved!',
              text: `Shop "${this.shop!.name}" has been approved successfully.`,
              icon: 'success',
              confirmButtonColor: '#667eea'
            });
            this.loadShopDetails(); // Refresh data
          },
          error: (error) => {
            console.error('Error approving shop:', error);
            Swal.fire({
              title: 'Error!',
              text: `Failed to approve shop "${this.shop!.name}". Please try again.`,
              icon: 'error',
              confirmButtonColor: '#667eea'
            });
          }
        });
      }
    });
  }

  rejectShop() {
    if (!this.shop) return;

    Swal.fire({
      title: 'Reject Shop',
      text: `Enter rejection reason for "${this.shop.name}":`,
      input: 'textarea',
      inputPlaceholder: 'Enter the reason for rejection...',
      inputAttributes: {
        'aria-label': 'Rejection reason'
      },
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#ef4444',
      cancelButtonColor: '#6b7280',
      confirmButtonText: 'Reject Shop',
      cancelButtonText: 'Cancel',
      inputValidator: (value) => {
        if (!value || !value.trim()) {
          return 'Rejection reason is required!';
        }
        return null;
      }
    }).then((result) => {
      if (result.isConfirmed && result.value && this.shop) {
        this.shopService.rejectShop(this.shop.id, result.value.trim()).subscribe({
          next: () => {
            Swal.fire({
              title: 'Rejected!',
              text: `Shop "${this.shop!.name}" has been rejected.`,
              icon: 'success',
              confirmButtonColor: '#667eea'
            });
            this.loadShopDetails(); // Refresh data
          },
          error: (error) => {
            console.error('Error rejecting shop:', error);
            Swal.fire({
              title: 'Error!',
              text: `Failed to reject shop "${this.shop!.name}". Please try again.`,
              icon: 'error',
              confirmButtonColor: '#667eea'
            });
          }
        });
      }
    });
  }

  requestMoreInfo() {
    Swal.fire({
      title: 'Request More Information',
      text: 'What additional information do you need?',
      input: 'textarea',
      inputPlaceholder: 'Enter your request...',
      showCancelButton: true,
      confirmButtonText: 'Send Request',
      inputValidator: (value) => {
        if (!value || !value.trim()) {
          return 'Please enter your request!';
        }
        return null;
      }
    }).then((result) => {
      if (result.isConfirmed) {
        Swal.fire({
          title: 'Request Sent!',
          text: 'The shop owner will be notified about your request.',
          icon: 'success'
        });
      }
    });
  }

  viewDocument(document: any) {
    this.documentService.downloadDocument(document.id).subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        
        // Create a new window/tab and write the content directly for better viewing
        const newWindow = window.open('', '_blank');
        if (newWindow) {
          if (blob.type.startsWith('image/')) {
            // For images, create an img element
            newWindow.document.write(`
              <html>
                <head><title>${document.fileName || 'Document'}</title></head>
                <body style="margin:0; padding:20px; text-align:center; background:#f5f5f5;">
                  <img src="${url}" style="max-width:100%; max-height:100%; object-fit:contain;" 
                       onload="document.title='${document.fileName || 'Image'}'" />
                </body>
              </html>
            `);
          } else {
            // For other files (PDFs, etc.), try to display directly
            newWindow.location.href = url;
          }
        } else {
          // Fallback if popup is blocked
          const link = document.createElement('a');
          link.href = url;
          link.target = '_blank';
          link.click();
        }
        
        // Clean up the URL after a delay to allow the browser to load it
        setTimeout(() => window.URL.revokeObjectURL(url), 10000);
      },
      error: (error) => {
        console.error('Error viewing document:', error);
        Swal.fire({
          title: 'Error',
          text: 'Failed to load document. Please try again.',
          icon: 'error',
          confirmButtonText: 'OK'
        });
      }
    });
  }

  downloadDocument(document: any) {
    this.documentService.downloadDocument(document.id).subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = document.fileName || `document_${document.id}`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        window.URL.revokeObjectURL(url);
      },
      error: (error) => {
        console.error('Error downloading document:', error);
        Swal.fire({
          title: 'Download Failed',
          text: 'Failed to download document. Please try again.',
          icon: 'error',
          confirmButtonText: 'OK'
        });
      }
    });
  }

  getShopLogo(): string | null {
    if (!this.shop || !this.shop.images || this.shop.images.length === 0) {
      return null;
    }
    
    // Find the primary logo image
    const logoImage = this.shop.images.find(img => img.imageType === 'LOGO' && img.isPrimary);
    if (logoImage) {
      const imageUrl = logoImage.imageUrl;
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return imageUrl;
      }
      return `http://localhost:8082${imageUrl}`;
    }
    
    return null;
  }

  getStatusClass(status: string | undefined): string {
    switch(status?.toString().toUpperCase()) {
      case 'PENDING': return 'status-pending';
      case 'APPROVED': return 'status-approved';
      case 'REJECTED': return 'status-rejected';
      default: return 'status-pending';
    }
  }

  getStatusIcon(status: string | undefined): string {
    switch(status?.toString().toUpperCase()) {
      case 'PENDING': return 'schedule';
      case 'APPROVED': return 'check_circle';
      case 'REJECTED': return 'cancel';
      default: return 'schedule';
    }
  }

  getStatusDisplay(status: string | undefined): string {
    switch(status?.toString().toUpperCase()) {
      case 'PENDING': return 'Pending Review';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      default: return status?.toString() || 'Unknown';
    }
  }

  getBusinessTypeDisplay(type: string): string {
    switch(type?.toUpperCase()) {
      case 'GROCERY': return 'Grocery';
      case 'PHARMACY': return 'Pharmacy';
      case 'RESTAURANT': return 'Restaurant';
      case 'GENERAL': return 'General';
      default: return type || 'General';
    }
  }

  getBusinessTypeClass(type: string): string {
    switch(type?.toUpperCase()) {
      case 'GROCERY': return 'business-type-grocery';
      case 'PHARMACY': return 'business-type-pharmacy';
      case 'RESTAURANT': return 'business-type-restaurant';
      case 'GENERAL': return 'business-type-general';
      default: return 'business-type-general';
    }
  }

  getDocumentIcon(type: string): string {
    switch(type?.toUpperCase()) {
      case 'BUSINESS_LICENSE': return 'business';
      case 'GST_CERTIFICATE': return 'receipt';
      case 'PAN_CARD': return 'credit_card';
      case 'AADHAR_CARD': return 'badge';
      case 'OWNER_PHOTO': return 'person';
      case 'SHOP_PHOTO': return 'storefront';
      default: return 'description';
    }
  }

  getDocumentDisplayName(type: string): string {
    switch(type?.toUpperCase()) {
      case 'BUSINESS_LICENSE': return 'Business License';
      case 'GST_CERTIFICATE': return 'GST Certificate';
      case 'PAN_CARD': return 'PAN Card';
      case 'AADHAR_CARD': return 'Aadhar Card';
      case 'OWNER_PHOTO': return 'Owner Photo';
      case 'SHOP_PHOTO': return 'Shop Photo';
      case 'ADDRESS_PROOF': return 'Address Proof';
      default: return type?.replace('_', ' ') || 'Document';
    }
  }

  getDocumentStatusClass(status: string): string {
    switch(status?.toUpperCase()) {
      case 'VERIFIED':
      case 'APPROVED': return 'verified';
      case 'REJECTED': return 'rejected';
      default: return 'pending';
    }
  }

  getDocumentStatusIcon(status: string): string {
    switch(status?.toUpperCase()) {
      case 'VERIFIED':
      case 'APPROVED': return 'check_circle';
      case 'REJECTED': return 'cancel';
      default: return 'schedule';
    }
  }

  getOperatingHours(): string {
    if (!this.shop) return 'Not specified';
    
    // Mock operating hours - replace with actual shop data
    if (this.shop.businessType === 'PHARMACY') {
      return '8:00 AM - 10:00 PM';
    } else if (this.shop.businessType === 'GROCERY') {
      return '6:00 AM - 11:00 PM';
    } else if (this.shop.businessType === 'RESTAURANT') {
      return '11:00 AM - 11:00 PM';
    } else {
      return '9:00 AM - 9:00 PM';
    }
  }

  getVerifiedDocuments(): number {
    return this.documents.filter(doc => 
      doc.verificationStatus?.toUpperCase() === 'VERIFIED' || 
      doc.verificationStatus?.toUpperCase() === 'APPROVED'
    ).length;
  }

  getVerificationProgress(): number {
    if (this.documents.length === 0) return 0;
    return (this.getVerifiedDocuments() / this.documents.length) * 100;
  }

  trackDocument(index: number, document: any): any {
    return document.id || index;
  }

  getDocumentStatusDisplay(status: string): string {
    switch(status?.toUpperCase()) {
      case 'VERIFIED':
      case 'APPROVED': return 'Verified';
      case 'REJECTED': return 'Rejected';
      case 'PENDING': return 'Pending Review';
      default: return status || 'Pending';
    }
  }

  formatFileSize(bytes: number): string {
    if (!bytes) return '';
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
  }

  verifyDocument(document: any) {
    Swal.fire({
      title: 'Verify Document',
      text: `Mark "${this.getDocumentDisplayName(document.documentType)}" as verified?`,
      icon: 'question',
      showCancelButton: true,
      confirmButtonColor: '#10b981',
      cancelButtonColor: '#6b7280',
      confirmButtonText: 'Yes, verify it!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        // Update document status locally (replace with API call)
        document.verificationStatus = 'VERIFIED';
        document.verifiedAt = new Date().toISOString();
        
        Swal.fire({
          title: 'Verified!',
          text: 'Document has been marked as verified.',
          icon: 'success',
          confirmButtonColor: '#667eea'
        });
      }
    });
  }

  rejectDocument(document: any) {
    Swal.fire({
      title: 'Reject Document',
      text: `Enter rejection reason for "${this.getDocumentDisplayName(document.documentType)}":`,
      input: 'textarea',
      inputPlaceholder: 'Enter the reason for rejection...',
      inputAttributes: {
        'aria-label': 'Rejection reason'
      },
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#ef4444',
      cancelButtonColor: '#6b7280',
      confirmButtonText: 'Reject Document',
      cancelButtonText: 'Cancel',
      inputValidator: (value) => {
        if (!value || !value.trim()) {
          return 'Rejection reason is required!';
        }
        return null;
      }
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        // Update document status locally (replace with API call)
        document.verificationStatus = 'REJECTED';
        document.verificationNotes = result.value.trim();
        
        Swal.fire({
          title: 'Rejected!',
          text: 'Document has been rejected.',
          icon: 'success',
          confirmButtonColor: '#667eea'
        });
      }
    });
  }

  requestDocuments() {
    Swal.fire({
      title: 'Request Documents',
      text: 'Send a request to the shop owner to upload verification documents?',
      icon: 'question',
      showCancelButton: true,
      confirmButtonColor: '#667eea',
      cancelButtonColor: '#6b7280',
      confirmButtonText: 'Send Request',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        Swal.fire({
          title: 'Request Sent!',
          text: 'The shop owner will be notified to upload verification documents.',
          icon: 'success',
          confirmButtonColor: '#667eea'
        });
      }
    });
  }
}