import { AfterViewInit, Component, ElementRef, NgZone, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Subscription, interval } from 'rxjs';
import { environment } from '../../../../environments/environment';
import { AuthService } from '../../../core/services/auth.service';
import { MapsLoaderService } from '../../../core/services/maps-loader.service';
import { TransportOwnerService, routePath, routeColor } from '../../../core/services/transport-owner.service';
import { roadPath, drawRouteLine, busIcon, ghostBusIcon, animateMarker, stateColor, currentLeg, nextDeparture, legProgress, pointAlong, dirLabel, LL, h12 } from '../map-utils';

declare var google: any;

interface PublicBus { id: number; name: string; regNo: string; operator: string; route: any; schedules?: any[]; }
interface Pos { vehicleId: number; lat: number; lng: number; speedKmh?: number; heading?: number; ageSec: number; state: string; direction?: string; }

/**
 * Public transport home: what the service is, live public buses on a map,
 * and the doors in for owners and drivers. No login needed.
 */
@Component({
  selector: 'app-transport-home',
  template: `
<div class="th">
  <header class="hero">
    <div class="hero-in">
      <div class="brand"><mat-icon>directions_bus</mat-icon><span>Nammaooru Transport</span></div>
      <h1>Where is my bus?</h1>
      <p>See your bus moving live on the map, pick your stop and know roughly when it arrives. A free service for everyone in our town. Bus and lorry owners can track their own fleet too.</p>
      <div class="cta">
        <a mat-raised-button color="accent" (click)="scrollTo('live')"><mat-icon>my_location</mat-icon> See live buses</a>
        <a mat-stroked-button routerLink="/transport/login"><mat-icon>login</mat-icon> Fleet owner login</a>
      </div>
      <div class="stats">
        <div><strong>{{ buses.length }}</strong><span>public buses</span></div>
        <div><strong>{{ moving }}</strong><span>moving now</span></div>
        <div><strong>{{ operators }}</strong><span>operators</span></div>
      </div>
    </div>
  </header>

  <section class="how">
    <div class="card"><mat-icon>phone_android</mat-icon><h3>For passengers</h3><p>Open the Nammaooru app, tap <b>Where is Bus</b>, choose your bus and your stop. Arrival time updates every few seconds.</p></div>
    <div class="card"><mat-icon>dashboard_customize</mat-icon><h3>For bus & lorry owners</h3><p>Register from the app or ask the admin. Add any vehicle type, drivers and routes. Watch the whole fleet live here on the website, with trip history and trails.</p></div>
    <div class="card"><mat-icon>sports_motorsports</mat-icon><h3>For drivers</h3><p>Log into the app with the number your owner added, tap <b>Start Trip</b>. The phone shares location even with the screen locked.</p></div>
  </section>

  <section class="live" id="live">
    <div class="live-head">
      <h2>Live public buses</h2>
      <span class="dot" [class.on]="feedOk"></span>
      <mat-form-field appearance="outline" class="search"><mat-label>Find a bus or route</mat-label><input matInput [(ngModel)]="q"><mat-icon matSuffix>search</mat-icon></mat-form-field>
    </div>
    <div class="live-grid">
      <div class="map-wrap">
        <div #map class="map"></div>
        <div class="no-maps" *ngIf="!mapsReady">{{ mapsMsg }}</div>
      </div>
      <div class="list">
        <div class="empty" *ngIf="loaded && buses.length === 0">No buses are being tracked yet. Owners can add theirs from the app or the owner portal.</div>
        <div class="row" *ngFor="let b of filtered()" [class.sel]="selected === b.id" (click)="select(b)">
          <mat-icon [class]="'ico ' + stateOf(b.id).toLowerCase()">directions_bus</mat-icon>
          <div class="info">
            <strong>{{ b.name }}</strong>
            <small>{{ b.route ? (b.route.source + ' → ' + b.route.destination) : b.regNo }} · {{ b.operator }}</small>
            <small *ngIf="pos(b.id) as p">{{ (p.speedKmh || 0) | number:'1.0-0' }} km/h · {{ ago(p) }}</small>
            <small class="tt" *ngIf="ttText(b) as t">{{ t }}</small>
          </div>
          <span [class]="'chip ' + stateOf(b.id).toLowerCase()">{{ stateOf(b.id) }}</span>
        </div>
      </div>
    </div>
    <div class="detail" *ngIf="selected && selBus">
      <strong>{{ selBus.name }}</strong> · {{ selBus.operator }}
      <ng-container *ngIf="selBus.route"> · {{ selBus.route.source }} → {{ selBus.route.destination }}</ng-container>
      <ng-container *ngIf="stops().length">
        <mat-form-field appearance="outline" class="stop"><mat-label>My stop</mat-label>
          <mat-select [(ngModel)]="stopIdx"><mat-option *ngFor="let s of stops(); let i = index" [value]="i">{{ i + 1 }}. {{ s.name }}</mat-option></mat-select></mat-form-field>
        <span class="eta" *ngIf="eta() as e">🕒 {{ e }}</span>
      </ng-container>
    </div>
  </section>

  <footer class="foot">
    <span>Nammaooru · Local delivery & town services</span>
    <a routerLink="/transport/login">Owner login</a>
    <a routerLink="/auth/login">Admin</a>
  </footer>
</div>`,
  styles: [`
    .th { background: #f3f6fa; min-height: 100vh; font-family: inherit; }
    .hero { background: linear-gradient(135deg, #0d47a1, #1976d2 60%, #42a5f5); color: #fff; padding: 48px 16px 40px; }
    .hero-in { max-width: 1100px; margin: 0 auto; }
    .brand { display: flex; align-items: center; gap: 8px; opacity: .9; font-weight: 600; mat-icon { font-size: 28px; width: 28px; height: 28px; } }
    h1 { font-size: clamp(30px, 5vw, 48px); margin: 10px 0 8px; font-weight: 800; }
    .hero p { max-width: 640px; font-size: 16px; line-height: 1.5; opacity: .95; }
    .cta { display: flex; gap: 10px; flex-wrap: wrap; margin: 18px 0; a { height: 44px; display: inline-flex; align-items: center; gap: 6px; } a[mat-stroked-button] { color: #fff; border-color: rgba(255,255,255,.6); } }
    .stats { display: flex; gap: 22px; flex-wrap: wrap; div { display: flex; flex-direction: column; strong { font-size: 26px; font-weight: 800; } span { font-size: 12px; opacity: .85; } } }
    .how { max-width: 1100px; margin: -22px auto 0; padding: 0 16px; display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 12px; }
    .card { background: #fff; border-radius: 14px; padding: 18px; box-shadow: 0 10px 30px rgba(13,71,161,.08); mat-icon { color: #1565c0; font-size: 30px; width: 30px; height: 30px; } h3 { margin: 8px 0 4px; font-size: 16px; } p { margin: 0; color: #4b5563; font-size: 13.5px; line-height: 1.5; } }
    .live { max-width: 1100px; margin: 28px auto; padding: 0 16px; }
    .live-head { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; h2 { margin: 0; flex: 1; } .search { width: 280px; margin-bottom: -1.25em; } }
    .dot { width: 10px; height: 10px; border-radius: 50%; background: #cfd8dc; &.on { background: #2e7d32; box-shadow: 0 0 0 4px rgba(46,125,50,.2); } }
    .live-grid { display: grid; grid-template-columns: 1fr 340px; gap: 12px; margin-top: 12px; height: 480px; }
    .map-wrap { position: relative; border-radius: 14px; overflow: hidden; background: #e8eef5; }
    .map { width: 100%; height: 100%; }
    .no-maps { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; color: #6b7280; text-align: center; padding: 20px; }
    .list { background: #fff; border-radius: 14px; border: 1px solid #e5e7eb; overflow: auto; padding: 8px; }
    .row { display: flex; align-items: center; gap: 10px; padding: 10px; border-radius: 12px; cursor: pointer; border: 1px solid transparent; }
    .row:hover { background: #f5f8fc; } .row.sel { border-color: #1565c0; background: #e8f0fe; }
    .ico { font-size: 28px; width: 28px; height: 28px; &.moving { color: #2e7d32; } &.stopped { color: #1565c0; } &.offline { color: #90a4ae; } }
    .info { flex: 1; min-width: 0; display: flex; flex-direction: column; small { color: #6b7280; font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; } }
    .tt { color: #1565c0 !important; font-weight: 600; }
    .chip { font-size: 10.5px; font-weight: 700; padding: 3px 8px; border-radius: 999px; &.moving { background: #e8f5e9; color: #2e7d32; } &.stopped { background: #e3f2fd; color: #1565c0; } &.offline { background: #eceff1; color: #546e7a; } }
    .empty { padding: 24px; text-align: center; color: #9ca3af; }
    .detail { margin-top: 12px; background: #fff; border: 1px solid #e5e7eb; border-radius: 12px; padding: 10px 14px; display: flex; align-items: center; gap: 12px; flex-wrap: wrap; .stop { width: 260px; margin-bottom: -1.25em; } .eta { font-weight: 700; color: #1565c0; } }
    .foot { max-width: 1100px; margin: 0 auto; padding: 24px 16px 36px; display: flex; gap: 18px; color: #6b7280; font-size: 13px; a { color: #1565c0; } }
    @media (max-width: 900px) { .live-grid { grid-template-columns: 1fr; height: auto; } .map-wrap { height: 50vh; } .list { max-height: 45vh; } }
  `]
})
export class TransportHomeComponent implements OnInit, AfterViewInit, OnDestroy {
  @ViewChild('map') mapEl!: ElementRef<HTMLDivElement>;
  buses: PublicBus[] = [];
  positions = new Map<number, Pos>();
  staleAfter = 120;
  pollEvery = 5;
  private pollTick = 0;
  loaded = false;
  feedOk = false;
  mapsReady = false;
  mapsMsg = 'Loading map...';
  q = '';
  selected: number | null = null;
  selBus: PublicBus | null = null;
  stopIdx: number | null = null;
  moving = 0;
  operators = 0;
  private map: any;
  private markers = new Map<number, any>();
  private routeLine: any[] | null = null;
  private routeToken = 0;
  private routeMarkers: any[] = [];
  private allRouteLines = new Map<number, any[]>();
  private ghosts = new Map<number, any>();
  private roadPaths = new Map<number, LL[]>();
  private clock: any;
  private subs: Subscription[] = [];

