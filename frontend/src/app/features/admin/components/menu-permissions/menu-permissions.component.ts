import { Component, OnInit, OnDestroy } from '@angular/core';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { MenuPermissionService, Permission, UserMenuPermission } from '../../../../core/services/menu-permission.service';
import { SwalService } from '../../../../core/services/swal.service';

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
    private swal: SwalService
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
          this.swal.toast('Error loading permissions', 'error');
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
          this.swal.toast('Error loading shop owners', 'error');
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
            this.swal.toast(`Permission removed for ${shopOwner.fullName}`, 'success');
            this.saving[shopOwner.userId] = false;
          },
          error: (error) => {
            console.error('Error removing permission:', error);
            this.swal.toast('Error removing permission', 'error');
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
            this.swal.toast(`Permission granted for ${shopOwner.fullName}`, 'success');
            this.saving[shopOwner.userId] = false;
          },
          error: (error) => {
            console.error('Error adding permission:', error);
            this.swal.toast('Error adding permission', 'error');
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
          this.swal.toast(`All permissions granted for ${shopOwner.fullName}`, 'success');
          this.saving[shopOwner.userId] = false;
        },
        error: (error) => {
          console.error('Error granting all permissions:', error);
          this.swal.toast('Error granting permissions', 'error');
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
          this.swal.toast(`All permissions revoked for ${shopOwner.fullName}`, 'success');
          this.saving[shopOwner.userId] = false;
        },
        error: (error) => {
          console.error('Error revoking all permissions:', error);
          this.swal.toast('Error revoking permissions', 'error');
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
