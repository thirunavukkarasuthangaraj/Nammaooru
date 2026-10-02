import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';
import { OwnerBootstrap, TransportOwnerService, TransportPosition } from '../../core/services/transport-owner.service';

/** Shared owner data for the portal pages, so each page does not refetch everything. */
@Injectable({ providedIn: 'root' })
export class TransportStore {
  private subject = new BehaviorSubject<OwnerBootstrap | null>(null);
  readonly data$ = this.subject.asObservable();
  loading = false;

  constructor(private svc: TransportOwnerService) {}

  get snapshot(): OwnerBootstrap | null { return this.subject.value; }

  load(force = false): Observable<OwnerBootstrap | null> {
    if (this.subject.value && !force) return of(this.subject.value);
    this.loading = true;
    return this.svc.bootstrap().pipe(tap({
      next: d => { this.loading = false; this.subject.next(d); },
      error: () => { this.loading = false; }
    }));
  }

  refresh(): void { this.load(true).subscribe({ error: () => {} }); }

  applyPositions(positions: TransportPosition[]): void {
    const d = this.subject.value;
    if (!d) return;
    const byId = new Map<number, TransportPosition>((d.positions || []).map(p => [p.vehicleId, p]));
    (positions || []).forEach(p => byId.set(p.vehicleId, p));
    this.subject.next({ ...d, positions: Array.from(byId.values()) });
  }

  clear(): void { this.subject.next(null); }

  stateOf(vehicleId: number): 'MOVING' | 'STOPPED' | 'OFFLINE' {
    const d = this.subject.value;
    const p = d?.positions?.find(x => x.vehicleId === vehicleId);
    if (!p) return 'OFFLINE';
    const stale = d?.settings?.staleAfterSec || 120;
    if ((p.ageSec ?? 9999) > stale) return 'OFFLINE';
    return p.state || 'STOPPED';
  }

  positionOf(vehicleId: number): TransportPosition | undefined {
    return this.subject.value?.positions?.find(x => x.vehicleId === vehicleId);
  }
}
