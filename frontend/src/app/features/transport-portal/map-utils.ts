import { TransportRoute, routePath } from '../../core/services/transport-owner.service';

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
