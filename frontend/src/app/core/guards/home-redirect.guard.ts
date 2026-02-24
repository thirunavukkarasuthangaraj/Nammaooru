import { Injectable } from '@angular/core';
import { CanActivate, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { UserRole } from '../models/auth.model';

@Injectable({
  providedIn: 'root'
})
export class HomeRedirectGuard implements CanActivate {

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  canActivate(): boolean {
    if (!this.authService.isAuthenticated()) {
      this.router.navigate(['/auth/login']);
      return false;
    }

    const user = this.authService.getCurrentUser();
    switch (user?.role) {
      case UserRole.SUPER_ADMIN:
        this.router.navigate(['/analytics']);
        break;
      case UserRole.ADMIN:
        this.router.navigate(['/admin/post-dashboard']);
        break;
      case UserRole.SHOP_OWNER:
        this.router.navigate(['/shop-owner/dashboard']);
        break;
      case 'DELIVERY_PARTNER' as any:
        this.router.navigate(['/delivery/partner/orders']);
        break;
      default:
        this.router.navigate(['/auth/login']);
    }

    return false;
  }
}
