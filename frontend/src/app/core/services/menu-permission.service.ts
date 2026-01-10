import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map, catchError, throwError, BehaviorSubject, of } from 'rxjs';
import { environment } from '../../../environments/environment';
import { ApiResponse, ApiResponseHelper } from '../models/api-response.model';

export interface Permission {
  id: number;
  name: string;
  description: string;
  category: string;
  resourceType: string;
  actionType: string;
  active: boolean;
}

export interface UserMenuPermission {
  userId: number;
  username: string;
  fullName: string;
  email: string;
  menuPermissions: string[];
  allAvailablePermissions: string[];
}

// Menu permission name to route mapping
export const MENU_PERMISSION_ROUTES: { [key: string]: string } = {
  'MENU_DASHBOARD': '/shop-owner/dashboard',
  'MENU_SHOP_PROFILE': '/shop-owner/profile',
  'MENU_MY_PRODUCTS': '/shop-owner/my-products',
  'MENU_BROWSE_PRODUCTS': '/shop-owner/browse-products',
  'MENU_COMBOS': '/shop-owner/combos',
  'MENU_BULK_IMPORT': '/products/bulk-import',
  'MENU_ORDER_MANAGEMENT': '/shop-owner/orders-management',
  'MENU_NOTIFICATIONS': '/shop-owner/notifications',
  'MENU_PROMO_CODES': '/shop-owner/promo-codes'
};

@Injectable({
  providedIn: 'root'
})
export class MenuPermissionService {
  private apiUrl = `${environment.apiUrl}/menu-permissions`;
  private userMenuPermissions = new BehaviorSubject<Set<string>>(new Set());
  private permissionsLoaded = false;

  constructor(private http: HttpClient) {}

  /**
   * Get all available menu permissions (for super admin)
   */
  getAllMenuPermissions(): Observable<Permission[]> {
    return this.http.get<ApiResponse<Permission[]>>(this.apiUrl).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }

  /**
   * Get current user's menu permissions
   */
  getMyMenuPermissions(): Observable<string[]> {
    return this.http.get<ApiResponse<string[]>>(`${this.apiUrl}/my-permissions`).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        const permissions = response.data || [];
        this.userMenuPermissions.next(new Set(permissions));
        this.permissionsLoaded = true;
        return permissions;
      }),
      catchError(error => {
        console.error('Error loading menu permissions:', error);
        return of([]);
      })
    );
  }

  /**
   * Load and cache current user's menu permissions
   */
  loadMyMenuPermissions(): void {
    if (!this.permissionsLoaded) {
      this.getMyMenuPermissions().subscribe();
    }
  }

  /**
   * Get current user's menu permissions as observable
   */
  get menuPermissions$(): Observable<Set<string>> {
    return this.userMenuPermissions.asObservable();
  }

  /**
   * Check if current user has a specific menu permission
   */
  hasPermission(permissionName: string): boolean {
    return this.userMenuPermissions.value.has(permissionName);
  }

  /**
   * Check if current user has permission for a specific route
   */
  hasRoutePermission(route: string): boolean {
    // Find the permission for this route
    for (const [permission, permissionRoute] of Object.entries(MENU_PERMISSION_ROUTES)) {
      if (route.startsWith(permissionRoute)) {
        return this.hasPermission(permission);
      }
    }
    return true; // Allow if no permission mapping exists
  }

  /**
   * Get menu permissions for a specific user (super admin only)
   */
  getUserMenuPermissions(userId: number): Observable<string[]> {
    return this.http.get<ApiResponse<string[]>>(`${this.apiUrl}/user/${userId}`).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data || [];
      }),
      catchError(error => throwError(() => error))
    );
  }

  /**
   * Update menu permissions for a user (super admin only)
   */
  updateUserMenuPermissions(userId: number, permissionIds: number[]): Observable<void> {
    return this.http.put<ApiResponse<void>>(`${this.apiUrl}/user/${userId}`, { permissionIds }).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return;
      }),
      catchError(error => throwError(() => error))
    );
  }

  /**
   * Add a single menu permission to a user
   */
  addMenuPermission(userId: number, permissionName: string): Observable<void> {
    return this.http.post<ApiResponse<void>>(`${this.apiUrl}/user/${userId}/add`, { permissionName }).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return;
      }),
      catchError(error => throwError(() => error))
    );
  }

  /**
   * Remove a single menu permission from a user
   */
  removeMenuPermission(userId: number, permissionName: string): Observable<void> {
    return this.http.post<ApiResponse<void>>(`${this.apiUrl}/user/${userId}/remove`, { permissionName }).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return;
      }),
      catchError(error => throwError(() => error))
    );
  }

  /**
   * Grant all menu permissions to a user
   */
  grantAllMenuPermissions(userId: number): Observable<void> {
    return this.http.post<ApiResponse<void>>(`${this.apiUrl}/user/${userId}/grant-all`, {}).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return;
      }),
      catchError(error => throwError(() => error))
    );
  }

  /**
   * Revoke all menu permissions from a user
   */
  revokeAllMenuPermissions(userId: number): Observable<void> {
    return this.http.post<ApiResponse<void>>(`${this.apiUrl}/user/${userId}/revoke-all`, {}).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return;
      }),
      catchError(error => throwError(() => error))
    );
  }

  /**
   * Get all shop owners with their menu permissions
   */
  getAllShopOwnersWithPermissions(): Observable<UserMenuPermission[]> {
    return this.http.get<ApiResponse<UserMenuPermission[]>>(`${this.apiUrl}/shop-owners`).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data || [];
      }),
      catchError(error => throwError(() => error))
    );
  }

  /**
   * Clear cached permissions (call on logout)
   */
  clearPermissions(): void {
    this.userMenuPermissions.next(new Set());
    this.permissionsLoaded = false;
  }

  /**
   * Force reload of permissions
   */
  reloadPermissions(): void {
    this.permissionsLoaded = false;
    this.getMyMenuPermissions().subscribe();
  }
}