  constructor(private http: HttpClient, private mapsLoader: MapsLoaderService, private router: Router,
              private auth: AuthService, private owner: TransportOwnerService, private zone: NgZone) {}

  ngOnInit(): void {
    this.load();
    this.subs.push(interval(1000).subscribe(() => { const every = Math.max(2, this.pollEvery); this.pollTick = (this.pollTick + 1) % every; if (this.pollTick === 0) this.refresh(); }));
    this.clock = setInterval(() => this.renderGhosts(), 15000);
  }

  ngAfterViewInit(): void {
    this.mapsLoader.load().then(ok => {
      if (!ok) { this.mapsMsg = 'Map is not configured yet. The bus list still works.'; return; }
      this.map = new google.maps.Map(this.mapEl.nativeElement, { center: { lat: 12.4966, lng: 78.5729 }, zoom: 11, mapTypeControl: false, streetViewControl: false });
      this.mapsReady = true;
      this.render(true);
    });
  }

  ngOnDestroy(): void { this.subs.forEach(s => s.unsubscribe()); clearInterval(this.clock); }

  private load(): void {
    this.http.get<any>(`${environment.apiUrl}/transport/public/buses`, { params: { silentError: '1' } }).subscribe({
      next: r => {
        const d = r?.data || {};
        this.buses = d.buses || [];
        this.staleAfter = d.settings?.staleAfterSec || 120;
        this.pollEvery = d.settings?.pollIntervalSec || 5;
        (d.positions || []).forEach((p: Pos) => this.positions.set(p.vehicleId, p));
        this.operators = new Set(this.buses.map(b => b.operator)).size;
        this.loaded = true; this.feedOk = true;
        this.recount(); this.render(true);
      },
      error: () => { this.loaded = true; this.feedOk = false; }
    });
  }

