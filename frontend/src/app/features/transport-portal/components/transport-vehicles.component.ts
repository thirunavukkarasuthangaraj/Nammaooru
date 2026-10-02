import { Component, OnDestroy, OnInit } from '@angular/core';
import { Subscription } from 'rxjs';
import { SwalService } from '../../../core/services/swal.service';
import { TransportDriver, TransportOwnerService, TransportRoute, TransportVehicle, VEHICLE_TYPES } from '../../../core/services/transport-owner.service';
import { TransportStore } from '../transport-store.service';

@Component({
  selector: 'app-transport-vehicles',
  template: `
<div class="page">
  <div class="head">
    <div><h2>Vehicles</h2><p class="sub">Any type: bus, lorry, van, auto, car, bike, tractor. Only buses can be shown to the public.</p></div>
    <button mat-raised-button color="primary" (click)="startAdd()"><mat-icon>add</mat-icon> Add vehicle</button>
  </div>

  <div class="form" *ngIf="editing">
    <h3>{{ editing.id ? 'Edit vehicle' : 'Add vehicle' }}</h3>
    <div class="grid">
      <mat-form-field appearance="outline"><mat-label>Type</mat-label>
        <mat-select [(ngModel)]="editing.vehicleType" (selectionChange)="onTypeChange()"><mat-option *ngFor="let t of types" [value]="t">{{ t }}</mat-option></mat-select></mat-form-field>
      <mat-form-field appearance="outline"><mat-label>Registration number *</mat-label><input matInput [(ngModel)]="editing.regNo" placeholder="TN23AB1234" style="text-transform:uppercase"></mat-form-field>
      <mat-form-field appearance="outline"><mat-label>Display name</mat-label><input matInput [(ngModel)]="editing.name" placeholder="e.g. Route 7 Morning"></mat-form-field>
      <mat-form-field appearance="outline"><mat-label>Route</mat-label>
        <mat-select [(ngModel)]="editing.routeId"><mat-option [value]="null">No route</mat-option><mat-option *ngFor="let r of routes" [value]="r.id">{{ r.name }}</mat-option></mat-select></mat-form-field>
      <mat-form-field appearance="outline"><mat-label>Driver</mat-label>
        <mat-select [(ngModel)]="editing.driverId"><mat-option [value]="null">No driver</mat-option><mat-option *ngFor="let d of drivers" [value]="d.id">{{ d.name }} &middot; {{ d.phone }}</mat-option></mat-select></mat-form-field>
      <div class="toggle" *ngIf="editing.vehicleType === 'BUS'">
        <mat-slide-toggle [(ngModel)]="editing.isPublic" color="primary">Show to public on "Where is Bus"</mat-slide-toggle>
        <small>Passengers can see this bus live in the app</small>
      </div>
    </div>
    <div class="actions">
      <button mat-raised-button color="primary" [disabled]="saving" (click)="save()"><mat-icon>save</mat-icon> {{ saving ? 'Saving...' : 'Save' }}</button>
      <button mat-button (click)="editing = null">Cancel</button>
    </div>
  </div>

  <div class="cards">
    <div class="empty" *ngIf="vehicles.length === 0 && !editing">No vehicles yet. Click "Add vehicle".</div>
    <div class="card" *ngFor="let v of vehicles">
      <div class="card-top">
        <mat-icon [class]="'ico ' + state(v).toLowerCase()">{{ icon(v.vehicleType) }}</mat-icon>
        <div class="t"><strong>{{ v.name }}</strong><small>{{ v.vehicleType }} &middot; {{ v.regNo }}</small></div>
        <span [class]="'chip ' + state(v).toLowerCase()">{{ state(v) }}</span>
      </div>
      <div class="meta">
        <span><mat-icon>alt_route</mat-icon>{{ v.routeName || 'No route' }}</span>
        <span><mat-icon>badge</mat-icon>{{ v.driverName || 'No driver' }}</span>
        <span *ngIf="v.isPublic" class="pub"><mat-icon>public</mat-icon>Public</span>
      </div>
      <div class="card-actions">
        <button mat-button color="primary" (click)="edit(v)"><mat-icon>edit</mat-icon> Edit</button>
        <button mat-button color="warn" (click)="remove(v)"><mat-icon>delete</mat-icon> Remove</button>
      </div>
    </div>
  </div>
</div>`,
  styles: [`
    .head { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; margin-bottom: 14px; h2 { margin: 0; } .sub { margin: 4px 0 0; color: #6b7280; font-size: 13px; } }
    .form { background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; padding: 16px; margin-bottom: 16px; h3 { margin: 0 0 10px; } }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 10px; }
    .toggle { display: flex; flex-direction: column; justify-content: center; small { color: #6b7280; font-size: 12px; margin-left: 2px; } }
    .actions { display: flex; gap: 8px; margin-top: 6px; }
    .cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 12px; }
    .card { background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; padding: 14px; display: flex; flex-direction: column; gap: 10px; }
    .card-top { display: flex; align-items: center; gap: 10px; .t { flex: 1; display: flex; flex-direction: column; small { color: #6b7280; font-size: 12px; } } }
    .ico { font-size: 30px; width: 30px; height: 30px; &.moving { color: #2e7d32; } &.stopped { color: #1565c0; } &.offline { color: #90a4ae; } }
    .chip { font-size: 10.5px; font-weight: 700; padding: 3px 8px; border-radius: 999px; &.moving { background: #e8f5e9; color: #2e7d32; } &.stopped { background: #e3f2fd; color: #1565c0; } &.offline { background: #eceff1; color: #546e7a; } }
    .meta { display: flex; flex-wrap: wrap; gap: 10px; font-size: 12.5px; color: #4b5563; span { display: inline-flex; align-items: center; gap: 4px; } mat-icon { font-size: 16px; width: 16px; height: 16px; } .pub { color: #2e7d32; font-weight: 600; } }
    .card-actions { display: flex; gap: 4px; margin-top: auto; }
    .empty { grid-column: 1 / -1; padding: 30px; text-align: center; color: #9ca3af; }
  `]
})
export class TransportVehiclesComponent implements OnInit, OnDestroy {
  types = VEHICLE_TYPES;
  vehicles: TransportVehicle[] = [];
  drivers: TransportDriver[] = [];
  routes: TransportRoute[] = [];
  editing: TransportVehicle | null = null;
  saving = false;
  private sub?: Subscription;

