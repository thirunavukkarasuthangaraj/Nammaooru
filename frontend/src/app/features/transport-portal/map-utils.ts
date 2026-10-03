import { TransportRoute, TransportSchedule, routePath } from '../../core/services/transport-owner.service';

declare var google: any;

export interface LL { lat: number; lng: number; }

/** Cached road-following paths per route id, shared by the live and home pages. */
const roadCache = new Map<number, LL[]>();
const pending = new Map<number, Promise<LL[]>>();

/**
 * Road-following path for a route: A -> stops -> B via the Directions service.
 * Falls back to straight segments when Directions is unavailable or fails.
 */
export function roadPath(route: TransportRoute | null | undefined): Promise<LL[]> {
  const pts = routePath(route).map(p => ({ lat: p.lat, lng: p.lng }));
  if (!route || route.id == null || pts.length < 2) return Promise.resolve(pts);
  const id = route.id;
  const cached = roadCache.get(id);
  if (cached) return Promise.resolve(cached);
  const inflight = pending.get(id);
  if (inflight) return inflight;
  const p = new Promise<LL[]>((resolve) => {
    try {
      if (!google?.maps?.DirectionsService) { resolve(pts); return; }
      const svc = new google.maps.DirectionsService();
      const waypoints = pts.slice(1, -1).slice(0, 23).map(w => ({ location: w, stopover: true }));
      svc.route({ origin: pts[0], destination: pts[pts.length - 1], waypoints, travelMode: 'DRIVING', optimizeWaypoints: false },
        (res: any, status: string) => {
          if (status === 'OK' && res?.routes?.[0]?.overview_path?.length) {
            const path = res.routes[0].overview_path.map((q: any) => ({ lat: q.lat(), lng: q.lng() }));
            roadCache.set(id, path); resolve(path);
          } else { resolve(pts); }
        });
    } catch { resolve(pts); }
  }).finally(() => pending.delete(id));
  pending.set(id, p);
  return p;
}

/** Draw a route as white outline + coloured line. Returns both polylines so the caller can remove them. */
export function drawRouteLine(map: any, path: LL[], color: string, bold = false): any[] {
  if (!map || path.length < 2) return [];
  const outline = new google.maps.Polyline({ path, strokeColor: '#ffffff', strokeOpacity: 1, strokeWeight: bold ? 13 : 9, map, zIndex: bold ? 3 : 1 });
  const line = new google.maps.Polyline({ path, strokeColor: color, strokeOpacity: 1, strokeWeight: bold ? 7 : 5, map, zIndex: bold ? 4 : 2 });
  return [outline, line];
}