  private refresh(): void {
    if (this.buses.length === 0) { this.load(); return; }
    const ids = this.buses.map(b => b.id).join(',');
    this.http.get<any>(`${environment.apiUrl}/transport/public/positions`, { params: { ids, silentError: '1' } }).subscribe({
      next: r => { (r?.data || []).forEach((p: Pos) => this.positions.set(p.vehicleId, p)); this.feedOk = true; this.recount(); this.render(false); },
      error: () => { this.feedOk = false; }
    });
  }

  private recount(): void { this.moving = this.buses.filter(b => this.stateOf(b.id) === 'MOVING').length; }

  filtered(): PublicBus[] {
    const q = this.q.trim().toLowerCase();
    if (!q) return this.buses;
    return this.buses.filter(b => `${b.name} ${b.regNo} ${b.operator} ${b.route?.name || ''} ${b.route?.source || ''} ${b.route?.destination || ''}`.toLowerCase().includes(q));
  }
  pos(id: number): Pos | undefined { return this.positions.get(id); }
  stateOf(id: number): string {
    const p = this.positions.get(id);
    if (!p || (p.ageSec ?? 9999) > this.staleAfter) return 'OFFLINE';
    return p.state || 'STOPPED';
  }
  ttText(b: PublicBus): string | null {
    const rows = b.schedules || []; if (!rows.length) return null;
    const leg = currentLeg(rows);
    if (leg) return `Scheduled ${h12(leg.departTime)}-${h12(leg.arriveTime)} ${dirLabel(b.route, leg.direction)}`;
    const nx = nextDeparture(rows); return nx ? `Next ${h12(nx.departTime)} ${dirLabel(b.route, nx.direction)}` : null;
  }
  private renderGhosts(): void {
    if (!this.map) return;
    const seen = new Set<number>();
    for (const b of this.buses) {
      const path = b.route?.id != null ? this.roadPaths.get(b.route.id) : null;
      const leg = currentLeg(b.schedules || []);
      const live = this.positions.get(b.id) && this.stateOf(b.id) !== 'OFFLINE';
      if (!path || !leg || live) continue;
      const dirPath = leg.direction === 'BA' ? [...path].reverse() : path;
      const at = pointAlong(dirPath, legProgress(leg)); if (!at) continue;
      seen.add(b.id);
      const icon = ghostBusIcon('#546e7a', at.heading, `${b.name} (timetable)`);
      let g = this.ghosts.get(b.id);
      if (!g) {
        g = new google.maps.Marker({ position: at.pos, map: this.map, icon, title: `${b.name} (timetable)`, zIndex: 8 });
        g.addListener('click', () => this.zone.run(() => this.select(b)));
        this.ghosts.set(b.id, g);
      } else { animateMarker(g, at.pos, 1500); g.setIcon(icon); }
    }
    for (const [id, g] of this.ghosts) if (!seen.has(id)) { g.setMap(null); this.ghosts.delete(id); }
  }
  ago(p: Pos): string { const s = p.ageSec ?? 0; return s < 5 ? 'just now' : s < 60 ? `${s}s ago` : s < 3600 ? `${Math.round(s / 60)} min ago` : `${Math.round(s / 3600)} h ago`; }
  stops(): any[] {
    const list = (this.selBus?.route?.stops || []).filter((s: any) => s.lat != null && s.lng != null);
    const p = this.selected ? this.positions.get(this.selected) : null;
    const leg = currentLeg(this.selBus?.schedules || []);
    const dir = (p && p.direction) || (leg && leg.direction) || 'AB';
    return dir === 'BA' ? [...list].reverse() : list;
  }
  eta(): string | null {
    const p = this.selected ? this.positions.get(this.selected) : null;
    const st = this.stopIdx != null ? this.stops()[this.stopIdx] : null;
    if (!p || !st || this.stateOf(this.selected!) === 'OFFLINE') return st && p ? 'Bus is not sharing its location right now' : null;
    const km = this.haversine(+p.lat, +p.lng, +st.lat, +st.lng) * 1.3;
    const sp = Math.max(20, +(p.speedKmh || 0));
    const min = Math.max(1, Math.round(km / sp * 60));
    return `About ${min} min · ${km.toFixed(1)} km`;
  }
  private haversine(a: number, b: number, c: number, d: number): number {
    const R = 6371, dLat = (c - a) * Math.PI / 180, dLon = (d - b) * Math.PI / 180;
    const x = Math.sin(dLat / 2) ** 2 + Math.cos(a * Math.PI / 180) * Math.cos(c * Math.PI / 180) * Math.sin(dLon / 2) ** 2;
    return 2 * R * Math.asin(Math.sqrt(x));
  }

