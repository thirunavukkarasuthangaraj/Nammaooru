import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HealthTipsService, HealthTip, HealthTipQueueStats } from '../../services/health-tips.service';

@Component({
  selector: 'app-health-tips-management',
  templateUrl: './health-tips-management.component.html',
  styles: [`
    .health-tips-container { padding: 24px; }
    .header-section { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; }
    .page-title { display: flex; align-items: center; gap: 8px; margin: 0; font-size: 24px; font-weight: 500; }
    .title-icon { font-size: 28px; width: 28px; height: 28px; color: #4caf50; }
    .header-actions { display: flex; gap: 12px; flex-wrap: wrap; }

    .stats-row { display: flex; gap: 16px; margin-bottom: 24px; flex-wrap: wrap; }
    .stat-card { flex: 1; min-width: 140px; }
    .stat-card mat-card { text-align: center; padding: 16px; }
    .stat-value { font-size: 28px; font-weight: 700; line-height: 1.2; }
    .stat-label { font-size: 13px; color: #666; margin-top: 4px; }
    .stat-pending .stat-value { color: #ff9800; }
    .stat-approved .stat-value { color: #2196f3; }
    .stat-sent .stat-value { color: #4caf50; }
    .stat-rejected .stat-value { color: #f44336; }

    .filter-card { margin-bottom: 24px; }
    .filter-row { display: flex; align-items: center; gap: 16px; flex-wrap: wrap; }
    .search-field { flex: 1; min-width: 200px; }
    .tab-section { margin-bottom: 24px; }

    .table-card { margin-bottom: 24px; }
    .table-container { overflow-x: auto; }
    .health-tip-table { width: 100%; }

    .tip-message { max-width: 400px; white-space: pre-wrap; word-break: break-word; font-size: 13px; line-height: 1.5; }
    .tip-message-truncated { max-height: 60px; overflow: hidden; text-overflow: ellipsis; cursor: pointer; }
    .tip-message-truncated:hover { max-height: none; }

    .status-chip { font-size: 11px; font-weight: 600; }
    .date-cell { font-size: 13px; color: #555; white-space: nowrap; }

    .no-data { text-align: center; padding: 48px 16px; color: #999; }
    .no-data mat-icon { font-size: 48px; width: 48px; height: 48px; margin-bottom: 8px; }
    .no-data p { font-size: 16px; }

    .loading-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(255,255,255,0.7); display: flex; align-items: center; justify-content: center; z-index: 1000; }

    .edit-field { width: 100%; }
    .edit-actions { display: flex; gap: 8px; margin-top: 8px; }

    .delete-action { color: #f44336; }
    .approve-action { color: #4caf50; }

    @media (max-width: 768px) {
      .health-tips-container { padding: 16px; }
      .header-section { flex-direction: column; align-items: stretch; }
      .stats-row { flex-direction: column; }
      .stat-card { min-width: unset; }
    }
  `]
})
export class HealthTipsManagementComponent implements OnInit {
  // Queue tab
  queueColumns: string[] = ['id', 'message', 'scheduledDate', 'status', 'approvedBy', 'actions'];
  queueDataSource: MatTableDataSource<HealthTip>;
  stats: HealthTipQueueStats = { PENDING: 0, APPROVED: 0, SENT: 0, REJECTED: 0 };

  // History tab
  historyColumns: string[] = ['id', 'message', 'scheduledDate', 'sentAt', 'approvedBy'];
  historyDataSource: MatTableDataSource<HealthTip>;
  historyTotalElements = 0;
  historyPage = 0;
  historyPageSize = 20;

  // State
  isLoading = false;
  isGenerating = false;
  activeTab: 'queue' | 'history' = 'queue';
  filterStatus = 'ALL';

  // Inline editing
  editingTipId: number | null = null;
  editMessage = '';

  @ViewChild('queuePaginator') queuePaginator!: MatPaginator;
  @ViewChild('queueSort') queueSort!: MatSort;
  @ViewChild('historyPaginator') historyPaginator!: MatPaginator;

  constructor(
    private healthTipsService: HealthTipsService,
    private snackBar: MatSnackBar
  ) {
    this.queueDataSource = new MatTableDataSource<HealthTip>([]);
    this.historyDataSource = new MatTableDataSource<HealthTip>([]);
  }

  ngOnInit(): void {
    this.loadQueue();
  }

  ngAfterViewInit(): void {
    this.queueDataSource.paginator = this.queuePaginator;
    this.queueDataSource.sort = this.queueSort;
  }

  switchTab(tab: 'queue' | 'history'): void {
    this.activeTab = tab;
    if (tab === 'history' && this.historyDataSource.data.length === 0) {
      this.loadHistory();
    }
  }

