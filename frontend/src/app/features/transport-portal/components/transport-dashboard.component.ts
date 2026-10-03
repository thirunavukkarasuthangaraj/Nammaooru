import { Component, OnDestroy, OnInit } from '@angular/core';
import { Subscription } from 'rxjs';
import { TransportOwnerService, TransportVehicle } from '../../../core/services/transport-owner.service';
import { TransportStore } from '../transport-store.service';
import { currentLeg, nextDeparture, dirLabel } from '../map-utils';

/** Owner home: today at a glance plus one-click access to every activity. */
@Component({
  selector: 'app-transport-dashboard',
  template: `
<div class="dash">
  <div class="welcome">
    <div>
      <h2>{{ company }}</h2>
      <p class="sub">{{ today }} · {{ greeting }}</p>
    </div>
    <a mat-raised-button color="primary" routerLink="/transport/live"><mat-icon>my_location</mat-icon> Open live map</a>
  </div>

  <div class="stats">
    <div class="stat moving"><strong>{{ moving }}</strong><span>moving now</span></div>
    <div class="stat stopped"><strong>{{ stopped }}</strong><span>stopped</span></div>
    <div class="stat offline"><strong>{{ offline }}</strong><span>offline</span></div>
    <div class="stat"><strong>{{ vehicles.length }}</strong><span>vehicles</span></div>
    <div class="stat"><strong>{{ drivers }}</strong><span>drivers</span></div>
    <div class="stat"><strong>{{ tripsToday }}</strong><span>trips today</span></div>
    <div class="stat"><strong>{{ kmToday | number:'1.0-0' }}</strong><span>km today</span></div>
  </div>

  <div class="grid">
    <section class="card">
      <h3><mat-icon>schedule</mat-icon> Right now</h3>
      <div class="row" *ngFor="let v of vehicles">
        <mat-icon [class]="'ico ' + state(v).toLowerCase()">directions_bus</mat-icon>
        <div class="info">
          <strong>{{ v.name }}</strong>
          <small>{{ nowText(v) }}</small>
        </div>
        <span [class]="'chip ' + state(v).toLowerCase()">{{ state(v) }}</span>
      </div>
      <div class="empty" *ngIf="vehicles.length === 0">No vehicles yet.</div>
    </section>

    <section class="card">
      <h3><mat-icon>bolt</mat-icon> What do you want to do?</h3>
      <div class="actions">
        <a routerLink="/transport/vehicles"><mat-icon>add_circle</mat-icon><span>Add a vehicle</span><small>Bus, lorry, van, auto, car...</small></a>
        <a routerLink="/transport/drivers"><mat-icon>person_add</mat-icon><span>Add a driver</span><small>By mobile number; he uses the app</small></a>
        <a routerLink="/transport/routes"><mat-icon>add_road</mat-icon><span>Create a route</span><small>A, stops, B on the map</small></a>
        <a routerLink="/transport/timetable"><mat-icon>schedule</mat-icon><span>Set the timetable</span><small>Departures A→B and back</small></a>
        <a routerLink="/transport/live"><mat-icon>my_location</mat-icon><span>Watch the fleet live</span><small>Position, speed, trails</small></a>
        <a routerLink="/transport/trips"><mat-icon>history</mat-icon><span>Trip history</span><small>Trail, distance, duration</small></a>
        <a routerLink="/transport/reports"><mat-icon>bar_chart</mat-icon><span>Reports</span><small>Km and trips per vehicle / driver</small></a>
        <a routerLink="/transport/profile"><mat-icon>business</mat-icon><span>Company profile</span><small>Name, owner, contact</small></a>
      </div>
    </section>

    <section class="card">
      <h3><mat-icon>checklist</mat-icon> Setup checklist</h3>
      <div class="check" [class.done]="vehicles.length > 0"><mat-icon>{{ vehicles.length > 0 ? 'check_circle' : 'radio_button_unchecked' }}</mat-icon> Add at least one vehicle</div>
      <div class="check" [class.done]="drivers > 0"><mat-icon>{{ drivers > 0 ? 'check_circle' : 'radio_button_unchecked' }}</mat-icon> Add a driver and assign to a vehicle</div>
      <div class="check" [class.done]="routesCount > 0"><mat-icon>{{ routesCount > 0 ? 'check_circle' : 'radio_button_unchecked' }}</mat-icon> Create a route with A, stops and B</div>
      <div class="check" [class.done]="schedulesCount > 0"><mat-icon>{{ schedulesCount > 0 ? 'check_circle' : 'radio_button_unchecked' }}</mat-icon> Enter the timetable</div>
      <div class="check" [class.done]="publicCount > 0"><mat-icon>{{ publicCount > 0 ? 'check_circle' : 'radio_button_unchecked' }}</mat-icon> Mark a bus "Show to public"</div>
      <div class="check" [class.done]="tripsTotal > 0"><mat-icon>{{ tripsTotal > 0 ? 'check_circle' : 'radio_button_unchecked' }}</mat-icon> Driver starts the first trip from the app</div>
    </section>

    <section class="card">
      <h3><mat-icon>event</mat-icon> Next departures</h3>
      <div class="row" *ngFor="let n of upcoming">
        <mat-icon class="ico">departure_board</mat-icon>
        <div class="info"><strong>{{ n.time }}</strong><small>{{ n.vehicle }} · {{ n.dir }}</small></div>
      </div>
      <div class="empty" *ngIf="upcoming.length === 0">No timetable yet. <a routerLink="/transport/timetable">Add departures</a>.</div>
    </section>
  </div>
</div>`,
  styles: [`
    .welcome { display: flex; justify-content: space-between; align-items: center; gap: 12px; flex-wrap: wrap; margin-bottom: 14px; h2 { margin: 0; } .sub { margin: 2px 0 0; color: #6b7280; } }
    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(130px, 1fr)); gap: 10px; margin-bottom: 14px; }
    .stat { background: #fff; border: 1px solid #e5e7eb; border-radius: 12px; padding: 12px; display: flex; flex-direction: column; strong { font-size: 24px; font-weight: 800; color: #0d47a1; } span { font-size: 12px; color: #6b7280; } &.moving strong { color: #1b5e20; } &.stopped strong { color: #1565c0; } &.offline strong { color: #546e7a; } }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 12px; }
    .card { background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; padding: 14px; h3 { margin: 0 0 10px; font-size: 15px; display: flex; align-items: center; gap: 6px; mat-icon { color: #1565c0; } } }
    .row { display: flex; align-items: center; gap: 10px; padding: 8px 4px; border-bottom: 1px solid #f3f4f6; .info { flex: 1; display: flex; flex-direction: column; small { color: #6b7280; font-size: 12px; } } }
    .ico { &.moving { color: #1b5e20; } &.stopped { color: #1565c0; } &.offline { color: #90a4ae; } }
    .chip { font-size: 10.5px; font-weight: 700; padding: 3px 8px; border-radius: 999px; &.moving { background: #e8f5e9; color: #1b5e20; } &.stopped { background: #e3f2fd; color: #1565c0; } &.offline { background: #eceff1; color: #546e7a; } }
    .actions { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 8px; a { display: flex; flex-direction: column; gap: 2px; padding: 12px; border-radius: 12px; background: #f5f8fc; text-decoration: none; color: #111827; border: 1px solid transparent; mat-icon { color: #1565c0; } span { font-weight: 700; font-size: 13.5px; } small { color: #6b7280; font-size: 11.5px; } } a:hover { border-color: #1565c0; background: #e8f0fe; } }
    .check { display: flex; align-items: center; gap: 8px; padding: 6px 0; color: #4b5563; mat-icon { color: #cfd8dc; } &.done { color: #1b5e20; mat-icon { color: #2e7d32; } } }
    .empty { color: #9ca3af; padding: 10px 4px; a { color: #1565c0; } }
  `]
})
export class TransportDashboardComponent implements OnInit, OnDestroy {
  company = 'My Fleet';
  vehicles: TransportVehicle[] = [];
  drivers = 0; routesCount = 0; schedulesCount = 0; publicCount = 0;
  moving = 0; stopped = 0; offline = 0;
  tripsToday = 0; tripsTotal = 0; kmToday = 0;
  upcoming: { time: string; vehicle: string; dir: string }[] = [];
  today = new Date().toLocaleDateString('en-IN', { weekday: 'long', day: '2-digit', month: 'short', year: 'numeric' });
  private sub?: Subscription;

