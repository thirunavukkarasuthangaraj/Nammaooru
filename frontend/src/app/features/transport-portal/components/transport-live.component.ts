import { AfterViewInit, Component, ElementRef, NgZone, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { Subscription } from 'rxjs';
import { TransportPosition, TransportVehicle, routePath, routeColor } from '../../../core/services/transport-owner.service';
import { TransportStore } from '../transport-store.service';
import { roadPath, drawRouteLine, busIcon, ghostBusIcon, animateMarker, stateColor, currentLeg, nextDeparture, legProgress, pointAlong, progressAlong, dirLabel, LL, h12 } from '../map-utils';

declare var google: any;

function minOfSafe(t: string): number { const [h, m] = (t || '0:0').split(':').map(Number); return h * 60 + m; }

@Component({
  selector: 'app-transport-live',
  template: `
<div class="live">
  <div class="map-wrap">
    <div #map class="map"></div>
    <div class="map-tools">
      <button mat-mini-fab color="primary" (click)="fitAll()" title="Fit all vehicles"><mat-icon>fit_screen</mat-icon></button>
      <button mat-mini-fab [color]="follow ? 'accent' : undefined" (click)="follow = !follow" title="Follow selected"><mat-icon>gps_fixed</mat-icon></button>
      <button mat-mini-fab [color]="showTrails ? 'accent' : undefined" (click)="toggleTrails()" title="Show movement trails"><mat-icon>timeline</mat-icon></button>
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
          <small *ngIf="pos(v) as p; else nosig">{{ (p.speedKmh || 0) | number:'1.0-0' }} km/h &middot; {{ ago(p) }} <span class="late" *ngIf="lateText(v) as lt">&middot; {{ lt }}</span></small>
          <ng-template #nosig><small>no signal yet</small></ng-template>
          <small class="tt" *ngIf="ttText(v) as t">{{ t }}</small>
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
    .tt { color: #1565c0 !important; font-weight: 600; }
    .late { color: #c62828; font-weight: 700; }
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
  private routeLine: any[] | null = null;
  private routeToken = 0;
  private routeMarkers: any[] = [];
  private allRouteLines = new Map<number, any[]>();
  private trails = new Map<number, { lat: number; lng: number }[]>();
  private trailLines = new Map<number, any>();
  private ghosts = new Map<number, any>();
  private roadPaths = new Map<number, LL[]>();
  private clock: any;
  showTrails = true;
  private sub?: Subscription;
  private mapsTimer: any;

  constructor(private store: TransportStore, private zone: NgZone) {}

  ngOnInit(): void {
    this.sub = this.store.data$.subscribe(d => {
      if (!d) return;
      this.vehicles = d.vehicles || [];
      this.render();
    });
    this.clock = setInterval(() => this.renderGhosts(), 15000);
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

  ngOnDestroy(): void { this.sub?.unsubscribe(); clearTimeout(this.mapsTimer); clearInterval(this.clock); }

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
  schedulesOf(v: TransportVehicle) { return (this.store.snapshot?.schedules || []).filter(s => s.vehicleId === v.id); }
  routeOf(v: TransportVehicle) { return this.store.snapshot?.routes?.find(r => r.id === v.routeId) || null; }
  /** Timetable line for the list: current leg or next departure. */
  ttText(v: TransportVehicle): string | null {
    const rows = this.schedulesOf(v); if (!rows.length) return null;
    const leg = currentLeg(rows);
    if (leg) return `Scheduled ${h12(leg.departTime)}-${h12(leg.arriveTime)} ${dirLabel(this.routeOf(v), leg.direction)}`;
    const nx = nextDeparture(rows); return nx ? `Next ${h12(nx.departTime)} ${dirLabel(this.routeOf(v), nx.direction)}` : null;
  }
  /** Live bus vs timetable: minutes late/early along the road path. */
  lateText(v: TransportVehicle): string | null {
    const p = this.pos(v); const rows = this.schedulesOf(v); const leg = currentLeg(rows);
    const path = v.routeId != null ? this.roadPaths.get(v.routeId) : null;
    if (!p || !leg || !path || this.stateOf(v) === 'OFFLINE') return null;
    const dirPath = leg.direction === 'BA' ? [...path].reverse() : path;
    const actual = progressAlong(dirPath, { lat: +p.lat, lng: +p.lng });
    const planned = legProgress(leg);
    const legMin = Math.max(1, (minOfSafe(leg.arriveTime) - minOfSafe(leg.departTime)));
    const diff = Math.round((planned - actual) * legMin);
    if (Math.abs(diff) <= 3) return 'on time';
    return diff > 0 ? `${diff} min late` : `${-diff} min early`;
  }
  /** Timetable "should be here" markers for vehicles without a live position. */
  private renderGhosts(): void {
    if (!this.map) return;
    const seen = new Set<number>();
    for (const v of this.vehicles) {
      const path = v.routeId != null ? this.roadPaths.get(v.routeId) : null;
      const leg = currentLeg(this.schedulesOf(v));
      const live = this.pos(v) && this.stateOf(v) !== 'OFFLINE';
      if (!path || !leg || live) continue;
      const dirPath = leg.direction === 'BA' ? [...path].reverse() : path;
      const at = pointAlong(dirPath, legProgress(leg)); if (!at) continue;
      seen.add(v.id!);
      const icon = ghostBusIcon('#546e7a', at.heading, `${v.name} (timetable)`);
      let g = this.ghosts.get(v.id!);
      if (!g) {
        g = new google.maps.Marker({ position: at.pos, map: this.map, icon, title: `${v.name} (scheduled)`, zIndex: 8 });
        g.addListener('click', () => this.zone.run(() => this.select(v)));
        this.ghosts.set(v.id!, g);
      } else { animateMarker(g, at.pos, 1500); g.setIcon(icon); }
    }
    for (const [id, g] of this.ghosts) if (!seen.has(id)) { g.setMap(null); this.ghosts.delete(id); }
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
    if (this.routeLine) { this.routeLine.forEach((l: any) => l.setMap(null)); this.routeLine = null; }
    this.routeMarkers.forEach(m => m.setMap(null)); this.routeMarkers = [];
    const r = this.store.snapshot?.routes?.find(x => x.id === v.routeId);
    if (!r) return;
    const color = routeColor(r.id);
    const token = (this.routeToken = (this.routeToken || 0) + 1);
    roadPath(r).then(path => {
      if (token !== this.routeToken || !this.map) return;
      this.roadPaths.set(r.id!, path);
      this.routeLine = drawRouteLine(this.map, path, color, true);
      this.renderGhosts();
    });
    routePath(r).forEach((p, i) => {
      const isEnd = p.kind !== 'stop';
      this.routeMarkers.push(new google.maps.Marker({
        position: { lat: p.lat, lng: p.lng }, map: this.map, title: p.label,
        label: isEnd ? { text: p.kind === 'from' ? 'A' : 'B', color: '#fff', fontWeight: '800' } : { text: String(i), color: color, fontSize: '11px', fontWeight: '800' },
        icon: isEnd ? undefined : { path: google.maps.SymbolPath.CIRCLE, scale: 10, fillColor: '#fff', fillOpacity: 1, strokeColor: color, strokeWeight: 3 },
        zIndex: isEnd ? 6 : 5,
      }));
    });
  }

  toggleTrails(): void {
    this.showTrails = !this.showTrails;
    this.trailLines.forEach(l => l.setMap(this.showTrails ? this.map : null));
  }

  /** Keep the last ~200 distinct points per vehicle and draw them as its movement trail. */
  private pushTrail(id: number, lat: number, lng: number, moving: boolean): void {
    const t = this.trails.get(id) || [];
    const last = t[t.length - 1];
    if (!last || Math.abs(last.lat - lat) > 0.00002 || Math.abs(last.lng - lng) > 0.00002) {
      t.push({ lat, lng });
      if (t.length > 200) t.splice(0, t.length - 200);
      this.trails.set(id, t);
    }
    if (!this.map || t.length < 2) return;
    let line = this.trailLines.get(id);
    if (!line) {
      line = new google.maps.Polyline({ path: t, strokeColor: moving ? '#2e7d32' : '#78909c', strokeOpacity: .8, strokeWeight: 3, map: this.showTrails ? this.map : null });
      this.trailLines.set(id, line);
    } else {
      line.setPath(t);
      line.setOptions({ strokeColor: moving ? '#2e7d32' : '#78909c' });
    }
  }

  /** Every route assigned to a vehicle, drawn along the roads with a white outline so it stands out. */
  private drawAllRoutes(): void {
    if (!this.map) return;
    const routes = this.store.snapshot?.routes || [];
    const used = new Set<number>(this.vehicles.map(v => v.routeId!).filter(id => id != null));
    for (const [id, lines] of this.allRouteLines) { if (!used.has(id)) { lines.forEach(l => l.setMap(null)); this.allRouteLines.delete(id); } }
    for (const id of used) {
      if (this.allRouteLines.has(id)) continue;
      const r = routes.find(x => x.id === id);
      if (!r) continue;
      this.allRouteLines.set(id, []); // placeholder so we request once
      roadPath(r).then(path => {
        if (!this.map || !this.allRouteLines.has(id)) return;
        this.roadPaths.set(id, path);
        this.allRouteLines.set(id, drawRouteLine(this.map, path, routeColor(id), false));
        this.renderGhosts();
        if (this.markers.size === 0) this.fitAll();
      });
    }
  }

  private render(): void {
    if (!this.map) return;
    this.drawAllRoutes();
    const seen = new Set<number>();
    for (const v of this.vehicles) {
      const p = this.pos(v);
      if (!p || p.lat == null) continue;
      seen.add(v.id!);
      const st = this.stateOf(v);
      const icon = busIcon(stateColor(st), +(p.heading || 0), v.name);
      const ll = { lat: +p.lat, lng: +p.lng };
      this.pushTrail(v.id!, ll.lat, ll.lng, st === 'MOVING');
      let m = this.markers.get(v.id!);
      if (!m) {
        m = new google.maps.Marker({ position: ll, map: this.map, icon, title: v.name, zIndex: 10 });
        m.addListener('click', () => this.zone.run(() => this.select(v)));
        this.markers.set(v.id!, m);
      } else {
        animateMarker(m, ll); m.setIcon(icon);
      }
      if (this.follow && this.selected === v.id) this.map.panTo(ll);
    }
    for (const [id, m] of this.markers) { if (!seen.has(id)) { m.setMap(null); this.markers.delete(id); } }
    this.renderGhosts();
    for (const [id, l] of this.trailLines) { if (!seen.has(id)) { l.setMap(null); this.trailLines.delete(id); this.trails.delete(id); } }
  }

  fitAll(): void {
    if (!this.map) return;
    const b = new google.maps.LatLngBounds();
    this.markers.forEach(m => b.extend(m.getPosition()));
    this.ghosts.forEach(m => b.extend(m.getPosition()));
    if (this.markers.size === 0 && this.ghosts.size === 0) { this.allRouteLines.forEach(ls => ls.forEach(l => l.getPath().forEach((p: any) => b.extend(p)))); if (b.isEmpty()) return; this.map.fitBounds(b, 60); return; }
    if (this.markers.size === 1) { this.map.setCenter(b.getCenter()); this.map.setZoom(14); }
    else this.map.fitBounds(b, 60);
  }
}
