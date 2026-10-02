import { AfterViewChecked, Component, ElementRef, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { Subscription } from 'rxjs';
import { SwalService } from '../../../core/services/swal.service';
import { TransportDriver, TransportOwnerService, TransportVehicle } from '../../../core/services/transport-owner.service';
import { TransportStore } from '../transport-store.service';

declare var google: any;

@Component({
  selector: 'app-transport-trips',
  template: `
<div class="page">
  <div class="head">
    <div><h2>Trips</h2><p class="sub">Every trip a driver started, with distance and the trail on the map.</p></div>
    <mat-form-field appearance="outline" class="filter"><mat-label>Vehicle</mat-label>
      <mat-select [(ngModel)]="vehicleId" (selectionChange)="load()"><mat-option [value]="null">All vehicles</mat-option><mat-option *ngFor="let v of vehicles" [value]="v.id">{{ v.name }}</mat-option></mat-select></mat-form-field>
  </div>

  <div class="layout">
    <div class="list">
      <div class="loading" *ngIf="loading"><mat-spinner diameter="28"></mat-spinner></div>
      <div class="empty" *ngIf="!loading && trips.length === 0">No trips yet.</div>
      <div class="trip" *ngFor="let t of trips" [class.sel]="selected?.id === t.id" (click)="open(t)">
        <mat-icon [class.run]="t.status === 'RUNNING'">{{ t.status === 'RUNNING' ? 'play_circle' : 'flag' }}</mat-icon>
        <div class="info">
          <strong>{{ vname(t.vehicleId) }}</strong>
          <small>{{ dname(t.driverId) }}</small>
          <small>{{ fmt(t.startedAt) }} &rarr; {{ t.status === 'RUNNING' ? 'running' : fmt(t.endedAt) }}</small>
        </div>
        <div class="right">
          <span class="km" *ngIf="t.distanceKm != null">{{ t.distanceKm }} km</span>
          <span class="dur">{{ dur(t.startedAt, t.endedAt) }}</span>
        </div>
      </div>
    </div>
    <div class="detail">
      <div class="map-wrap"><div #map class="map"></div><div class="hint" *ngIf="!selected">Select a trip to see its trail</div></div>
      <div class="trip-meta" *ngIf="selected">
        <span><strong>{{ vname(selected.vehicleId) }}</strong> &middot; {{ dname(selected.driverId) }}</span>
        <span>{{ points.length }} GPS points</span>
        <span *ngIf="selected.distanceKm != null">{{ selected.distanceKm }} km</span>
        <span>{{ dur(selected.startedAt, selected.endedAt) }}</span>
        <span>Max {{ maxSpeed | number:'1.0-0' }} km/h</span>
      </div>
    </div>
  </div>
</div>`,
  styles: [`
    .head { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; margin-bottom: 10px; h2 { margin: 0; } .sub { margin: 4px 0 0; color: #6b7280; font-size: 13px; } .filter { width: 220px; } }
    .layout { display: grid; grid-template-columns: 380px 1fr; gap: 12px; height: calc(100vh - 150px); }
    .list { background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; overflow: auto; padding: 8px; }
    .trip { display: flex; align-items: center; gap: 10px; padding: 10px; border-radius: 12px; cursor: pointer; border: 1px solid transparent; mat-icon { color: #90a4ae; &.run { color: #2e7d32; } } }
    .trip:hover { background: #f5f8fc; } .trip.sel { border-color: #1565c0; background: #e8f0fe; }
    .info { flex: 1; min-width: 0; display: flex; flex-direction: column; small { color: #6b7280; font-size: 12px; } }
    .right { display: flex; flex-direction: column; align-items: flex-end; .km { font-weight: 700; color: #1565c0; } .dur { font-size: 12px; color: #6b7280; } }
    .detail { display: flex; flex-direction: column; gap: 8px; min-height: 0; }
    .map-wrap { position: relative; flex: 1; border-radius: 14px; overflow: hidden; background: #e8eef5; min-height: 320px; }
    .map { width: 100%; height: 100%; }
    .hint { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; color: #6b7280; pointer-events: none; }
    .trip-meta { display: flex; flex-wrap: wrap; gap: 14px; background: #fff; border: 1px solid #e5e7eb; border-radius: 12px; padding: 10px 14px; font-size: 13px; }
    .loading { display: flex; justify-content: center; padding: 30px; }
    .empty { padding: 30px; text-align: center; color: #9ca3af; }
    @media (max-width: 900px) { .layout { grid-template-columns: 1fr; height: auto; } .list { max-height: 40vh; } .map-wrap { height: 45vh; } }
  `]
})
export class TransportTripsComponent implements OnInit, AfterViewChecked, OnDestroy {
  @ViewChild('map') mapEl?: ElementRef<HTMLDivElement>;
  vehicles: TransportVehicle[] = [];
  drivers: TransportDriver[] = [];
  trips: any[] = [];
  vehicleId: number | null = null;
  loading = false;
  selected: any = null;
  points: any[] = [];
  maxSpeed = 0;
  private map: any;
  private line: any;
  private markers: any[] = [];
  private sub?: Subscription;

  constructor(private store: TransportStore, private svc: TransportOwnerService, private swal: SwalService) {}

  ngOnInit(): void {
    this.sub = this.store.data$.subscribe(d => { if (!d) return; this.vehicles = d.vehicles || []; this.drivers = d.drivers || []; });
    this.load();
  }
  ngOnDestroy(): void { this.sub?.unsubscribe(); }

  ngAfterViewChecked(): void {
    if (!this.map && this.mapEl && typeof google !== 'undefined' && google.maps) {
      this.map = new google.maps.Map(this.mapEl.nativeElement, { center: { lat: 12.4966, lng: 78.5729 }, zoom: 11, mapTypeControl: false, streetViewControl: false });
    }
  }

  load(): void {
    this.loading = true;
    this.svc.trips(this.vehicleId || undefined).subscribe({
      next: (d: any) => { this.loading = false; this.trips = (d && d.content) ? d.content : (Array.isArray(d) ? d : []); },
      error: () => { this.loading = false; }
    });
  }

  vname(id: number): string { return this.vehicles.find(v => v.id === id)?.name || `#${id}`; }
  dname(id: number): string { return this.drivers.find(d => d.id === id)?.name || ''; }
  fmt(iso: string): string { if (!iso) return '-'; const d = new Date(iso); return isNaN(d.getTime()) ? iso : d.toLocaleString('en-IN', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' }); }
  dur(a: string, b?: string): string {
    const s = new Date(a).getTime(), e = b ? new Date(b).getTime() : Date.now();
    if (isNaN(s) || isNaN(e)) return '';
    const m = Math.max(0, Math.round((e - s) / 60000));
    return m < 60 ? `${m} min` : `${Math.floor(m / 60)} h ${m % 60} min`;
  }

  open(t: any): void {
    this.selected = t;
    this.svc.tripTrail(t.id).subscribe({
      next: (d: any) => {
        this.points = d?.points || [];
        this.maxSpeed = this.points.reduce((m: number, p: any) => Math.max(m, +(p.speedKmh || 0)), 0);
        this.draw();
      },
      error: (e) => this.swal.error('Could not load trail', e?.error?.message || '')
    });
  }

  private draw(): void {
    if (!this.map) return;
    if (this.line) this.line.setMap(null);
    this.markers.forEach(m => m.setMap(null)); this.markers = [];
    const pts = this.points.map(p => ({ lat: +p.lat, lng: +p.lng }));
    if (pts.length === 0) return;
    this.line = new google.maps.Polyline({ path: pts, strokeColor: '#1565c0', strokeWeight: 4, strokeOpacity: .9, map: this.map });
    this.markers.push(new google.maps.Marker({ position: pts[0], map: this.map, label: 'S', title: 'Start' }));
    if (pts.length > 1) this.markers.push(new google.maps.Marker({ position: pts[pts.length - 1], map: this.map, label: 'E', title: 'End' }));
    const b = new google.maps.LatLngBounds(); pts.forEach(p => b.extend(p));
    pts.length === 1 ? (this.map.setCenter(pts[0]), this.map.setZoom(14)) : this.map.fitBounds(b, 40);
  }
}
