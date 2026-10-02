import { Injectable } from '@angular/core';
import { CanActivate, Router, UrlTree } from '@angular/router';
import { Observable, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { AuthService } from '../services/auth.service';
import { TransportOwnerService } from '../services/transport-owner.service';

/** Lets a logged-in user into /transport/** only if they are an ACTIVE transporter. */
@Injectable({ providedIn: 'root' })
export class TransporterGuard implements CanActivate {
  constructor(private auth: AuthService, private svc: TransportOwnerService, private router: Router) {}

  canActivate(): Observable<boolean | UrlTree> {
    if (!this.auth.isAuthenticated()) {
      return of(this.router.createUrlTree(['/transport/login']));
    }
    return this.svc.me().pipe(
      map(me => {
        if (me && me.isOwner) return true;
        const status = me && me.transporter ? me.transporter.status : null;
        return this.router.createUrlTree(['/transport/login'], { queryParams: { status: status || 'none' } });
      }),
      catchError(() => of(this.router.createUrlTree(['/transport/login'])))
    );
  }
}
