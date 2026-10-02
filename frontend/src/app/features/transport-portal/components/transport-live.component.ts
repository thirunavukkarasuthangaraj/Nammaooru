import { AfterViewInit, Component, ElementRef, NgZone, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { Subscription } from 'rxjs';
import { TransportPosition, TransportVehicle } from '../../../core/services/transport-owner.service';
import { TransportStore } from '../transport-store.service';

declare var google: any;

@Component({
  selector: 'app-transport-live',
  template: `
<div class="live">
  <div class="map-wrap">
    <div #map class="map"></div>
    <div class="map-tools">
      <button mat-mini-fab color="primary" (click)="fitAll()" title="Fit all vehicles"><mat-icon>fit_screen</mat-icon></button>
      <button mat-mini-fab [color]="follow ? 'accent' : undefined" (click)="follow = !follow" title="Follow selected"><mat-icon>gps_fixed</mat-icon></button>
    </div>
    <div class="no-maps" *ngIf="!mapsReady">Loading Google Maps...</div>
  </div>
  <aside class="side">
    <div class="side-head">
      <mat-form-field appearance="outline" class="search">
        <mat-label>Search vehicle</mat-label>
        <input matInput [(ngModel)]="q" placeholder="Name, reg no, driver">
        <mat-icon matSuffix>search</mat-icon>
      </mat-form-field>
    </div>
    <div class="list">
      <div class="empty" *ngIf="vehicles.length === 0">No vehicles yet. Add them under Vehicles.</div>
      <div class="row" *ngFor="let v of filtered()" [class.sel]="selected === v.id" (click)="select(v)">
        <mat-icon [class]="'ico ' + stateOf(v).toLowerCase()">{{ icon(v.vehicleType) }}</mat-icon>
        <div class="info">
          <strong>{{ v.name }}</strong>
          <small>{{ v.regNo }} <ng-container *ngIf="v.driverName">&middot; {{ v.driverName }}</ng-container></small>
          <small *ngIf="pos(v) as p; else nosig">{{ (p.speedKmh || 0) | number:'1.0-0' }} km/h &middot; {{ ago(p) }}</small>
          <ng-template #nosig><small>no signal yet</small></ng-template>
        </div>
        <span [class]="'chip ' + stateOf(v).toLowerCase()">{{ stateOf(v) }}</span>
      </div>
    </div>
  </aside>
</div>`,
  styles: [`
    .live { display: grid; grid-template-columns: 1fr 340px; gap: 12px; height: calc(100vh - 90px); }
    .map-wrap { position: relative; border-radius: 14px; overflow: hidden; background: #e8eef5; min-height: 320px; }
    .map { width: 100%; height: 100%; }
    .map-tools { position: absolute; right: 12px; bottom: 24px; display: flex; flex-direction: column; gap: 8px; }
    .no-maps { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; color: #6b7280; }
    .side { background: #fff; border-radius: 14px; border: 1px solid #e5e7eb; display: flex; flex-direction: column; min-height: 0; }
    .side-head { padding: 12px 12px 0; }
    .search { width: 100%; }
    .list { overflow: auto; padding: 0 8px 8px; }
    .row { display: flex; align-items: center; gap: 10px; padding: 10px; border-radius: 12px; cursor: pointer; border: 1px solid transparent; }
    .row:hover { background: #f5f8fc; }
    .row.sel { border-color: #1565c0; background: #e8f0fe; }
    .ico { font-size: 28px; width: 28px; height: 28px; &.moving { color: #2e7d32; } &.stopped { color: #1565c0; } &.offline { color: #90a4ae; } }
    .info { flex: 1; min-width: 0; display: flex; flex-direction: column; small { color: #6b7280; font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; } }
    .chip { font-size: 10.5px; font-weight: 700; padding: 3px 8px; border-radius: 999px; &.moving { background: #e8f5e9; color: #2e7d32; } &.stopped { background: #e3f2fd; color: #1565c0; } &.offline { background: #eceff1; color: #546e7a; } }
    .empty { padding: 24px; text-align: center; color: #9ca3af; }
    @media (max-width: 900px) { .live { grid-template-columns: 1fr; height: auto; } .map-wrap { height: 50vh; } .list { max-height: 50vh; } }
  `]
})
export class TransportLiveComponent implements OnInit, AfterViewInit, OnDestroy {
  @ViewChild('map') mapEl!: ElementRef<HTMLDivElement>;
  vehicles: TransportVehicle[] = [];
  q = '';
  selected: number | null = null;
  follow = true;
  mapsReady = false;
  private map: any;
  private markers = new Map<number, any>();
  private routeLine: any;
  private sub?: Subscription;
  private mapsTimer: any;

  constructor(private store: TransportStore, private zone: NgZone) {}

  ngOnInit(): void {
    this.sub = this.store.data$.subscribe(d => {
      if (!d) return;
      this.vehicles = d.vehicles || [];
      this.render();
    });
  }

  ngAfterViewInit(): void {
    const tryInit = () => {
      if (typeof google !== 'undefined' && google.maps) {
        this.map = new google.maps.Map(this.mapEl.nativeElement, {
          center: { lat: 12.4966, lng: 78.5729 }, zoom: 11, mapTypeControl: false, streetViewControl: false, fullscreenControl: true,
        });
        this.mapsReady = true;
        this.render();
        setTimeout(() => this.fitAll(), 600);
      } else {
        this.mapsTimer = setTimeout(tryInit, 400);
      }
    };
    tryInit();
  }

  ngOnDestroy(): void { this.sub?.unsubscribe(); clearTimeout(this.mapsTimer); }

  filtered(): TransportVehicle[] {
    const q = this.q.trim().toLowerCase();
    if (!q) return this.vehicles;
    return this.vehicles.filter(v => `${v.name} ${v.regNo} ${v.driverName || ''} ${v.routeName || ''}`.toLowerCase().includes(q));
  }

  stateOf(v: TransportVehicle) { return this.store.stateOf(v.id!); }
  pos(v: TransportVehicle): TransportPosition | undefined { return this.store.positionOf(v.id!); }
  ago(p: TransportPosition): string {
    const s = p.ageSec ?? 0;
    if (s < 5) return 'just now';
    if (s < 60) return `${s}s ago`;
    if (s < 3600) return `${Math.round(s / 60)} min ago`;
    return `${Math.round(s / 3600)} h ago`;
  }
  icon(t: string): string {
    return ({ BUS: 'directions_bus', LORRY: 'local_shipping', VAN: 'airport_shuttle', AUTO: 'electric_rickshaw', CAR: 'directions_car', BIKE: 'two_wheeler', TRACTOR: 'agriculture' } as any)[t] || 'commute';
  }

  select(v: TransportVehicle): void {
    this.selected = v.id!;
    this.follow = true;
    const p = this.pos(v);
    if (p && this.map) { this.map.panTo({ lat: +p.lat, lng: +p.lng }); if (this.map.getZoom() < 14) this.map.setZoom(14); }
    this.drawRoute(v);
  }

  private drawRoute(v: TransportVehicle): void {
    if (!this.map) return;
    if (this.routeLine) { this.routeLine.setMap(null); this.routeLine = null; }
    const r = this.store.snapshot?.routes?.find(x => x.id === v.routeId);
    const pts = (r?.stops || []).filter(s => s.lat != null && s.lng != null).map(s => ({ lat: +s.lat!, lng: +s.lng! }));
    if (pts.length > 1) {
      this.routeLine = new google.maps.Polyline({ path: pts, strokeColor: '#1565c0', strokeOpacity: .5, strokeWeight: 3, map: this.map,
        icons: [{ icon: { path: 'M 0,-1 0,1', strokeOpacity: 1, scale: 3 }, offset: '0', repeat: '16px' }] } as any);
    }
  }

  private render(): void {
    if (!this.map) return;
    const seen = new Set<number>();
    for (const v of this.vehicles) {
      const p = this.pos(v);
      if (!p || p.lat == null) continue;
      seen.add(v.id!);
      const st = this.stateOf(v);
      const color = st === 'MOVING' ? '#2e7d32' : st === 'STOPPED' ? '#1565c0' : '#78909c';
      const icon = { path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW, scale: 6, fillColor: color, fillOpacity: 1, strokeColor: '#fff', strokeWeight: 2, rotation: +(p.heading || 0) };
      const ll = { lat: +p.lat, lng: +p.lng };
      let m = this.markers.get(v.id!);
      if (!m) {
        m = new google.maps.Marker({ position: ll, map: this.map, icon, title: v.name, label: { text: v.name, color: '#1a237e', fontSize: '11px', fontWeight: '700' } as any });
        m.addListener('click', () => this.zone.run(() => this.select(v)));
        this.markers.set(v.id!, m);
      } else {
        m.setPosition(ll); m.setIcon(icon);
      }
      if (this.follow && this.selected === v.id) this.map.panTo(ll);
    }
    for (const [id, m] of this.markers) { if (!seen.has(id)) { m.setMap(null); this.markers.delete(id); } }
  }

  fitAll(): void {
    if (!this.map || this.markers.size === 0) return;
    const b = new google.maps.LatLngBounds();
    this.markers.forEach(m => b.extend(m.getPosition()));
    if (this.markers.size === 1) { this.map.setCenter(b.getCenter()); this.map.setZoom(14); }
    else this.map.fitBounds(b, 60);
  }
}
