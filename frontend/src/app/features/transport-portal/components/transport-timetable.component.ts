import { Component, OnDestroy, OnInit } from '@angular/core';
import { Subscription } from 'rxjs';
import { SwalService } from '../../../core/services/swal.service';
import { TransportOwnerService, TransportRoute, TransportSchedule, TransportVehicle } from '../../../core/services/transport-owner.service';
import { TransportStore } from '../transport-store.service';

@Component({
  selector: 'app-transport-timetable',
  template: `
<div class="page">
  <div class="head">
    <div><h2>Timetable</h2><p class="sub">When each bus leaves A for B and comes back. Example: 10:00 Tirupattur to Alangayam arriving 11:00, then 11:20 back arriving 12:20. The map shows where each bus should be from this timetable even when its GPS is off.</p></div>
  </div>

  <div class="form">
    <h3>Add departure</h3>
    <div class="grid">
      <mat-form-field appearance="outline"><mat-label>Vehicle *</mat-label>
        <mat-select [(ngModel)]="form.vehicleId"><mat-option *ngFor="let v of vehicles" [value]="v.id" [disabled]="!v.routeId">{{ v.name }} <span *ngIf="!v.routeId">(assign a route first)</span></mat-option></mat-select></mat-form-field>
      <mat-form-field appearance="outline"><mat-label>Direction *</mat-label>
        <mat-select [(ngModel)]="form.direction">
          <mat-option value="AB">A &rarr; B &nbsp;{{ dirLabel('AB') }}</mat-option>
          <mat-option value="BA">B &rarr; A &nbsp;{{ dirLabel('BA') }}</mat-option>
        </mat-select></mat-form-field>
      <mat-form-field appearance="outline"><mat-label>Departs (24h) *</mat-label><input matInput type="time" [(ngModel)]="form.departTime"></mat-form-field>
      <mat-form-field appearance="outline"><mat-label>Arrives (24h) *</mat-label><input matInput type="time" [(ngModel)]="form.arriveTime"></mat-form-field>
      <mat-form-field appearance="outline"><mat-label>Days</mat-label>
        <mat-select [(ngModel)]="form.days">
          <mat-option value="DAILY">Daily</mat-option>
          <mat-option value="MON,TUE,WED,THU,FRI">Weekdays</mat-option>
          <mat-option value="SAT,SUN">Weekends</mat-option>
        </mat-select></mat-form-field>
    </div>
    <div class="actions">
      <button mat-raised-button color="primary" [disabled]="saving" (click)="save()"><mat-icon>add</mat-icon> {{ saving ? 'Saving...' : 'Add' }}</button>
      <button mat-stroked-button [disabled]="saving || !canReturn()" (click)="addReturn()" title="Adds the opposite direction 20 min after arrival, same duration"><mat-icon>swap_horiz</mat-icon> Add + return trip</button>
    </div>
  </div>

  <div class="vehicle" *ngFor="let v of vehiclesWithRows()">
    <div class="v-head">
      <mat-icon>directions_bus</mat-icon>
      <div><strong>{{ v.name }}</strong><small>{{ v.regNo }} · {{ v.routeName || 'no route' }}</small></div>
      <span class="next" *ngIf="nextOf(v) as n">Next: {{ n.departTime }} {{ dirLabel(n.direction, v) }}</span>
    </div>
    <table>
      <tr><th>Departs</th><th>Direction</th><th>Arrives</th><th>Days</th><th></th></tr>
      <tr *ngFor="let s of rowsOf(v.id!)" [class.now]="isNow(s)">
        <td><strong>{{ s.departTime }}</strong></td>
        <td>{{ dirLabel(s.direction, v) }}</td>
        <td>{{ s.arriveTime }}</td>
        <td>{{ s.days === 'DAILY' ? 'Daily' : s.days }}</td>
        <td><button mat-icon-button color="warn" (click)="remove(s)" title="Remove"><mat-icon>delete</mat-icon></button></td>
      </tr>
    </table>
  </div>
  <div class="empty" *ngIf="schedules.length === 0">No timetable yet. Add the first departure above.</div>
</div>`,
  styles: [`
    .head { margin-bottom: 14px; h2 { margin: 0; } .sub { margin: 4px 0 0; color: #6b7280; font-size: 13px; max-width: 760px; } }
    .form { background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; padding: 16px; margin-bottom: 16px; h3 { margin: 0 0 10px; } }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 10px; }
    .actions { display: flex; gap: 8px; margin-top: 4px; flex-wrap: wrap; }
    .vehicle { background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; padding: 14px; margin-bottom: 12px; }
    .v-head { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; mat-icon { color: #1565c0; } div { display: flex; flex-direction: column; flex: 1; small { color: #6b7280; font-size: 12px; } } }
    .next { background: #e8f5e9; color: #1b5e20; font-weight: 700; font-size: 12px; padding: 4px 10px; border-radius: 999px; }
    table { width: 100%; border-collapse: collapse; th { text-align: left; font-size: 12px; color: #6b7280; padding: 6px 8px; border-bottom: 1px solid #eee; } td { padding: 6px 8px; border-bottom: 1px solid #f3f4f6; } tr.now td { background: #e8f0fe; } }
    .empty { padding: 30px; text-align: center; color: #9ca3af; }
  `]
})
export class TransportTimetableComponent implements OnInit, OnDestroy {
  vehicles: TransportVehicle[] = [];
  routes: TransportRoute[] = [];
  schedules: TransportSchedule[] = [];
  form: any = { vehicleId: null, direction: 'AB', departTime: '', arriveTime: '', days: 'DAILY' };
  saving = false;
  private sub?: Subscription;