  loadQueue(): void {
    this.isLoading = true;
    this.healthTipsService.getQueue().subscribe({
      next: (response) => {
        let tips = response.data;
        if (this.filterStatus !== 'ALL') {
          tips = tips.filter(t => t.status === this.filterStatus);
        }
        this.queueDataSource.data = tips;
        this.stats = response.stats;
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading health tip queue:', error);
        this.showSnackBar('Failed to load health tip queue', 'error');
        this.isLoading = false;
      }
    });
  }

  loadHistory(): void {
    this.isLoading = true;
    this.healthTipsService.getHistory(this.historyPage, this.historyPageSize).subscribe({
      next: (response) => {
        this.historyDataSource.data = response.data;
        this.historyTotalElements = response.totalElements;
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading health tip history:', error);
        this.showSnackBar('Failed to load history', 'error');
        this.isLoading = false;
      }
    });
  }

  onHistoryPageChange(event: any): void {
    this.historyPage = event.pageIndex;
    this.historyPageSize = event.pageSize;
    this.loadHistory();
  }

  filterByStatus(status: string): void {
    this.filterStatus = status;
    this.loadQueue();
  }

  applyFilter(event: Event): void {
    const filterValue = (event.target as HTMLInputElement).value;
    this.queueDataSource.filter = filterValue.trim().toLowerCase();
    if (this.queueDataSource.paginator) {
      this.queueDataSource.paginator.firstPage();
    }
  }

  generateWeeklyTips(): void {
    if (this.isGenerating) return;
    this.isGenerating = true;
    this.healthTipsService.generateWeeklyTips().subscribe({
      next: (tips) => {
        this.showSnackBar(`Generated ${tips.length} health tips for the week`, 'success');
        this.loadQueue();
        this.isGenerating = false;
      },
      error: (error) => {
        console.error('Error generating tips:', error);
        this.showSnackBar('Failed to generate tips. Try again.', 'error');
        this.isGenerating = false;
      }
    });
  }

  // Inline edit
  startEdit(tip: HealthTip): void {
    this.editingTipId = tip.id;
    this.editMessage = tip.message;
  }

  cancelEdit(): void {
    this.editingTipId = null;
    this.editMessage = '';
  }

  saveEdit(tip: HealthTip): void {
    if (!this.editMessage.trim()) return;
    this.healthTipsService.editTip(tip.id, this.editMessage.trim()).subscribe({
      next: () => {
        this.showSnackBar('Tip updated successfully', 'success');
        this.editingTipId = null;
        this.editMessage = '';
        this.loadQueue();
      },
      error: (error) => {
        console.error('Error editing tip:', error);
        this.showSnackBar('Failed to update tip', 'error');
      }
    });
  }

  approveTip(tip: HealthTip): void {
    this.healthTipsService.approveTip(tip.id).subscribe({
      next: () => {
        this.showSnackBar('Tip approved', 'success');
        this.loadQueue();
      },
      error: (error) => {
        console.error('Error approving tip:', error);
        this.showSnackBar('Failed to approve tip', 'error');
      }
    });
  }

  rejectTip(tip: HealthTip): void {
    if (confirm('Reject this health tip?')) {
      this.healthTipsService.rejectTip(tip.id).subscribe({
        next: () => {
          this.showSnackBar('Tip rejected', 'success');
          this.loadQueue();
        },
        error: (error) => {
          console.error('Error rejecting tip:', error);
          this.showSnackBar('Failed to reject tip', 'error');
        }
      });
    }
  }

  sendNow(tip: HealthTip): void {
    if (confirm('Send this health tip to all subscribed users NOW?')) {
      this.healthTipsService.sendNow(tip.id).subscribe({
        next: (response) => {
          const count = response?.notifiedCount || 0;
          this.showSnackBar(`Tip sent to ${count} users`, 'success');
          this.loadQueue();
        },
        error: (error) => {
          console.error('Error sending tip:', error);
          this.showSnackBar(error?.error?.message || 'Failed to send tip', 'error');
        }
      });
    }
  }

  getStatusColor(status: string): string {
    return this.healthTipsService.getStatusColor(status);
  }

  getStatusIcon(status: string): string {
    return this.healthTipsService.getStatusIcon(status);
  }

  formatDate(date: string | null): string {
    if (!date) return '-';
    return new Date(date).toLocaleDateString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric'
    });
  }

  formatDateTime(date: string | null): string {
    if (!date) return '-';
    return new Date(date).toLocaleString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  private showSnackBar(message: string, type: 'success' | 'error'): void {
    this.snackBar.open(message, 'Close', {
      duration: 3000,
      horizontalPosition: 'end',
      verticalPosition: 'top',
      panelClass: type === 'success' ? 'snackbar-success' : 'snackbar-error'
    });
  }
}