  constructor(private store: TransportStore, private svc: TransportOwnerService, private swal: SwalService) {}

  ngOnInit(): void {
    this.sub = this.store.data$.subscribe(d => { if (!d) return; this.vehicles = d.vehicles || []; this.drivers = d.drivers || []; this.routes = d.routes || []; });
  }
  ngOnDestroy(): void { this.sub?.unsubscribe(); }

  state(v: TransportVehicle) { return this.store.stateOf(v.id!); }
  icon(t: string): string {
    return ({ BUS: 'directions_bus', LORRY: 'local_shipping', VAN: 'airport_shuttle', AUTO: 'electric_rickshaw', CAR: 'directions_car', BIKE: 'two_wheeler', TRACTOR: 'agriculture' } as any)[t] || 'commute';
  }

  startAdd(): void { this.editing = { vehicleType: 'BUS', regNo: '', name: '', routeId: null, driverId: null, isPublic: false }; window.scrollTo({ top: 0, behavior: 'smooth' }); }
  edit(v: TransportVehicle): void { this.editing = { ...v }; window.scrollTo({ top: 0, behavior: 'smooth' }); }
  onTypeChange(): void { if (this.editing && this.editing.vehicleType !== 'BUS') this.editing.isPublic = false; }

  save(): void {
    if (!this.editing) return;
    if (!this.editing.regNo.trim()) { this.swal.error('Registration number is required'); return; }
    this.saving = true;
    this.svc.saveVehicle(this.editing).subscribe({
      next: (r: any) => { this.saving = false; if (r?.success === false) { this.swal.error(r.message); return; } this.editing = null; this.store.refresh(); this.swal.success('Vehicle saved'); },
      error: (e) => { this.saving = false; this.swal.error('Could not save', e?.error?.message || ''); }
    });
  }

  remove(v: TransportVehicle): void {
    if (!confirm(`Remove vehicle ${v.name}?`)) return;
    this.svc.deleteVehicle(v.id!).subscribe({
      next: () => { this.store.refresh(); this.swal.success('Vehicle removed'); },
      error: (e) => this.swal.error('Could not remove', e?.error?.message || '')
    });
  }
}