  constructor(private store: TransportStore, private svc: TransportOwnerService, private swal: SwalService) {}

  ngOnInit(): void {
    this.sub = this.store.data$.subscribe(d => {
      if (!d) return;
      this.vehicles = d.vehicles || []; this.routes = d.routes || []; this.schedules = d.schedules || [];
      if (!this.form.vehicleId && this.vehicles.length) this.form.vehicleId = this.vehicles.find(v => v.routeId)?.id || null;
    });
  }
  ngOnDestroy(): void { this.sub?.unsubscribe(); }

  routeOf(v?: TransportVehicle | null): TransportRoute | undefined { return this.routes.find(r => r.id === v?.routeId); }
  dirLabel(dir: string, v?: TransportVehicle): string {
    const r = this.routeOf(v || this.vehicles.find(x => x.id === this.form.vehicleId));
    if (!r) return '';
    return dir === 'AB' ? `${r.source} → ${r.destination}` : `${r.destination} → ${r.source}`;
  }
  rowsOf(vehicleId: number): TransportSchedule[] { return this.schedules.filter(s => s.vehicleId === vehicleId).sort((a, b) => a.departTime.localeCompare(b.departTime)); }
  vehiclesWithRows(): TransportVehicle[] { return this.vehicles.filter(v => this.rowsOf(v.id!).length > 0); }

  private nowMin(): number { const d = new Date(); return d.getHours() * 60 + d.getMinutes(); }
  private min(t: string): number { const [h, m] = t.split(':').map(Number); return h * 60 + m; }
  isNow(s: TransportSchedule): boolean { const n = this.nowMin(); return this.min(s.departTime) <= n && n <= this.min(s.arriveTime); }
  nextOf(v: TransportVehicle): TransportSchedule | null {
    const n = this.nowMin();
    const rows = this.rowsOf(v.id!);
    return rows.find(s => this.min(s.departTime) >= n) || rows[0] || null;
  }

  canReturn(): boolean { return !!(this.form.vehicleId && this.form.departTime && this.form.arriveTime); }

  save(cb?: () => void): void {
    if (!this.form.vehicleId) { this.swal.error('Choose a vehicle'); return; }
    if (!this.form.departTime || !this.form.arriveTime) { this.swal.error('Enter departure and arrival time'); return; }
    this.saving = true;
    this.svc.saveSchedule({ ...this.form }).subscribe({
      next: (r: any) => { this.saving = false; if (r?.success === false) { this.swal.error(r.message); return; } this.store.refresh(); if (cb) cb(); else this.swal.success('Departure added'); },
      error: (e) => { this.saving = false; this.swal.error('Could not save', e?.error?.message || ''); }
    });
  }

  /** Adds this departure, then the opposite direction 20 minutes after arrival with the same duration. */
  addReturn(): void {
    const dur = this.min(this.form.arriveTime) - this.min(this.form.departTime);
    if (dur <= 0) { this.swal.error('Arrival must be after departure'); return; }
    const first = { ...this.form };
    this.save(() => {
      const dep = this.min(first.arriveTime) + 20, arr = dep + dur;
      const fmt = (m: number) => `${String(Math.floor((m % 1440) / 60)).padStart(2, '0')}:${String(m % 60).padStart(2, '0')}`;
      this.form = { ...first, direction: first.direction === 'AB' ? 'BA' : 'AB', departTime: fmt(dep), arriveTime: fmt(arr) };
      this.save(() => { this.swal.success('Departure and return trip added'); this.form = { ...this.form, departTime: '', arriveTime: '' }; });
    });
  }

  remove(s: TransportSchedule): void {
    if (!confirm(`Remove ${s.departTime} departure?`)) return;
    this.svc.deleteSchedule(s.id!).subscribe({ next: () => this.store.refresh(), error: (e) => this.swal.error('Could not remove', e?.error?.message || '') });
  }
}
