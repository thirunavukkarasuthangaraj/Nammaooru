import { Injectable } from '@angular/core';
import { CanActivate, Router, UrlTree } from '@angular/router';
import { Observable, of } from 'rxjs';
import { map, catchError } from 'rxjs/operators';
import { AuthService } from '../services/auth.service';
import { PaymentCollectService } from '../services/payment-collect.service';
import { UserRole } from '../models/auth.model';

@Injectable({
  providedIn: 'root'
})
export class PaymentLockGuard implements CanActivate {

  constructor(
    private authService: AuthService,
    private paymentCollectService: PaymentCollectService,
    private router: Router
  ) {}

  canActivate(): Observable<boolean | UrlTree> | boolean {
    const user = this.authService.getCurrentUser();
    if (!user || user.role !== UserRole.SHOP_OWNER) {
      return true;
    }

    return this.paymentCollectService.getStatus().pipe(
      map(status => status.paid ? true : this.router.parseUrl('/pay-and-use')),
      // Offline: fall back to the last server verdict so a shop that was already
      // locked stays locked without a connection. Online hiccups still fail open —
      // the backend ShopPaymentGateFilter enforces the lock server-side regardless.
      catchError(() => {
        if (!navigator.onLine) {
          const cached = this.paymentCollectService.getCachedStatus();
          if (cached && cached.paymentRequired && !cached.paid) {
            return of(this.router.parseUrl('/pay-and-use'));
          }
        }
        return of(true);
      })
    );
  }
}
