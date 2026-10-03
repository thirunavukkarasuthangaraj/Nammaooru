import { AfterViewInit, Component, ElementRef, NgZone, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Subscription, interval } from 'rxjs';
import { environment } from '../../../../environments/environment';
import { AuthService } from '../../../core/services/auth.service';
import { MapsLoaderService } from '../../../core/services/maps-loader.service';
import { TransportOwnerService, routePath } from '../../../core/services/transport-owner.service';

declare var google: any;

interface PublicBus { id: number; name: string; regNo: string; operator: string; route: any; }
interface Pos { vehicleId: number; lat: number; lng: number; speedKmh?: number; heading?: number; ageSec: number; state: string; }

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
  private routeLine: any;
  private routeMarkers: any[] = [];
  private subs: Subscription[] = [];

  constructor(private http: HttpClient, private mapsLoader: MapsLoaderService, private router: Router,
              private auth: AuthService, private owner: TransportOwnerService, private zone: NgZone) {}

  ngOnInit(): void {
    this.load();
    this.subs.push(interval(5000).subscribe(() => this.refresh()));
  }

  ngAfterViewInit(): void {
    this.mapsLoader.load().then(ok => {
      if (!ok) { this.mapsMsg = 'Map is not configured yet. The bus list still works.'; return; }
      this.map = new google.maps.Map(this.mapEl.nativeElement, { center: { lat: 12.4966, lng: 78.5729 }, zoom: 11, mapTypeControl: false, streetViewControl: false });
      this.mapsReady = true;
      this.render(true);
    });
  }

  ngOnDestroy(): void { this.subs.forEach(s => s.unsubscribe()); }

  private load(): void {
    this.http.get<any>(`${environment.apiUrl}/transport/public/buses`, { params: { silentError: '1' } }).subscribe({
      next: r => {
        const d = r?.data || {};
        this.buses = d.buses || [];
        this.staleAfter = d.settings?.staleAfterSec || 120;
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
  ago(p: Pos): string { const s = p.ageSec ?? 0; return s < 5 ? 'just now' : s < 60 ? `${s}s ago` : s < 3600 ? `${Math.round(s / 60)} min ago` : `${Math.round(s / 3600)} h ago`; }
  stops(): any[] { return (this.selBus?.route?.stops || []).filter((s: any) => s.lat != null && s.lng != null); }
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
    if (!p) this.fitRoute();
  }

  scrollTo(id: string): void { document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' }); }

  private drawRoute(b: PublicBus): void {
    if (!this.map) return;
    if (this.routeLine) { this.routeLine.setMap(null); this.routeLine = null; }
    this.routeMarkers.forEach(m => m.setMap(null)); this.routeMarkers = [];
    const path = routePath(b.route);
    if (path.length > 1) this.routeLine = new google.maps.Polyline({ path, strokeColor: '#1565c0', strokeOpacity: .55, strokeWeight: 4, map: this.map });
    path.forEach((p, i) => this.routeMarkers.push(new google.maps.Marker({
      position: { lat: p.lat, lng: p.lng }, map: this.map, title: p.label,
      label: p.kind === 'stop' ? { text: String(i), color: '#1a237e', fontSize: '10px', fontWeight: '700' } : { text: p.kind === 'from' ? 'A' : 'B', color: '#fff', fontWeight: '700' },
      icon: p.kind === 'stop' ? { path: google.maps.SymbolPath.CIRCLE, scale: 7, fillColor: '#fff', fillOpacity: 1, strokeColor: '#1565c0', strokeWeight: 2 } : undefined,
    })));
  }
  private fitRoute(): void {
    if (!this.map || !this.routeLine) return;
    const b = new google.maps.LatLngBounds(); this.routeLine.getPath().forEach((p: any) => b.extend(p)); this.map.fitBounds(b, 40);
  }

  private render(fit: boolean): void {
    if (!this.map) return;
    const seen = new Set<number>();
    for (const b of this.buses) {
      const p = this.positions.get(b.id);
      if (!p) continue;
      seen.add(b.id);
      const st = this.stateOf(b.id);
      const color = st === 'MOVING' ? '#2e7d32' : st === 'STOPPED' ? '#1565c0' : '#78909c';
      const icon = { path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW, scale: 6, fillColor: color, fillOpacity: 1, strokeColor: '#fff', strokeWeight: 2, rotation: +(p.heading || 0) };
      const ll = { lat: +p.lat, lng: +p.lng };
      let m = this.markers.get(b.id);
      if (!m) {
        m = new google.maps.Marker({ position: ll, map: this.map, icon, title: b.name, label: { text: b.name, color: '#1a237e', fontSize: '11px', fontWeight: '700' } });
        m.addListener('click', () => this.zone.run(() => this.select(b)));
        this.markers.set(b.id, m);
      } else { m.setPosition(ll); m.setIcon(icon); }
      if (this.selected === b.id) this.map.panTo(ll);
    }
    for (const [id, m] of this.markers) if (!seen.has(id)) { m.setMap(null); this.markers.delete(id); }
    if (fit && this.markers.size > 0) {
      const bb = new google.maps.LatLngBounds(); this.markers.forEach(m => bb.extend(m.getPosition()));
      this.markers.size === 1 ? (this.map.setCenter(bb.getCenter()), this.map.setZoom(13)) : this.map.fitBounds(bb, 60);
    }
  }
}
