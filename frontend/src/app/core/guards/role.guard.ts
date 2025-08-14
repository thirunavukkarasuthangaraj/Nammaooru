import { Injectable } from '@angular/core';
import { CanActivate, ActivatedRouteSnapshot, RouterStateSnapshot, Router } from '@angular/router';
import { Observable } from 'rxjs';
import { AuthService } from '../services/auth.service';
import { UserRole } from '../models/auth.model';

@Injectable({
  providedIn: 'root'
})
export class RoleGuard implements CanActivate {

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  canActivate(
    route: ActivatedRouteSnapshot,
    state: RouterStateSnapshot
  ): Observable<boolean> | Promise<boolean> | boolean {
    
    const requiredRoles = route.data['roles'] as UserRole[];
    
    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    if (!this.authService.isAuthenticated()) {
      this.router.navigate(['/auth/login']);
      return false;
    }

    if (this.authService.hasAnyRole(requiredRoles)) {
      return true;
    }

    // Redirect based on user role
    const user = this.authService.getCurrentUser();
    if (user) {
      switch (user.role) {
        case UserRole.ADMIN:
          this.router.navigate(['/admin']);
          break;
        case UserRole.SHOP_OWNER:
          this.router.navigate(['/shop-owner']);
          break;
        default:
          this.router.navigate(['/shops']);
          break;
      }
    } else {
      this.router.navigate(['/unauthorized']);
    }

    return false;
  }
}