import { Component, OnInit } from '@angular/core';
import { SwalService } from '../../../../core/services/swal.service';
import { TransportAdminService, TransporterRow } from '../../../../core/services/transport-admin.service';

@Component({
  selector: 'app-transport-management',
  templateUrl: './transport-management.component.html',
  styleUrls: ['./transport-management.component.scss']
})
export class TransportManagementComponent implements OnInit {

  rows: TransporterRow[] = [];
  isLoading = false;
  filterStatus = 'PENDING';
  pendingCount = 0;
  liveBuses: any[] = [];
  livePositions: any[] = [];

  displayedColumns = ['company', 'owner', 'phone', 'vehicles', 'status', 'createdAt', 'actions'];

  statusOptions = [
    { value: 'PENDING', label: 'Pending approval' },
    { value: 'ACTIVE', label: 'Active' },
    { value: 'BLOCKED', label: 'Blocked' },
    { value: '', label: 'All' }
  ];

  constructor(private service: TransportAdminService, private swal: SwalService) {}

  ngOnInit(): void {
    this.load();
    this.loadLive();
  }

  load(): void {
    this.isLoading = true;
    this.service.listTransporters(this.filterStatus).subscribe({
      next: (res) => {
        const data = res?.data || res || {};
        this.rows = data.content || [];
        this.pendingCount = data.pendingCount || 0;
        this.isLoading = false;
      },
      error: (err) => {
        this.isLoading = false;
        this.swal.error('Failed to load transporters', err?.error?.message || '');
      }
    });
  }

  loadLive(): void {
    this.service.publicBuses().subscribe({
      next: (res) => {
        const data = res?.data || {};
        this.liveBuses = data.buses || [];
        this.livePositions = data.positions || [];
      },
      error: () => {}
    });
  }

  positionFor(busId: number): any {
    return this.livePositions.find(p => p.vehicleId === busId);
  }

  setStatus(row: TransporterRow, status: 'ACTIVE' | 'BLOCKED' | 'PENDING'): void {
    const verb = status === 'ACTIVE' ? 'approve' : status === 'BLOCKED' ? 'block' : 'move to pending';
    if (!confirm(`Are you sure you want to ${verb} ${row.companyName}?`)) return;
    this.service.setStatus(row.id, status).subscribe({
      next: () => {
        this.swal.success('Updated', `${row.companyName} is now ${status.toLowerCase()}`);
        this.load();
      },
      error: (err) => this.swal.error('Update failed', err?.error?.message || '')
    });
  }

  formatDate(iso: string): string {
    if (!iso) return '-';
    const d = new Date(iso);
    return isNaN(d.getTime()) ? iso : d.toLocaleString('en-IN', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
  }
}
