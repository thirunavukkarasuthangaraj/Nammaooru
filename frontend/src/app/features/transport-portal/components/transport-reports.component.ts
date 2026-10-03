import { Component, OnDestroy, OnInit } from '@angular/core';
import { Subscription } from 'rxjs';
import { TransportDriver, TransportOwnerService, TransportVehicle } from '../../../core/services/transport-owner.service';
import { TransportStore } from '../transport-store.service';

interface Row { name: string; trips: number; km: number; minutes: number; }

/** Simple reports built from trip history: per vehicle, per driver, per day. */
@Component({
  selector: 'app-transport-reports',
  template: `
<div class="page">
  <div class="head">
    <div><h2>Reports</h2><p class="sub">Trips, kilometres and hours on road, from the trips drivers ran in the app.</p></div>
    <div class="range">
      <mat-form-field appearance="outline"><mat-label>From</mat-label><input matInput type="date" [(ngModel)]="from" (change)="compute()"></mat-form-field>
      <mat-form-field appearance="outline"><mat-label>To</mat-label><input matInput type="date" [(ngModel)]="to" (change)="compute()"></mat-form-field>
      <button mat-stroked-button (click)="exportCsv()" [disabled]="filtered.length === 0"><mat-icon>download</mat-icon> CSV</button>
    </div>
  </div>

  <div class="totals">
    <div><strong>{{ filtered.length }}</strong><span>trips</span></div>
    <div><strong>{{ totalKm | number:'1.0-0' }}</strong><span>km</span></div>
    <div><strong>{{ hours(totalMin) }}</strong><span>on road</span></div>
    <div><strong>{{ avgKm | number:'1.0-0' }}</strong><span>km / trip</span></div>
  </div>

  <div class="grid">
    <section class="card">
      <h3>Per vehicle</h3>
      <table><tr><th>Vehicle</th><th>Trips</th><th>Km</th><th>Hours</th></tr>
        <tr *ngFor="let r of byVehicle"><td>{{ r.name }}</td><td>{{ r.trips }}</td><td>{{ r.km | number:'1.0-1' }}</td><td>{{ hours(r.minutes) }}</td></tr>
      </table>
      <div class="empty" *ngIf="byVehicle.length === 0">No trips in this range.</div>
    </section>
    <section class="card">
      <h3>Per driver</h3>
      <table><tr><th>Driver</th><th>Trips</th><th>Km</th><th>Hours</th></tr>
        <tr *ngFor="let r of byDriver"><td>{{ r.name }}</td><td>{{ r.trips }}</td><td>{{ r.km | number:'1.0-1' }}</td><td>{{ hours(r.minutes) }}</td></tr>
      </table>
      <div class="empty" *ngIf="byDriver.length === 0">No trips in this range.</div>
    </section>
    <section class="card wide">
      <h3>Per day</h3>
      <table><tr><th>Day</th><th>Trips</th><th>Km</th><th>Hours</th></tr>
        <tr *ngFor="let r of byDay"><td>{{ r.name }}</td><td>{{ r.trips }}</td><td>{{ r.km | number:'1.0-1' }}</td><td>{{ hours(r.minutes) }}</td></tr>
      </table>
      <div class="empty" *ngIf="byDay.length === 0">No trips in this range.</div>
    </section>
  </div>
</div>`,
  styles: [`
    .head { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; flex-wrap: wrap; margin-bottom: 12px; h2 { margin: 0; } .sub { margin: 4px 0 0; color: #6b7280; font-size: 13px; } }
    .range { display: flex; gap: 8px; align-items: center; mat-form-field { width: 160px; margin-bottom: -1.25em; } }
    .totals { display: grid; grid-template-columns: repeat(auto-fit, minmax(130px, 1fr)); gap: 10px; margin-bottom: 12px; div { background: #fff; border: 1px solid #e5e7eb; border-radius: 12px; padding: 12px; display: flex; flex-direction: column; strong { font-size: 24px; font-weight: 800; color: #0d47a1; } span { font-size: 12px; color: #6b7280; } } }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 12px; }
    .card { background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; padding: 14px; h3 { margin: 0 0 8px; font-size: 15px; } &.wide { grid-column: 1 / -1; } }
    table { width: 100%; border-collapse: collapse; th { text-align: left; font-size: 12px; color: #6b7280; padding: 6px 8px; border-bottom: 1px solid #eee; } td { padding: 6px 8px; border-bottom: 1px solid #f3f4f6; } }
    .empty { color: #9ca3af; padding: 10px 4px; }
  `]
})
export class TransportReportsComponent implements OnInit, OnDestroy {
  vehicles: TransportVehicle[] = [];
  drivers: TransportDriver[] = [];
  trips: any[] = [];
  filtered: any[] = [];
  from = ''; to = '';
  byVehicle: Row[] = []; byDriver: Row[] = []; byDay: Row[] = [];
  totalKm = 0; totalMin = 0; avgKm = 0;
  private sub?: Subscription;

