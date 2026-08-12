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
      // Fail open on transient errors so a status-check hiccup doesn't lock out a paid shop owner;
      // the backend ShopPaymentGateFilter still enforces the lock server-side either way.
      catchError(() => of(true))
    );
  }
}
