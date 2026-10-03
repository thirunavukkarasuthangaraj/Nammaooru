import { Component, OnDestroy, OnInit } from '@angular/core';
import { Subscription } from 'rxjs';
import { SwalService } from '../../../core/services/swal.service';
import { TransportOwnerService } from '../../../core/services/transport-owner.service';
import { TransportStore } from '../transport-store.service';

@Component({
  selector: 'app-transport-profile',
  template: `
<div class="page">
  <div class="head"><div><h2>Company profile</h2><p class="sub">Shown to passengers as the operator name on public buses.</p></div></div>
  <div class="card">
    <div class="grid">
      <mat-form-field appearance="outline"><mat-label>Company / fleet name *</mat-label><input matInput [(ngModel)]="companyName"></mat-form-field>
      <mat-form-field appearance="outline"><mat-label>Owner name</mat-label><input matInput [(ngModel)]="ownerName"></mat-form-field>
      <mat-form-field appearance="outline"><mat-label>Contact number</mat-label><input matInput [(ngModel)]="phone" maxlength="13"></mat-form-field>
    </div>
    <div class="meta">
      <span>Status: <strong>{{ status }}</strong></span>
      <span>Registered: {{ created }}</span>
      <span>Transporter ID: {{ id }}</span>
    </div>
    <div class="actions">
      <button mat-raised-button color="primary" [disabled]="saving" (click)="save()"><mat-icon>save</mat-icon> {{ saving ? 'Saving...' : 'Save' }}</button>
    </div>
  </div>

  <div class="card help">
    <h3>How the pieces fit</h3>
    <ol>
      <li><b>Vehicles</b>: add each bus or lorry. Buses can be shown to the public.</li>
      <li><b>Drivers</b>: add by mobile number. The driver installs the Nammaooru app, logs in with that number, opens Where is Bus, taps the driver icon and starts the trip.</li>
      <li><b>Routes</b>: A, stops and B placed on the map. One route can be used by many buses.</li>
      <li><b>Timetable</b>: departures per bus, A to B and back. The map shows where each bus should be even when GPS is off, and whether it is late.</li>
      <li><b>Live map / Trips / Reports</b>: watch, review and total up what actually happened.</li>
    </ol>
  </div>
</div>`,
  styles: [`
    .head { margin-bottom: 12px; h2 { margin: 0; } .sub { margin: 4px 0 0; color: #6b7280; font-size: 13px; } }
    .card { background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; padding: 16px; margin-bottom: 12px; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 10px; }
    .meta { display: flex; gap: 18px; flex-wrap: wrap; color: #6b7280; font-size: 13px; margin: 4px 0 10px; }
    .help { h3 { margin: 0 0 8px; } ol { margin: 0; padding-left: 20px; color: #374151; line-height: 1.7; } }
  `]
})
export class TransportProfileComponent implements OnInit, OnDestroy {
  id: any = ''; companyName = ''; ownerName = ''; phone = ''; status = ''; created = '';
  saving = false;
  private sub?: Subscription;
  constructor(private store: TransportStore, private svc: TransportOwnerService, private swal: SwalService) {}
  ngOnInit(): void {
    this.sub = this.store.data$.subscribe(d => {
      const t = d?.transporter; if (!t) return;
      this.id = t.id; this.companyName = t.companyName || ''; this.ownerName = t.ownerName || ''; this.phone = t.phone || ''; this.status = t.status || '';
      this.created = t.createdAt ? new Date(t.createdAt).toLocaleDateString('en-IN') : '';
    });
  }
  ngOnDestroy(): void { this.sub?.unsubscribe(); }
  save(): void {
    if (!this.companyName.trim()) { this.swal.error('Company name is required'); return; }
    this.saving = true;
    this.svc.register(this.companyName.trim(), this.ownerName.trim(), this.phone.trim()).subscribe({
      next: (r: any) => { this.saving = false; if (r?.success === false) { this.swal.error(r.message); return; } this.store.refresh(); this.swal.success('Profile saved'); },
      error: (e) => { this.saving = false; this.swal.error('Could not save', e?.error?.message || ''); }
    });
  }
}