  constructor(private store: TransportStore, private svc: TransportOwnerService) {}

  get greeting(): string { const h = new Date().getHours(); return h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening'; }

  ngOnInit(): void {
    this.sub = this.store.data$.subscribe(d => {
      if (!d) return;
      this.company = d.transporter?.companyName || 'My Fleet';
      this.vehicles = d.vehicles || [];
      this.drivers = (d.drivers || []).length;
      this.routesCount = (d.routes || []).length;
      this.schedulesCount = (d.schedules || []).length;
      this.publicCount = this.vehicles.filter(v => v.isPublic).length;
      let mv = 0, st = 0, off = 0;
      this.vehicles.forEach(v => { const s = this.state(v); if (s === 'MOVING') mv++; else if (s === 'STOPPED') st++; else off++; });
      this.moving = mv; this.stopped = st; this.offline = off;
      this.upcoming = this.vehicles.map(v => {
        const n = nextDeparture((d.schedules || []).filter(s => s.vehicleId === v.id));
        const r = (d.routes || []).find(x => x.id === v.routeId);
        return n ? { time: n.departTime, vehicle: v.name, dir: dirLabel(r, n.direction) } : null;
      }).filter((x): x is { time: string; vehicle: string; dir: string } => !!x).sort((a, b) => a.time.localeCompare(b.time)).slice(0, 8);
    });
    this.svc.trips(undefined, 0, 100).subscribe({
      next: (d: any) => {
        const trips: any[] = (d && d.content) ? d.content : (Array.isArray(d) ? d : []);
        const todayKey = new Date().toDateString();
        this.tripsTotal = trips.length;
        const today = trips.filter(t => new Date(t.startedAt).toDateString() === todayKey);
        this.tripsToday = today.length;
        this.kmToday = today.reduce((s, t) => s + (+t.distanceKm || 0), 0);
      },
      error: () => {}
    });
  }
  ngOnDestroy(): void { this.sub?.unsubscribe(); }

  state(v: TransportVehicle) { return this.store.stateOf(v.id!); }
  nowText(v: TransportVehicle): string {
    const d = this.store.snapshot; if (!d) return '';
    const rows = (d.schedules || []).filter(s => s.vehicleId === v.id);
    const r = (d.routes || []).find(x => x.id === v.routeId);
    const p = this.store.positionOf(v.id!);
    const parts: string[] = [];
    if (v.driverName) parts.push(v.driverName);
    const leg = currentLeg(rows);
    if (leg) parts.push(`${leg.departTime}-${leg.arriveTime} ${dirLabel(r, leg.direction)}`);
    else { const n = nextDeparture(rows); if (n) parts.push(`next ${n.departTime} ${dirLabel(r, n.direction)}`); }
    if (p && this.state(v) !== 'OFFLINE') parts.push(`${Math.round(+(p.speedKmh || 0))} km/h`);
    return parts.join(' · ') || 'No route / timetable yet';
  }
}
