import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { ShopService } from '../../../../core/services/shop.service';
import { DocumentService } from '../../../../core/services/document.service';
import { Shop } from '../../../../core/models/shop.model';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-shop-approvals-list',
  templateUrl: './shop-approvals-list.component.html',
  styleUrls: ['./shop-approvals-list.component.scss']
})
export class ShopApprovalsListComponent implements OnInit {
  shops: Shop[] = [];
  stats: any = null;
  loading = true;
  
  // Pagination
  totalElements = 0;
  pageSize = 10;
  currentPage = 0;
  
  // Filters
  searchQuery = '';
  statusFilter = '';
  businessTypeFilter = '';

  constructor(
    private shopService: ShopService,
    private documentService: DocumentService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadData();
    this.loadStats();
  }

  loadData(): void {
    this.loading = true;
    
    const params = {
      page: this.currentPage,
      size: this.pageSize,
      search: this.searchQuery || undefined,
      status: this.statusFilter || undefined,
      businessType: this.businessTypeFilter || undefined
    };

    this.shopService.getPendingShops(params).subscribe({
      next: (response) => {
        this.shops = response.content;
        this.totalElements = response.totalElements;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading shops:', error);
        this.loading = false;
        Swal.fire({
          title: 'Error!',
          text: 'Failed to load shops. Please try again.',
          icon: 'error',
          confirmButtonColor: '#667eea'
        });
      }
    });
  }

  loadStats(): void {
    this.shopService.getApprovalStats().subscribe({
      next: (stats) => {
        this.stats = stats;
      },
      error: (error) => {
        console.error('Error loading stats:', error);
      }
    });
  }

  applyFilters(): void {
    this.currentPage = 0;
    this.loadData();
  }

  clearFilters(): void {
    this.searchQuery = '';
    this.statusFilter = '';
    this.businessTypeFilter = '';
    this.currentPage = 0;
    this.loadData();
  }

  onPageChange(event: any): void {
    this.currentPage = event.pageIndex;
    this.pageSize = event.pageSize;
    this.loadData();
  }

  refreshData(): void {
    this.loadData();
    this.loadStats();
  }

  viewShop(shop: Shop): void {
    this.router.navigate(['/shops', shop.id, 'approval']);
  }

  editShop(shop: Shop): void {
    this.router.navigate(['/shops', shop.id, 'edit']);
  }

