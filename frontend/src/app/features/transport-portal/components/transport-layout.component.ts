import { Component, OnDestroy, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Subscription, interval } from 'rxjs';
import { AuthService } from '../../../core/services/auth.service';
import { TransportOwnerService } from '../../../core/services/transport-owner.service';
import { TransportStore } from '../transport-store.service';

@Component({
  selector: 'app-transport-layout',
  template: `
<div class="tp-shell" [class.nav-open]="navOpen">
  <aside class="tp-nav">
    <div class="brand">
      <mat-icon>directions_bus</mat-icon>
      <div class="brand-text">
        <strong>{{ company }}</strong>
        <small>Fleet owner portal</small>
      </div>
    </div>
    <nav>
      <a *ngFor="let m of menu" [routerLink]="m.route" routerLinkActive="active" (click)="navOpen = false">
        <mat-icon>{{ m.icon }}</mat-icon><span>{{ m.title }}</span>
        <em *ngIf="m.badge" class="badge">{{ m.badge }}</em>
      </a>
    </nav>
    <div class="nav-foot">
      <div class="counts">
        <span class="moving">{{ moving }} moving</span>
        <span class="stopped">{{ stopped }} stopped</span>
        <span class="offline">{{ offline }} offline</span>
      </div>
      <button mat-stroked-button (click)="logout()"><mat-icon>logout</mat-icon> Logout</button>
    </div>
  </aside>
  <div class="tp-overlay" (click)="navOpen = false"></div>
  <main class="tp-main">
    <header class="tp-top">
      <button mat-icon-button class="burger" (click)="navOpen = !navOpen"><mat-icon>menu</mat-icon></button>
      <span class="title">{{ pageTitle }}</span>
      <span class="spacer"></span>
      <span class="live-dot" [class.on]="liveOk" title="Live feed"></span>
      <button mat-icon-button (click)="refresh()" title="Refresh"><mat-icon>refresh</mat-icon></button>
    </header>
    <section class="tp-content"><router-outlet></router-outlet></section>
  </main>
</div>`,
  styles: [`
    :host { display: block; }
    .tp-shell { display: flex; min-height: 100vh; background: #f3f6fa; }
    .tp-nav { width: 240px; background: #0d47a1; color: #fff; display: flex; flex-direction: column; position: sticky; top: 0; height: 100vh; }
    .brand { display: flex; gap: 10px; align-items: center; padding: 18px 16px; border-bottom: 1px solid rgba(255,255,255,.12); mat-icon { font-size: 30px; width: 30px; height: 30px; } }
    .brand-text { display: flex; flex-direction: column; strong { font-size: 15px; line-height: 1.2; } small { opacity: .75; font-size: 11.5px; } }
    nav { display: flex; flex-direction: column; padding: 10px 8px; gap: 2px; }
    nav a { display: flex; align-items: center; gap: 12px; padding: 11px 12px; border-radius: 10px; color: rgba(255,255,255,.85); text-decoration: none; font-weight: 500; mat-icon { font-size: 22px; width: 22px; height: 22px; } }
    nav a:hover { background: rgba(255,255,255,.08); }
    nav a.active { background: #fff; color: #0d47a1; }
    .badge { margin-left: auto; background: #ff9800; color: #fff; border-radius: 999px; font-size: 11px; padding: 1px 8px; font-style: normal; }
    .nav-foot { margin-top: auto; padding: 14px 16px; border-top: 1px solid rgba(255,255,255,.12); display: flex; flex-direction: column; gap: 10px; button { color: #fff; border-color: rgba(255,255,255,.4); } }
    .counts { display: flex; gap: 8px; flex-wrap: wrap; font-size: 11.5px; span { padding: 2px 8px; border-radius: 999px; background: rgba(255,255,255,.12); } .moving { background: #2e7d32; } .stopped { background: #1976d2; } .offline { background: #546e7a; } }
    .tp-main { flex: 1; min-width: 0; display: flex; flex-direction: column; }
    .tp-top { display: flex; align-items: center; gap: 8px; padding: 8px 16px; background: #fff; border-bottom: 1px solid #e5e7eb; position: sticky; top: 0; z-index: 5; .title { font-weight: 700; font-size: 17px; } .spacer { flex: 1; } }
    .burger { display: none; }
    .live-dot { width: 10px; height: 10px; border-radius: 50%; background: #cfd8dc; margin-right: 4px; &.on { background: #2e7d32; box-shadow: 0 0 0 4px rgba(46,125,50,.2); } }
    .tp-content { padding: 16px; flex: 1; }
    .tp-overlay { display: none; }
    @media (max-width: 860px) {
      .tp-nav { position: fixed; left: -260px; transition: left .25s; z-index: 20; }
      .nav-open .tp-nav { left: 0; }
      .nav-open .tp-overlay { display: block; position: fixed; inset: 0; background: rgba(0,0,0,.4); z-index: 15; }
      .burger { display: inline-flex; }
      .tp-content { padding: 10px; }
    }
  `]
})
export class TransportLayoutComponent implements OnInit, OnDestroy {
  navOpen = false;
  company = 'My Fleet';
  liveOk = false;
  moving = 0; stopped = 0; offline = 0;
  private subs: Subscription[] = [];

  menu = [
    { title: 'Live map', icon: 'my_location', route: '/transport/live', badge: '' },
    { title: 'Vehicles', icon: 'directions_bus', route: '/transport/vehicles', badge: '' },
    { title: 'Drivers', icon: 'badge', route: '/transport/drivers', badge: '' },
    { title: 'Routes', icon: 'alt_route', route: '/transport/routes', badge: '' },
    { title: 'Timetable', icon: 'schedule', route: '/transport/timetable', badge: '' },
    { title: 'Trips', icon: 'history', route: '/transport/trips', badge: '' },
  ];

  constructor(private store: TransportStore, private svc: TransportOwnerService, private auth: AuthService, private router: Router) {}

  get pageTitle(): string {
    const m = this.menu.find(x => this.router.url.startsWith(x.route));
    return m ? m.title : 'Transport';
  }

  ngOnInit(): void {
    this.subs.push(this.store.load().subscribe({ error: () => this.router.navigate(['/transport/login']) }));
    this.subs.push(this.store.data$.subscribe(d => {
      if (!d) return;
      this.company = d.transporter?.companyName || 'My Fleet';
      this.menu[1].badge = d.vehicles?.length ? String(d.vehicles.length) : '';
      this.menu[2].badge = d.drivers?.length ? String(d.drivers.length) : '';
      let mv = 0, st = 0, off = 0;
      (d.vehicles || []).forEach(v => {
        const s = this.store.stateOf(v.id!);
        if (s === 'MOVING') mv++; else if (s === 'STOPPED') st++; else off++;
      });
      this.moving = mv; this.stopped = st; this.offline = off;
    }));
    // Poll live positions every 5 s for every page in the portal
    this.subs.push(interval(5000).subscribe(() => {
      if (!this.store.snapshot) return;
      this.svc.live().subscribe({
        next: p => { this.liveOk = true; this.store.applyPositions(p); },
        error: () => { this.liveOk = false; }
      });
    }));
  }

  refresh(): void { this.store.refresh(); }

  logout(): void {
    this.store.clear();
    this.auth.logout();
    this.router.navigate(['/transport']);
  }

  ngOnDestroy(): void { this.subs.forEach(s => s.unsubscribe()); }
}