  constructor(private store: TransportStore, private svc: TransportOwnerService) {}

  ngOnInit(): void {
    const d = new Date(); const iso = (x: Date) => x.toISOString().slice(0, 10);
    this.to = iso(d); d.setDate(d.getDate() - 6); this.from = iso(d);
    this.sub = this.store.data$.subscribe(s => { if (!s) return; this.vehicles = s.vehicles || []; this.drivers = s.drivers || []; this.compute(); });
    this.svc.trips(undefined, 0, 500).subscribe({ next: (r: any) => { this.trips = (r && r.content) ? r.content : (Array.isArray(r) ? r : []); this.compute(); }, error: () => {} });
  }
  ngOnDestroy(): void { this.sub?.unsubscribe(); }

  hours(min: number): string { return min < 60 ? `${Math.round(min)} min` : `${Math.floor(min / 60)} h ${Math.round(min % 60)} min`; }

  compute(): void {
    const f = this.from ? new Date(this.from + 'T00:00:00') : null, t = this.to ? new Date(this.to + 'T23:59:59') : null;
    this.filtered = this.trips.filter(tr => { const s = new Date(tr.startedAt); return (!f || s >= f) && (!t || s <= t); });
    const mins = (tr: any) => { const a = new Date(tr.startedAt).getTime(), b = tr.endedAt ? new Date(tr.endedAt).getTime() : Date.now(); return Math.max(0, (b - a) / 60000); };
    const group = (key: (tr: any) => string): Row[] => {
      const m = new Map<string, Row>();
      this.filtered.forEach(tr => { const k = key(tr); const r = m.get(k) || { name: k, trips: 0, km: 0, minutes: 0 }; r.trips++; r.km += +(tr.distanceKm || 0); r.minutes += mins(tr); m.set(k, r); });
      return Array.from(m.values()).sort((a, b) => b.km - a.km);
    };
    this.byVehicle = group(tr => this.vehicles.find(v => v.id === tr.vehicleId)?.name || `#${tr.vehicleId}`);
    this.byDriver = group(tr => this.drivers.find(d => d.id === tr.driverId)?.name || `#${tr.driverId}`);
    this.byDay = group(tr => new Date(tr.startedAt).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })).sort((a, b) => a.name.localeCompare(b.name));
    this.totalKm = this.filtered.reduce((s, tr) => s + (+tr.distanceKm || 0), 0);
    this.totalMin = this.filtered.reduce((s, tr) => s + mins(tr), 0);
    this.avgKm = this.filtered.length ? this.totalKm / this.filtered.length : 0;
  }

  exportCsv(): void {
    const rows = [['Started', 'Ended', 'Vehicle', 'Driver', 'Direction', 'Km', 'Minutes']];
    this.filtered.forEach(tr => rows.push([tr.startedAt, tr.endedAt || '', this.vehicles.find(v => v.id === tr.vehicleId)?.name || '', this.drivers.find(d => d.id === tr.driverId)?.name || '', tr.direction || '', String(tr.distanceKm ?? ''), String(Math.round(((tr.endedAt ? new Date(tr.endedAt).getTime() : Date.now()) - new Date(tr.startedAt).getTime()) / 60000))]));
    const csv = rows.map(r => r.map(c => `"${String(c).replace(/"/g, '""')}"`).join(',')).join('\n');
    const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv' })); a.download = `trips_${this.from}_${this.to}.csv`; a.click();
  }
}