  select(b: PublicBus): void {
    this.selected = b.id; this.selBus = b; this.stopIdx = null;
    const p = this.positions.get(b.id);
    if (this.map && p) { this.map.panTo({ lat: +p.lat, lng: +p.lng }); if (this.map.getZoom() < 14) this.map.setZoom(14); }
    this.drawRoute(b);
  }

  scrollTo(id: string): void { document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' }); }

  private drawRoute(b: PublicBus): void {
    if (!this.map) return;
    if (this.routeLine) { this.routeLine.forEach((l: any) => l.setMap(null)); this.routeLine = null; }
    this.routeMarkers.forEach(m => m.setMap(null)); this.routeMarkers = [];
    if (!b.route) return;
    const color = routeColor(b.route.id);
    const token = (this.routeToken = this.routeToken + 1);
    roadPath(b.route).then(path => {
      if (token !== this.routeToken || !this.map) return;
      this.routeLine = drawRouteLine(this.map, path, color, true);
      if (!this.positions.get(b.id)) this.fitRoute();
    });
    routePath(b.route).forEach((p, i) => this.routeMarkers.push(new google.maps.Marker({
      position: { lat: p.lat, lng: p.lng }, map: this.map, title: p.label,
      label: p.kind === 'stop' ? { text: String(i), color: color, fontSize: '11px', fontWeight: '800' } : { text: p.kind === 'from' ? 'A' : 'B', color: '#fff', fontWeight: '800' },
      icon: p.kind === 'stop' ? { path: google.maps.SymbolPath.CIRCLE, scale: 10, fillColor: '#fff', fillOpacity: 1, strokeColor: color, strokeWeight: 3 } : undefined,
      zIndex: p.kind === 'stop' ? 5 : 6,
    })));
  }
  private fitRoute(): void {
    if (!this.map || !this.routeLine || !this.routeLine.length) return;
    const b = new google.maps.LatLngBounds(); this.routeLine[1].getPath().forEach((p: any) => b.extend(p)); this.map.fitBounds(b, 40);
  }

  private drawAllRoutes(): void {
    if (!this.map) return;
    for (const b of this.buses) {
      const r = b.route; if (!r || r.id == null || this.allRouteLines.has(r.id)) continue;
      this.allRouteLines.set(r.id, []);
      roadPath(r).then(path => {
        if (!this.map) return;
        this.roadPaths.set(r.id, path);
        this.allRouteLines.set(r.id, drawRouteLine(this.map, path, routeColor(r.id), false));
        this.renderGhosts();
        if (this.markers.size === 0) this.render(true);
      });
    }
  }

  private render(fit: boolean): void {
    if (!this.map) return;
    this.drawAllRoutes();
    const seen = new Set<number>();
    for (const b of this.buses) {
      const p = this.positions.get(b.id);
      if (!p) continue;
      seen.add(b.id);
      const st = this.stateOf(b.id);
      const icon = busIcon(stateColor(st), +(p.heading || 0), b.name);
      const ll = { lat: +p.lat, lng: +p.lng };
      let m = this.markers.get(b.id);
      if (!m) {
        m = new google.maps.Marker({ position: ll, map: this.map, icon, title: b.name, zIndex: 10 });
        m.addListener('click', () => this.zone.run(() => this.select(b)));
        this.markers.set(b.id, m);
      } else { animateMarker(m, ll); m.setIcon(icon); }
      if (this.selected === b.id) this.map.panTo(ll);
    }
    for (const [id, m] of this.markers) if (!seen.has(id)) { m.setMap(null); this.markers.delete(id); }
    this.renderGhosts();
    if (fit) {
      const bb = new google.maps.LatLngBounds();
      this.markers.forEach(m => bb.extend(m.getPosition()));
      this.ghosts.forEach(m => bb.extend(m.getPosition()));
      if (this.markers.size === 0 && this.ghosts.size === 0) this.allRouteLines.forEach(ls => ls.forEach(l => l.getPath().forEach((p: any) => bb.extend(p))));
      if (bb.isEmpty()) return;
      this.markers.size === 1 ? (this.map.setCenter(bb.getCenter()), this.map.setZoom(13)) : this.map.fitBounds(bb, 60);
    }
  }
}
