import { AfterViewChecked, Component, ElementRef, NgZone, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { Subscription } from 'rxjs';
import { SwalService } from '../../../core/services/swal.service';
import { TransportOwnerService, TransportRoute, TransportStop, routePath } from '../../../core/services/transport-owner.service';
import { TransportStore } from '../transport-store.service';

declare var google: any;

@Component({
  selector: 'app-transport-routes',
  template: `
<div class="page">
  <div class="head">
    <div><h2>Routes</h2><p class="sub">Optional. Add stops with coordinates so passengers can pick their stop and see the arrival time. Click on the map to place a stop.</p></div>
    <button mat-raised-button color="primary" (click)="startAdd()"><mat-icon>add_road</mat-icon> Add route</button>
  </div>

  <div class="form" *ngIf="editing">
    <h3>{{ editing.id ? 'Edit route' : 'Add route' }}</h3>
    <div class="grid3">
      <mat-form-field appearance="outline" class="span3"><mat-label>Route name</mat-label><input matInput [(ngModel)]="editing.name" placeholder="e.g. Route 7"></mat-form-field>
    </div>
    <div class="endpoint" [class.sel]="target === 'from'" (click)="target = 'from'">
      <span class="tag a">A</span>
      <mat-form-field appearance="outline" class="name"><mat-label>From *</mat-label><input matInput [(ngModel)]="editing.source"></mat-form-field>
      <mat-form-field appearance="outline" class="coord"><mat-label>Lat</mat-label><input matInput type="number" step="any" [(ngModel)]="editing.sourceLat" (ngModelChange)="drawStops()"></mat-form-field>
      <mat-form-field appearance="outline" class="coord"><mat-label>Lng</mat-label><input matInput type="number" step="any" [(ngModel)]="editing.sourceLng" (ngModelChange)="drawStops()"></mat-form-field>
      <span class="hintsel">{{ target === 'from' ? 'click map to place' : '' }}</span>
    </div>
    <div class="endpoint" [class.sel]="target === 'to'" (click)="target = 'to'">
      <span class="tag b">B</span>
      <mat-form-field appearance="outline" class="name"><mat-label>To *</mat-label><input matInput [(ngModel)]="editing.destination"></mat-form-field>
      <mat-form-field appearance="outline" class="coord"><mat-label>Lat</mat-label><input matInput type="number" step="any" [(ngModel)]="editing.destLat" (ngModelChange)="drawStops()"></mat-form-field>
      <mat-form-field appearance="outline" class="coord"><mat-label>Lng</mat-label><input matInput type="number" step="any" [(ngModel)]="editing.destLng" (ngModelChange)="drawStops()"></mat-form-field>
      <span class="hintsel">{{ target === 'to' ? 'click map to place' : '' }}</span>
    </div>
    <div class="editor">
      <div class="stops">
        <div class="stops-head"><strong>Stops (in order)</strong><button mat-button color="primary" (click)="addStop()"><mat-icon>add</mat-icon> Add stop</button></div>
        <div class="stop" *ngFor="let s of editing.stops; let i = index" [class.sel]="target === 'stop' && selStop === i" (click)="target = 'stop'; selStop = i">
          <span class="n">{{ i + 1 }}</span>
          <mat-form-field appearance="outline" class="name"><mat-label>Stop name</mat-label><input matInput [(ngModel)]="s.name"></mat-form-field>
          <mat-form-field appearance="outline" class="coord"><mat-label>Lat</mat-label><input matInput type="number" step="any" [(ngModel)]="s.lat" (ngModelChange)="drawStops()"></mat-form-field>
          <mat-form-field appearance="outline" class="coord"><mat-label>Lng</mat-label><input matInput type="number" step="any" [(ngModel)]="s.lng" (ngModelChange)="drawStops()"></mat-form-field>
          <button mat-icon-button (click)="moveStop(i, -1); $event.stopPropagation()" [disabled]="i === 0" title="Move up"><mat-icon>arrow_upward</mat-icon></button>
          <button mat-icon-button (click)="moveStop(i, 1); $event.stopPropagation()" [disabled]="i === editing.stops.length - 1" title="Move down"><mat-icon>arrow_downward</mat-icon></button>
          <button mat-icon-button color="warn" (click)="removeStop(i); $event.stopPropagation()" title="Remove"><mat-icon>close</mat-icon></button>
        </div>
        <p class="tip">Tip: select A (From), B (To) or a stop row, then click its location on the map. Drag any marker to adjust. The line is drawn A &rarr; stops &rarr; B.</p>
      </div>
      <div class="map-wrap"><div #map class="map"></div></div>
    </div>
    <div class="actions">
      <button mat-raised-button color="primary" [disabled]="saving" (click)="save()"><mat-icon>save</mat-icon> {{ saving ? 'Saving...' : 'Save route' }}</button>
      <button mat-button (click)="cancel()">Cancel</button>
    </div>
  </div>

  <div class="cards">
    <div class="empty" *ngIf="routes.length === 0 && !editing">No routes yet.</div>
    <div class="card" *ngFor="let r of routes">
      <div class="card-top"><mat-icon class="ico">alt_route</mat-icon><div class="t"><strong>{{ r.name }}</strong><small>{{ r.source }} &rarr; {{ r.destination }}</small></div></div>
      <div class="stoplist">
        <span [class.muted]="r.sourceLat == null">A: {{ r.source }}{{ r.sourceLat == null ? ' (no point)' : '' }}</span>
        <span *ngFor="let s of r.stops; let i = index" [class.muted]="s.lat == null">{{ i + 1 }}. {{ s.name }}{{ s.lat == null ? ' (no point)' : '' }}</span>
        <span [class.muted]="r.destLat == null">B: {{ r.destination }}{{ r.destLat == null ? ' (no point)' : '' }}</span>
      </div>
      <div class="card-actions">
        <button mat-button color="primary" (click)="edit(r)"><mat-icon>edit</mat-icon> Edit</button>
        <button mat-button color="warn" (click)="remove(r)"><mat-icon>delete</mat-icon> Remove</button>
      </div>
    </div>
  </div>
</div>`,
  styles: [`
    .head { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; margin-bottom: 14px; h2 { margin: 0; } .sub { margin: 4px 0 0; color: #6b7280; font-size: 13px; max-width: 720px; } }
    .form { background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; padding: 16px; margin-bottom: 16px; h3 { margin: 0 0 10px; } }
    .grid3 { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px; }
    .span3 { grid-column: 1 / -1; }
    .endpoint { display: flex; align-items: center; gap: 6px; padding: 6px; border-radius: 10px; border: 1px solid transparent; cursor: pointer; margin-bottom: 2px; .name { flex: 2; } .coord { flex: 1; } mat-form-field { margin-bottom: -1.25em; } }
    .endpoint.sel { border-color: #1565c0; background: #e8f0fe; }
    .tag { width: 24px; height: 24px; border-radius: 50%; color: #fff; font-weight: 800; font-size: 12px; display: inline-flex; align-items: center; justify-content: center; &.a { background: #2e7d32; } &.b { background: #c62828; } }
    .hintsel { font-size: 11px; color: #1565c0; min-width: 90px; }
    .editor { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
    .stops-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
    .stop { display: flex; align-items: center; gap: 6px; padding: 6px; border-radius: 10px; border: 1px solid transparent; cursor: pointer; .n { width: 22px; font-weight: 700; color: #1565c0; } .name { flex: 2; } .coord { flex: 1; } }
    .stop.sel { border-color: #1565c0; background: #e8f0fe; }
    .stop mat-form-field { margin-bottom: -1.25em; }
    .tip { color: #6b7280; font-size: 12px; margin: 8px 0 0; }
    .map-wrap { border-radius: 12px; overflow: hidden; min-height: 360px; background: #e8eef5; }
    .map { width: 100%; height: 100%; min-height: 360px; }
    .actions { display: flex; gap: 8px; margin-top: 12px; }
    .cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 12px; }
    .card { background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; padding: 14px; display: flex; flex-direction: column; gap: 8px; }
    .card-top { display: flex; align-items: center; gap: 10px; .ico { color: #2e7d32; font-size: 28px; width: 28px; height: 28px; } .t { display: flex; flex-direction: column; small { color: #6b7280; font-size: 12px; } } }
    .stoplist { display: flex; flex-wrap: wrap; gap: 6px; font-size: 12px; span { background: #f3f4f6; border-radius: 999px; padding: 2px 8px; } .muted { color: #9ca3af; } }
    .card-actions { display: flex; gap: 4px; margin-top: auto; }
    .empty { grid-column: 1 / -1; padding: 30px; text-align: center; color: #9ca3af; }
    @media (max-width: 900px) { .editor { grid-template-columns: 1fr; } }
  `]
})
export class TransportRoutesComponent implements OnInit, AfterViewChecked, OnDestroy {
  @ViewChild('map') mapEl?: ElementRef<HTMLDivElement>;
  routes: TransportRoute[] = [];
  editing: TransportRoute | null = null;
  selStop: number | null = null;
  target: 'from' | 'to' | 'stop' = 'stop';
  saving = false;
  private map: any;
  private markers: any[] = [];
  private line: any;
  private mapInitFor: TransportRoute | null = null;
  private sub?: Subscription;

  constructor(private store: TransportStore, private svc: TransportOwnerService, private swal: SwalService, private zone: NgZone) {}

  ngOnInit(): void { this.sub = this.store.data$.subscribe(d => { if (d) this.routes = d.routes || []; }); }
  ngOnDestroy(): void { this.sub?.unsubscribe(); }

  ngAfterViewChecked(): void {
    if (this.editing && this.mapEl && this.mapInitFor !== this.editing && typeof google !== 'undefined' && google.maps) {
      this.mapInitFor = this.editing;
      this.map = new google.maps.Map(this.mapEl.nativeElement, { center: { lat: 12.4966, lng: 78.5729 }, zoom: 11, mapTypeControl: false, streetViewControl: false });
      this.map.addListener('click', (e: any) => this.zone.run(() => this.onMapClick(e.latLng.lat(), e.latLng.lng())));
      this.drawStops(true);
    }
  }

  startAdd(): void { this.editing = { name: '', source: '', destination: '', stops: [], sourceLat: null, sourceLng: null, destLat: null, destLng: null }; this.selStop = null; this.target = 'from'; this.mapInitFor = null; window.scrollTo({ top: 0, behavior: 'smooth' }); }
  edit(r: TransportRoute): void { this.editing = { ...r, stops: (r.stops || []).map(s => ({ ...s })) }; this.selStop = null; this.target = 'stop'; this.mapInitFor = null; window.scrollTo({ top: 0, behavior: 'smooth' }); }
  cancel(): void { this.editing = null; this.mapInitFor = null; this.clearMap(); }

  addStop(): void { if (!this.editing) return; this.editing.stops.push({ name: '', lat: null, lng: null }); this.selStop = this.editing.stops.length - 1; this.target = 'stop'; }
  removeStop(i: number): void { if (!this.editing) return; this.editing.stops.splice(i, 1); this.selStop = null; this.drawStops(); }
  moveStop(i: number, dir: number): void {
    if (!this.editing) return;
    const j = i + dir; if (j < 0 || j >= this.editing.stops.length) return;
    const s = this.editing.stops; [s[i], s[j]] = [s[j], s[i]]; this.selStop = j; this.drawStops();
  }

  private onMapClick(lat: number, lng: number): void {
    if (!this.editing) return;
    if (this.target === 'from') { this.editing.sourceLat = lat; this.editing.sourceLng = lng; this.target = 'to'; }
    else if (this.target === 'to') { this.editing.destLat = lat; this.editing.destLng = lng; this.target = 'stop'; this.selStop = null; }
    else if (this.selStop == null) { this.editing.stops.push({ name: `Stop ${this.editing.stops.length + 1}`, lat, lng }); this.selStop = this.editing.stops.length - 1; }
    else { this.editing.stops[this.selStop].lat = lat; this.editing.stops[this.selStop].lng = lng; }
    this.drawStops();
  }

  private clearMap(): void { this.markers.forEach(m => m.setMap(null)); this.markers = []; if (this.line) { this.line.setMap(null); this.line = null; } }

  drawStops(fit = false): void {
    if (!this.map || !this.editing) return;
    this.clearMap();
    const e = this.editing;
    const num = (v: any) => (v == null || v === '' ? null : +v);
    const pts: any[] = [];
    const addMarker = (pos: any, opts: any, onDrag: (ll: any) => void) => {
      const m = new google.maps.Marker({ position: pos, map: this.map, draggable: true, ...opts });
      m.addListener('dragend', (ev: any) => this.zone.run(() => { onDrag(ev.latLng); this.drawStops(); }));
      this.markers.push(m);
    };
    const sLat = num(e.sourceLat), sLng = num(e.sourceLng), dLat = num(e.destLat), dLng = num(e.destLng);
    if (sLat != null && sLng != null) {
      const ll = { lat: sLat, lng: sLng }; pts.push(ll);
      addMarker(ll, { label: { text: 'A', color: '#fff', fontWeight: '800' }, title: e.source || 'From', zIndex: 3 }, (p) => { e.sourceLat = p.lat(); e.sourceLng = p.lng(); });
    }
    e.stops.forEach((st: TransportStop, i: number) => {
      const la = num(st.lat), ln = num(st.lng);
      if (la == null || ln == null) return;
      const ll = { lat: la, lng: ln }; pts.push(ll);
      addMarker(ll, { label: { text: String(i + 1), color: '#fff', fontWeight: '700' }, title: st.name,
        icon: { path: google.maps.SymbolPath.CIRCLE, scale: 11, fillColor: '#1565c0', fillOpacity: 1, strokeColor: '#fff', strokeWeight: 2 } },
        (p) => { st.lat = p.lat(); st.lng = p.lng(); });
      this.markers[this.markers.length - 1].addListener('click', () => this.zone.run(() => { this.target = 'stop'; this.selStop = i; }));
    });
    if (dLat != null && dLng != null) {
      const ll = { lat: dLat, lng: dLng }; pts.push(ll);
      addMarker(ll, { label: { text: 'B', color: '#fff', fontWeight: '800' }, title: e.destination || 'To', zIndex: 3 }, (p) => { e.destLat = p.lat(); e.destLng = p.lng(); });
    }
    if (pts.length > 1) this.line = new google.maps.Polyline({ path: pts, strokeColor: '#1565c0', strokeOpacity: .7, strokeWeight: 4, map: this.map });
    if (fit && pts.length) { const b = new google.maps.LatLngBounds(); pts.forEach(p => b.extend(p)); pts.length === 1 ? (this.map.setCenter(pts[0]), this.map.setZoom(14)) : this.map.fitBounds(b, 40); }
  }

  save(): void {
    if (!this.editing) return;
    if (!this.editing.source.trim() || !this.editing.destination.trim()) { this.swal.error('From and To are required'); return; }
    this.saving = true;
    const n = (v: any) => (v == null || v === '' ? null : +v);
    const body = { ...this.editing,
      sourceLat: n(this.editing.sourceLat), sourceLng: n(this.editing.sourceLng), destLat: n(this.editing.destLat), destLng: n(this.editing.destLng),
      stops: this.editing.stops.filter(s => s.name && s.name.trim()).map(s => ({ name: s.name.trim(), lat: n(s.lat), lng: n(s.lng) })) };
    this.svc.saveRoute(body).subscribe({
      next: (r: any) => { this.saving = false; if (r?.success === false) { this.swal.error(r.message); return; } this.cancel(); this.store.refresh(); this.swal.success('Route saved'); },
      error: (e) => { this.saving = false; this.swal.error('Could not save', e?.error?.message || ''); }
    });
  }
  remove(r: TransportRoute): void {
    if (!confirm(`Remove route ${r.name}?`)) return;
    this.svc.deleteRoute(r.id!).subscribe({ next: () => { this.store.refresh(); this.swal.success('Route removed'); }, error: (e) => this.swal.error('Could not remove', e?.error?.message || '') });
  }
}