/** Bus icon as an SVG data URL, tinted with the state colour and rotated to the heading. */
export function busIcon(color: string, heading: number): any {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="44" height="44" viewBox="0 0 44 44">
    <g transform="rotate(${Math.round(heading)} 22 22)">
      <path d="M22 4 L30 16 L26 16 L26 20 L18 20 L18 16 L14 16 Z" fill="${color}" stroke="#fff" stroke-width="1.5"/>
    </g>
    <circle cx="22" cy="26" r="11" fill="${color}" stroke="#fff" stroke-width="3"/>
    <path d="M16 21h12a2 2 0 0 1 2 2v6a1 1 0 0 1-1 1h-1a1.5 1.5 0 0 1-3 0h-6a1.5 1.5 0 0 1-3 0h-1a1 1 0 0 1-1-1v-6a2 2 0 0 1 2-2zm0 3v3h12v-3z" fill="#fff"/>
  </svg>`;
  return { url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(svg), scaledSize: new google.maps.Size(44, 44), anchor: new google.maps.Point(22, 26) };
}

const anims = new WeakMap<any, number>();

/** Slide a marker from its current position to `to` over `ms` milliseconds. */
export function animateMarker(marker: any, to: LL, ms = 3500): void {
  const fromPos = marker.getPosition();
  if (!fromPos) { marker.setPosition(to); return; }
  const from = { lat: fromPos.lat(), lng: fromPos.lng() };
  if (Math.abs(from.lat - to.lat) < 1e-7 && Math.abs(from.lng - to.lng) < 1e-7) return;
  const prev = anims.get(marker);
  if (prev) cancelAnimationFrame(prev);
  const start = performance.now();
  const step = (now: number) => {
    const t = Math.min(1, (now - start) / ms);
    const e = t < .5 ? 2 * t * t : -1 + (4 - 2 * t) * t; // ease in-out
    marker.setPosition({ lat: from.lat + (to.lat - from.lat) * e, lng: from.lng + (to.lng - from.lng) * e });
    if (t < 1) anims.set(marker, requestAnimationFrame(step)); else anims.delete(marker);
  };
  anims.set(marker, requestAnimationFrame(step));
}

export function stateColor(state: string): string {
  return state === 'MOVING' ? '#1b5e20' : state === 'STOPPED' ? '#0d47a1' : '#546e7a';
}


/* ===================== timetable helpers ===================== */

const DAY = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
export function minOf(hhmm: string): number { const [h, m] = (hhmm || '0:0').split(':').map(Number); return h * 60 + m; }
export function nowMin(d = new Date()): number { return d.getHours() * 60 + d.getMinutes() + d.getSeconds() / 60; }
export function runsToday(s: TransportSchedule, d = new Date()): boolean {
  const days = (s.days || 'DAILY').toUpperCase();
  return days === 'DAILY' || days.split(',').map(x => x.trim()).includes(DAY[d.getDay()]);
}

/** The schedule row the vehicle is on right now (depart <= now <= arrive), if any. */
export function currentLeg(rows: TransportSchedule[], d = new Date()): TransportSchedule | null {
  const n = nowMin(d);
  return (rows || []).filter(r => r.isActive !== false && runsToday(r, d)).find(r => minOf(r.departTime) <= n && n <= minOf(r.arriveTime)) || null;
}

/** Next departure after now (today), or the first of the day if all have passed. */
export function nextDeparture(rows: TransportSchedule[], d = new Date()): TransportSchedule | null {
  const n = nowMin(d);
  const today = (rows || []).filter(r => r.isActive !== false && runsToday(r, d)).sort((a, b) => minOf(a.departTime) - minOf(b.departTime));
  return today.find(r => minOf(r.departTime) >= n) || today[0] || null;
}

/** 0..1 progress of the current leg by the clock. */
export function legProgress(leg: TransportSchedule, d = new Date()): number {
  const a = minOf(leg.departTime), b = minOf(leg.arriveTime);
  if (b <= a) return 0;
  return Math.max(0, Math.min(1, (nowMin(d) - a) / (b - a)));
}

/** Point at fraction t (0..1) along a polyline path. */
export function pointAlong(path: LL[], t: number): { pos: LL; heading: number } | null {
  if (!path || path.length === 0) return null;
  if (path.length === 1) return { pos: path[0], heading: 0 };
  const segs: number[] = []; let total = 0;
  for (let i = 1; i < path.length; i++) { const dd = dist(path[i - 1], path[i]); segs.push(dd); total += dd; }
  let target = total * Math.max(0, Math.min(1, t)), acc = 0;
  for (let i = 0; i < segs.length; i++) {
    if (acc + segs[i] >= target || i === segs.length - 1) {
      const f = segs[i] === 0 ? 0 : (target - acc) / segs[i];
      const a = path[i], b = path[i + 1];
      return { pos: { lat: a.lat + (b.lat - a.lat) * f, lng: a.lng + (b.lng - a.lng) * f }, heading: bearing(a, b) };
    }
    acc += segs[i];
  }
  return { pos: path[path.length - 1], heading: 0 };
}

/** Fraction (0..1) of the path already covered by the point nearest to `p`. */
export function progressAlong(path: LL[], p: LL): number {
  if (!path || path.length < 2) return 0;
  let best = Infinity, bestAcc = 0, acc = 0, total = 0;
  for (let i = 1; i < path.length; i++) {
    const a = path[i - 1], b = path[i], seg = dist(a, b);
    const t = seg === 0 ? 0 : Math.max(0, Math.min(1, ((p.lat - a.lat) * (b.lat - a.lat) + (p.lng - a.lng) * (b.lng - a.lng)) / ((b.lat - a.lat) ** 2 + (b.lng - a.lng) ** 2)));
    const q = { lat: a.lat + (b.lat - a.lat) * t, lng: a.lng + (b.lng - a.lng) * t };
    const dq = dist(p, q);
    if (dq < best) { best = dq; bestAcc = acc + seg * t; }
    acc += seg; total += seg;
  }
  return total === 0 ? 0 : bestAcc / total;
}

export function dist(a: LL, b: LL): number {
  const R = 6371, dLat = (b.lat - a.lat) * Math.PI / 180, dLon = (b.lng - a.lng) * Math.PI / 180;
  const x = Math.sin(dLat / 2) ** 2 + Math.cos(a.lat * Math.PI / 180) * Math.cos(b.lat * Math.PI / 180) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(x));
}
export function bearing(a: LL, b: LL): number {
  const y = Math.sin((b.lng - a.lng) * Math.PI / 180) * Math.cos(b.lat * Math.PI / 180);
  const x = Math.cos(a.lat * Math.PI / 180) * Math.sin(b.lat * Math.PI / 180) - Math.sin(a.lat * Math.PI / 180) * Math.cos(b.lat * Math.PI / 180) * Math.cos((b.lng - a.lng) * Math.PI / 180);
  return (Math.atan2(y, x) * 180 / Math.PI + 360) % 360;
}

/** Faded bus icon for the timetable ("should be here") position. */
export function ghostBusIcon(color: string, heading: number): any {
  const base = busIcon(color, heading);
  const svg = decodeURIComponent(base.url.split(',')[1]).replace('<svg ', '<svg opacity="0.45" ');
  return { ...base, url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(svg) };
}

/** Human label for a direction on a route. */
export function dirLabel(route: TransportRoute | null | undefined, dir: string | undefined): string {
  if (!route) return dir === 'BA' ? 'B → A' : 'A → B';
  return dir === 'BA' ? `${route.destination} → ${route.source}` : `${route.source} → ${route.destination}`;
}
