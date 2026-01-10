import { Component, OnInit, OnDestroy } from '@angular/core';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MenuPermissionService, Permission, UserMenuPermission } from '../../../../core/services/menu-permission.service';

@Component({
  selector: 'app-menu-permissions',
  templateUrl: './menu-permissions.component.html',
  styleUrls: ['./menu-permissions.component.scss']
})
export class MenuPermissionsComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  shopOwners: UserMenuPermission[] = [];
  allPermissions: Permission[] = [];
  loading = true;
  saving: { [userId: number]: boolean } = {};

  // Permission labels for display
  permissionLabels: { [key: string]: string } = {
    'MENU_DASHBOARD': 'Dashboard',
    'MENU_SHOP_PROFILE': 'Shop Profile',
    'MENU_MY_PRODUCTS': 'My Products',
    'MENU_BROWSE_PRODUCTS': 'Browse Products',
    'MENU_COMBOS': 'Combos',
    'MENU_BULK_IMPORT': 'Bulk Import',
    'MENU_ORDER_MANAGEMENT': 'Order Management',
    'MENU_NOTIFICATIONS': 'Notifications',
    'MENU_PROMO_CODES': 'Promo Codes'
  };

  constructor(
    private menuPermissionService: MenuPermissionService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadData();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadData(): void {
    this.loading = true;

    // Load all permissions first
    this.menuPermissionService.getAllMenuPermissions()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (permissions) => {
          this.allPermissions = permissions;
          this.loadShopOwners();
        },
        error: (error) => {
          console.error('Error loading permissions:', error);
          this.snackBar.open('Error loading permissions', 'Close', { duration: 3000 });
          this.loading = false;
        }
      });
  }

  loadShopOwners(): void {
    this.menuPermissionService.getAllShopOwnersWithPermissions()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (shopOwners) => {
          this.shopOwners = shopOwners;
          this.loading = false;
        },
        error: (error) => {
          console.error('Error loading shop owners:', error);
          this.snackBar.open('Error loading shop owners', 'Close', { duration: 3000 });
          this.loading = false;
        }
      });
  }

  hasPermission(shopOwner: UserMenuPermission, permissionName: string): boolean {
    return shopOwner.menuPermissions.includes(permissionName);
  }

  togglePermission(shopOwner: UserMenuPermission, permissionName: string): void {
    if (this.saving[shopOwner.userId]) return;

    this.saving[shopOwner.userId] = true;
    const hasPermission = this.hasPermission(shopOwner, permissionName);

    if (hasPermission) {
      // Remove permission
      this.menuPermissionService.removeMenuPermission(shopOwner.userId, permissionName)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: () => {
            shopOwner.menuPermissions = shopOwner.menuPermissions.filter(p => p !== permissionName);
            this.snackBar.open(`Permission removed for ${shopOwner.fullName}`, 'Close', { duration: 2000 });
            this.saving[shopOwner.userId] = false;
          },
          error: (error) => {
            console.error('Error removing permission:', error);
            this.snackBar.open('Error removing permission', 'Close', { duration: 3000 });
            this.saving[shopOwner.userId] = false;
          }
        });
    } else {
      // Add permission
      this.menuPermissionService.addMenuPermission(shopOwner.userId, permissionName)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: () => {
            shopOwner.menuPermissions.push(permissionName);
            this.snackBar.open(`Permission granted for ${shopOwner.fullName}`, 'Close', { duration: 2000 });
            this.saving[shopOwner.userId] = false;
          },
          error: (error) => {
            console.error('Error adding permission:', error);
            this.snackBar.open('Error adding permission', 'Close', { duration: 3000 });
            this.saving[shopOwner.userId] = false;
          }
        });
    }
  }

  grantAllPermissions(shopOwner: UserMenuPermission): void {
    if (this.saving[shopOwner.userId]) return;

    this.saving[shopOwner.userId] = true;
    this.menuPermissionService.grantAllMenuPermissions(shopOwner.userId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          shopOwner.menuPermissions = [...shopOwner.allAvailablePermissions];
          this.snackBar.open(`All permissions granted for ${shopOwner.fullName}`, 'Close', { duration: 2000 });
          this.saving[shopOwner.userId] = false;
        },
        error: (error) => {
          console.error('Error granting all permissions:', error);
          this.snackBar.open('Error granting permissions', 'Close', { duration: 3000 });
          this.saving[shopOwner.userId] = false;
        }
      });
  }

  revokeAllPermissions(shopOwner: UserMenuPermission): void {
    if (this.saving[shopOwner.userId]) return;

    this.saving[shopOwner.userId] = true;
    this.menuPermissionService.revokeAllMenuPermissions(shopOwner.userId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          shopOwner.menuPermissions = [];
          this.snackBar.open(`All permissions revoked for ${shopOwner.fullName}`, 'Close', { duration: 2000 });
          this.saving[shopOwner.userId] = false;
        },
        error: (error) => {
          console.error('Error revoking all permissions:', error);
          this.snackBar.open('Error revoking permissions', 'Close', { duration: 3000 });
          this.saving[shopOwner.userId] = false;
        }
      });
  }

  getPermissionLabel(permissionName: string): string {
    return this.permissionLabels[permissionName] || permissionName;
  }

  getPermissionCount(shopOwner: UserMenuPermission): string {
    return `${shopOwner.menuPermissions.length}/${shopOwner.allAvailablePermissions.length}`;
  }
}