  viewDocuments(shop: Shop): void {
    this.shopService.getDocumentVerificationStatus(shop.id).subscribe({
      next: (status) => {
        this.showDocumentsDialog(shop, status);
      },
      error: (error) => {
        console.error('Error fetching document status:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Failed to load document information. Please try again.',
          icon: 'error',
          confirmButtonColor: '#667eea'
        });
      }
    });
  }

  private showDocumentsDialog(shop: Shop, status: any): void {
    const documents = status.documents || [];
    const documentsList = documents.map((doc: any) => {
      const statusIcon = this.getDocumentStatusIcon(doc.verificationStatus);
      const statusClass = this.getDocumentStatusClass(doc.verificationStatus);
      return `
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; padding: 8px; border-radius: 4px; background-color: #f8f9fa;">
          <span style="font-weight: 500;">${doc.documentName || this.getDocumentTypeDisplay(doc.documentType)}</span>
          <span class="${statusClass}" style="display: flex; align-items: center; gap: 4px;">
            ${statusIcon} ${this.getVerificationStatusDisplay(doc.verificationStatus)}
          </span>
        </div>
      `;
    }).join('');

    const summaryHtml = `
      <div style="margin-bottom: 16px; padding: 12px; background-color: #f1f5f9; border-radius: 8px;">
        <h4 style="margin: 0 0 8px 0; color: #334155;">Document Verification Summary</h4>
        <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 8px; font-size: 14px;">
          <div><strong>Total:</strong> ${status.totalDocuments}</div>
          <div><strong>Verified:</strong> <span style="color: #10b981;">${status.verifiedDocuments}</span></div>
          <div><strong>Pending:</strong> <span style="color: #f59e0b;">${status.pendingDocuments}</span></div>
          <div><strong>Rejected:</strong> <span style="color: #ef4444;">${status.rejectedDocuments}</span></div>
        </div>
      </div>
    `;

    Swal.fire({
      title: `Documents - ${shop.name}`,
      html: `${summaryHtml}${documentsList || '<p>No documents uploaded yet.</p>'}`,
      width: 600,
      showCancelButton: true,
      confirmButtonText: 'Verify Documents',
      cancelButtonText: 'Close',
      confirmButtonColor: '#667eea',
      showLoaderOnConfirm: true,
      preConfirm: () => {
        return this.openDocumentVerificationDialog(shop, documents);
      }
    });
  }

  private openDocumentVerificationDialog(shop: Shop, documents: any[]): void {
    if (documents.length === 0) {
      Swal.fire({
        title: 'No Documents',
        text: 'This shop has not uploaded any documents yet.',
        icon: 'info',
        confirmButtonColor: '#667eea'
      });
      return;
    }

    // Create a detailed dialog for document verification
    const documentOptions = documents.map((doc: any, index: number) => {
      return `${index + 1}. ${doc.documentName || this.getDocumentTypeDisplay(doc.documentType)} - ${this.getVerificationStatusDisplay(doc.verificationStatus)}`;
    }).join('\n');

    Swal.fire({
      title: 'Document Verification',
      text: `Select a document to verify:\n\n${documentOptions}`,
      input: 'select',
      inputOptions: documents.reduce((options: any, doc: any, index: number) => {
        options[index] = `${doc.documentName || this.getDocumentTypeDisplay(doc.documentType)} (${this.getVerificationStatusDisplay(doc.verificationStatus)})`;
        return options;
      }, {}),
      inputPlaceholder: 'Select a document',
      showCancelButton: true,
      confirmButtonColor: '#667eea',
      inputValidator: (value) => {
        if (!value) {
          return 'Please select a document to verify';
        }
        return null;
      }
    }).then((result) => {
      if (result.isConfirmed) {
        const selectedDoc = documents[parseInt(result.value)];
        this.verifyDocument(selectedDoc, shop);
      }
    });
  }

  private verifyDocument(document: any, shop: Shop): void {
    Swal.fire({
      title: `Verify Document`,
      text: `Document: ${document.documentName || this.getDocumentTypeDisplay(document.documentType)}`,
      input: 'select',
      inputOptions: {
        'VERIFIED': '✅ Verify (Approve)',
        'REJECTED': '❌ Reject'
      },
      inputPlaceholder: 'Select verification status',
      showCancelButton: true,
      confirmButtonColor: '#667eea',
      inputValidator: (value) => {
        if (!value) {
          return 'Please select a verification status';
        }
        return null;
      }
    }).then((statusResult) => {
      if (statusResult.isConfirmed) {
        const status = statusResult.value;
        
        Swal.fire({
          title: 'Add Notes',
          text: `Add verification notes for this document:`,
          input: 'textarea',
          inputPlaceholder: 'Enter verification notes (optional)...',
          showCancelButton: true,
          confirmButtonColor: '#667eea'
        }).then((notesResult) => {
          if (notesResult.isConfirmed) {
            const verificationRequest = {
              verificationStatus: status,
              verificationNotes: notesResult.value?.trim() || ''
            };

            this.documentService.verifyDocument(document.id, verificationRequest).subscribe({
              next: () => {
                Swal.fire({
                  title: 'Success!',
                  text: `Document has been ${status.toLowerCase()} successfully.`,
                  icon: 'success',
                  confirmButtonColor: '#667eea'
                });
                this.refreshData();
              },
              error: (error) => {
                console.error('Error verifying document:', error);
                Swal.fire({
                  title: 'Error!',
                  text: 'Failed to verify document. Please try again.',
                  icon: 'error',
                  confirmButtonColor: '#667eea'
                });
              }
            });
          }
        });
      }
    });
  }

  private getDocumentStatusIcon(status: string): string {
    switch (status?.toUpperCase()) {
      case 'VERIFIED': return '✅';
      case 'REJECTED': return '❌';
      case 'PENDING': return '⏳';
      default: return '⏳';
    }
  }

  private getDocumentStatusClass(status: string): string {
    switch (status?.toUpperCase()) {
      case 'VERIFIED': return 'text-success';
      case 'REJECTED': return 'text-danger';
      case 'PENDING': return 'text-warning';
      default: return 'text-warning';
    }
  }

  private getVerificationStatusDisplay(status: string): string {
    switch (status?.toUpperCase()) {
      case 'VERIFIED': return 'Verified';
      case 'REJECTED': return 'Rejected';
      case 'PENDING': return 'Pending';
      default: return 'Pending';
    }
  }

  private getDocumentTypeDisplay(type: string): string {
    const displayNames: { [key: string]: string } = {
      'BUSINESS_LICENSE': 'Business License',
      'GST_CERTIFICATE': 'GST Certificate',
      'PAN_CARD': 'PAN Card',
      'AADHAR_CARD': 'Aadhar Card',
      'BANK_STATEMENT': 'Bank Statement',
      'ADDRESS_PROOF': 'Address Proof',
      'OWNER_PHOTO': 'Owner Photo',
      'SHOP_PHOTO': 'Shop Photo',
      'FOOD_LICENSE': 'Food License',
      'FSSAI_CERTIFICATE': 'FSSAI Certificate',
      'DRUG_LICENSE': 'Drug License',
      'TRADE_LICENSE': 'Trade License',
      'OTHER': 'Other Document'
    };
    return displayNames[type?.toUpperCase()] || type || 'Unknown Document';
  }

  approveShop(shop: Shop): void {
    Swal.fire({
      title: 'Approve Shop',
      text: `Are you sure you want to approve "${shop.name}"?`,
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
      if (result.isConfirmed) {
        const notes = result.value?.trim();
        this.shopService.approveShop(shop.id, notes).subscribe({
          next: () => {
            Swal.fire({
              title: 'Approved!',
              text: `Shop "${shop.name}" has been approved successfully.`,
              icon: 'success',
              confirmButtonColor: '#667eea'
            });
            this.refreshData();
          },
          error: (error) => {
            console.error('Error approving shop:', error);
            Swal.fire({
              title: 'Error!',
              text: `Failed to approve shop "${shop.name}". Please try again.`,
              icon: 'error',
              confirmButtonColor: '#667eea'
            });
          }
        });
      }
    });
  }

  rejectShop(shop: Shop): void {
    Swal.fire({
      title: 'Reject Shop',
      text: `Enter rejection reason for "${shop.name}":`,
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
      if (result.isConfirmed && result.value) {
        this.shopService.rejectShop(shop.id, result.value.trim()).subscribe({
          next: () => {
            Swal.fire({
              title: 'Rejected!',
              text: `Shop "${shop.name}" has been rejected.`,
              icon: 'success',
              confirmButtonColor: '#667eea'
            });
            this.refreshData();
          },
          error: (error) => {
            console.error('Error rejecting shop:', error);
            Swal.fire({
              title: 'Error!',
              text: `Failed to reject shop "${shop.name}". Please try again.`,
              icon: 'error',
              confirmButtonColor: '#667eea'
            });
          }
        });
      }
    });
  }

  getShopLogo(shop: Shop): string | null {
    if (!shop.images || shop.images.length === 0) {
      return null;
    }
    
    const logoImage = shop.images.find(img => img.imageType === 'LOGO' && img.isPrimary);
    if (logoImage) {
      const imageUrl = logoImage.imageUrl;
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return imageUrl;
      }
      return `http://localhost:8082${imageUrl}`;
    }
    
    return null;
  }

  getStatusClass(status: string): string {
    switch(status?.toUpperCase()) {
      case 'PENDING': return 'status-pending';
      case 'APPROVED': return 'status-approved';
      case 'REJECTED': return 'status-rejected';
      default: return 'status-pending';
    }
  }

  getStatusIcon(status: string): string {
    switch(status?.toUpperCase()) {
      case 'PENDING': return 'schedule';
      case 'APPROVED': return 'check_circle';
      case 'REJECTED': return 'cancel';
      default: return 'schedule';
    }
  }

  getStatusDisplay(status: string): string {
    switch(status?.toUpperCase()) {
      case 'PENDING': return 'Pending';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      default: return status || 'Unknown';
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

  getPageTitle(): string {
    if (!this.statusFilter) {
      return 'All Shops';
    }
    switch(this.statusFilter.toUpperCase()) {
      case 'PENDING': return 'Pending Shop Approvals';
      case 'APPROVED': return 'Approved Shops';
      case 'REJECTED': return 'Rejected Shops';
      default: return 'Shop Approvals';
    }
  }
}