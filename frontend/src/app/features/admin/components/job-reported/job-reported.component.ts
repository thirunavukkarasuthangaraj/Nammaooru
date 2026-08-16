import { Component, OnInit } from '@angular/core';
import { JobAdminService } from '../../services/job.service';
import { getImageUrl } from '../../../../core/utils/image-url.util';
import { SwalService } from '../../../../core/services/swal.service';

interface JobPost {
  id: number;
  jobTitle: string;
  companyName: string;
  phone: string;
  category: string;
  jobType: string;
  location: string | null;
  description: string | null;
  imageUrls: string | null;
  sellerUserId: number;
  sellerName: string;
  reportCount: number;
  status: string;
  createdAt: string;
}

@Component({
  selector: 'app-job-reported',
  templateUrl: './job-reported.component.html',
  styleUrls: ['./job-reported.component.scss']
})
export class JobReportedComponent implements OnInit {
  posts: JobPost[] = [];
  loading = true;
  currentPage = 0;
  totalPages = 0;
  totalItems = 0;
  pageSize = 20;

  constructor(
    private jobService: JobAdminService,
    private swal: SwalService
  ) {}

  ngOnInit(): void {
    this.loadReportedPosts();
  }

  loadReportedPosts(): void {
    this.loading = true;
    this.jobService.getReportedPosts(this.currentPage, this.pageSize).subscribe({
      next: (response) => {
        const data = response.data;
        this.posts = data?.content || [];
        this.totalPages = data?.totalPages || 0;
        this.totalItems = data?.totalElements || data?.totalItems || 0;
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading reported job posts:', err);
        this.loading = false;
        this.swal.toast('Failed to load reported posts', 'error');
      }
    });
  }

  approvePost(post: JobPost): void {
    this.jobService.approvePost(post.id).subscribe({
      next: () => {
        this.swal.toast(`"${post.jobTitle}" approved — reports cleared`, 'success');
        this.loadReportedPosts();
      },
      error: () => {
        this.swal.toast('Failed to approve post', 'error');
      }
    });
  }

  rejectPost(post: JobPost): void {
    const reason = prompt(`Reason for rejecting "${post.jobTitle}"? (optional)`);
    if (reason === null) return;
    this.jobService.rejectPost(post.id, reason).subscribe({
      next: () => {
        this.swal.toast(`"${post.jobTitle}" rejected`, 'success');
        this.loadReportedPosts();
      },
      error: () => {
        this.swal.toast('Failed to reject post', 'error');
      }
    });
  }

  deletePost(post: JobPost): void {
    if (confirm(`Delete "${post.jobTitle}" by ${post.companyName} permanently?`)) {
      this.jobService.deletePost(post.id).subscribe({
        next: () => {
          this.swal.toast('Post deleted', 'success');
          this.loadReportedPosts();
        },
        error: () => {
          this.swal.toast('Failed to delete post', 'error');
        }
      });
    }
  }

  getImageUrl(imageUrls: string | null): string {
    if (!imageUrls) return '';
    const first = imageUrls.split(',')[0]?.trim();
    return getImageUrl(first || null);
  }

  getCategoryLabel(category: string): string {
    const labels: Record<string, string> = {
      'SHOP_WORKER': 'Shop Worker', 'SALES_PERSON': 'Sales Person',
      'DELIVERY_BOY': 'Delivery Boy', 'SECURITY': 'Security',
      'CASHIER': 'Cashier', 'RECEPTIONIST': 'Receptionist',
      'ACCOUNTANT': 'Accountant', 'DRIVER': 'Driver',
      'COOK': 'Cook', 'HELPER': 'Helper',
      'TEACHER': 'Teacher', 'NURSE': 'Nurse',
      'TAILOR': 'Tailor', 'CLEANER': 'Cleaner',
      'WATCHMAN': 'Watchman', 'FARM_WORKER': 'Farm Worker',
      'COMPUTER_OPERATOR': 'Computer Operator', 'MANAGER': 'Manager',
      'ELECTRICIAN': 'Electrician', 'OTHER': 'Other'
    };
    return labels[category] || category;
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'PENDING_APPROVAL': return 'Pending';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      case 'EXPIRED': return 'Expired';
      default: return status;
    }
  }

  formatDate(dateStr: string): string {
    if (!dateStr) return '';
    return new Date(dateStr).toLocaleDateString('en-IN', {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });
  }

  onPageChange(page: number): void {
    this.currentPage = page;
    this.loadReportedPosts();
  }
}
