import { Component, OnDestroy, OnInit } from '@angular/core';
import { Subscription } from 'rxjs';
import { SwalService } from '../../../core/services/swal.service';
import { TransportDriver, TransportOwnerService, TransportVehicle } from '../../../core/services/transport-owner.service';
import { TransportStore } from '../transport-store.service';

@Component({
  selector: 'app-transport-drivers',
  template: `
<div class="page">
  <div class="head">
    <div><h2>Drivers</h2><p class="sub">Add the driver's mobile number. The driver installs the Nammaooru app, logs in with that number, and opens Where is Bus &rarr; Driver mode to start trips.</p></div>
    <button mat-raised-button color="primary" (click)="startAdd()"><mat-icon>person_add</mat-icon> Add driver</button>
  </div>

  <div class="form" *ngIf="editing">
    <h3>{{ editing.id ? 'Edit driver' : 'Add driver' }}</h3>
    <div class="grid">
      <mat-form-field appearance="outline"><mat-label>Driver name *</mat-label><input matInput [(ngModel)]="editing.name"></mat-form-field>
      <mat-form-field appearance="outline"><mat-label>Mobile number (10 digits) *</mat-label><input matInput [(ngModel)]="editing.phone" maxlength="10" inputmode="numeric"></mat-form-field>
    </div>
    <div class="actions">
      <button mat-raised-button color="primary" [disabled]="saving" (click)="save()"><mat-icon>save</mat-icon> {{ saving ? 'Saving...' : 'Save' }}</button>
      <button mat-button (click)="editing = null">Cancel</button>
    </div>
  </div>

  <table mat-table [dataSource]="drivers" class="mat-elevation-z1 full" *ngIf="drivers.length > 0">
    <ng-container matColumnDef="name"><th mat-header-cell *matHeaderCellDef>Driver</th><td mat-cell *matCellDef="let d"><strong>{{ d.name }}</strong></td></ng-container>
    <ng-container matColumnDef="phone"><th mat-header-cell *matHeaderCellDef>Mobile</th><td mat-cell *matCellDef="let d">{{ d.phone }}</td></ng-container>
    <ng-container matColumnDef="vehicles"><th mat-header-cell *matHeaderCellDef>Assigned vehicles</th><td mat-cell *matCellDef="let d">{{ assigned(d) || '-' }}</td></ng-container>
    <ng-container matColumnDef="status"><th mat-header-cell *matHeaderCellDef>Now</th><td mat-cell *matCellDef="let d"><span [class]="'chip ' + liveState(d).toLowerCase()">{{ liveState(d) }}</span></td></ng-container>
    <ng-container matColumnDef="actions"><th mat-header-cell *matHeaderCellDef></th><td mat-cell *matCellDef="let d" class="acts">
      <button mat-icon-button color="primary" (click)="edit(d)" title="Edit"><mat-icon>edit</mat-icon></button>
      <button mat-icon-button color="warn" (click)="remove(d)" title="Remove"><mat-icon>delete</mat-icon></button>
    </td></ng-container>
    <tr mat-header-row *matHeaderRowDef="cols"></tr>
    <tr mat-row *matRowDef="let row; columns: cols;"></tr>
  </table>
  <div class="empty" *ngIf="drivers.length === 0 && !editing">No drivers yet.</div>
</div>`,
  styles: [`
    .head { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; margin-bottom: 14px; h2 { margin: 0; } .sub { margin: 4px 0 0; color: #6b7280; font-size: 13px; max-width: 720px; } }
    .form { background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; padding: 16px; margin-bottom: 16px; h3 { margin: 0 0 10px; } }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 10px; }
    .actions { display: flex; gap: 8px; margin-top: 6px; }
    .full { width: 100%; background: #fff; border-radius: 12px; overflow: hidden; }
    .acts { white-space: nowrap; }
    .chip { font-size: 10.5px; font-weight: 700; padding: 3px 8px; border-radius: 999px; &.moving { background: #e8f5e9; color: #2e7d32; } &.stopped { background: #e3f2fd; color: #1565c0; } &.offline { background: #eceff1; color: #546e7a; } &.idle { background: #f3f4f6; color: #6b7280; } }
    .empty { padding: 30px; text-align: center; color: #9ca3af; }
  `]
})
export class TransportDriversComponent implements OnInit, OnDestroy {
  cols = ['name', 'phone', 'vehicles', 'status', 'actions'];
  drivers: TransportDriver[] = [];
  vehicles: TransportVehicle[] = [];
  editing: TransportDriver | null = null;
  saving = false;
  private sub?: Subscription;

  constructor(private store: TransportStore, private svc: TransportOwnerService, private swal: SwalService) {}

  ngOnInit(): void { this.sub = this.store.data$.subscribe(d => { if (!d) return; this.drivers = d.drivers || []; this.vehicles = d.vehicles || []; }); }
  ngOnDestroy(): void { this.sub?.unsubscribe(); }

  assigned(d: TransportDriver): string { return this.vehicles.filter(v => v.driverId === d.id).map(v => v.name).join(', '); }
  liveState(d: TransportDriver): string {
    const vs = this.vehicles.filter(v => v.driverId === d.id);
    if (vs.length === 0) return 'IDLE';
    const states = vs.map(v => this.store.stateOf(v.id!));
    return states.includes('MOVING') ? 'MOVING' : states.includes('STOPPED') ? 'STOPPED' : 'OFFLINE';
  }

  startAdd(): void { this.editing = { name: '', phone: '' }; }
  edit(d: TransportDriver): void { this.editing = { ...d }; }
  save(): void {
    if (!this.editing) return;
    const phone = this.editing.phone.replace(/\D/g, '');
    if (!this.editing.name.trim()) { this.swal.error('Driver name is required'); return; }
    if (phone.length !== 10) { this.swal.error('Enter a 10-digit mobile number'); return; }
    this.saving = true;
    this.svc.saveDriver({ ...this.editing, phone }).subscribe({
      next: (r: any) => { this.saving = false; if (r?.success === false) { this.swal.error(r.message); return; } this.editing = null; this.store.refresh(); this.swal.success('Driver saved'); },
      error: (e) => { this.saving = false; this.swal.error('Could not save', e?.error?.message || ''); }
    });
  }
  remove(d: TransportDriver): void {
    if (!confirm(`Remove driver ${d.name}?`)) return;
    this.svc.deleteDriver(d.id!).subscribe({ next: () => { this.store.refresh(); this.swal.success('Driver removed'); }, error: (e) => this.swal.error('Could not remove', e?.error?.message || '') });
  }
}
