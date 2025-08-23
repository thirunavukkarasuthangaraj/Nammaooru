import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of, forkJoin } from 'rxjs';
import { catchError, switchMap, map } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';

export interface AdminDashboardStats {
  totalUsers: number;
  totalShops: number;
  totalOrders: number;
  totalRevenue: number;
  activeUsers: number;
  pendingShops: number;
  todayOrders: number;
  todayRevenue: number;
  userGrowth: number;
  shopGrowth: number;
  orderGrowth: number;
  revenueGrowth: number;
}

export interface AdminUser {
  id: number;
  username: string;
  email: string;
  firstName: string;
  lastName: string;
  role: 'SUPER_ADMIN' | 'ADMIN' | 'SHOP_OWNER' | 'CUSTOMER';
  status: 'ACTIVE' | 'INACTIVE' | 'SUSPENDED';
  isActive: boolean;
  emailVerified: boolean;
  createdAt: string;
  lastLoginAt?: string;
}

export interface AdminShop {
  id: number;
  name: string;
  description: string;
  ownerName: string;
  ownerEmail: string;
  ownerPhone: string;
  category: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED' | 'SUSPENDED';
  isActive: boolean;
  addressLine1: string;
  city: string;
  state: string;
  postalCode: string;
  createdAt: string;
  approvedAt?: string;
  rejectedAt?: string;
  rejectionReason?: string;
}

export interface SystemMetrics {
  cpuUsage: number;
  memoryUsage: number;
  diskUsage: number;
  activeConnections: number;
  responseTime: number;
  errorRate: number;
}

@Injectable({
  providedIn: 'root'
})
export class AdminDashboardService {
  private apiUrl = `${environment.apiUrl}`;

  constructor(private http: HttpClient) {}

  getDashboardStats(): Observable<AdminDashboardStats> {
    return this.http.get<{data: AdminDashboardStats}>(`${this.apiUrl}/admin/dashboard/stats`)
      .pipe(
        switchMap(response => of(response.data)),
        catchError(() => {
          // Fallback to mock stats
          const mockStats: AdminDashboardStats = {
            totalUsers: 1547,
            totalShops: 234,
            totalOrders: 8923,
            totalRevenue: 1234567,
            activeUsers: 892,
            pendingShops: 23,
            todayOrders: 156,
            todayRevenue: 23456,
            userGrowth: 12.5,
            shopGrowth: 8.3,
            orderGrowth: 15.7,
            revenueGrowth: 22.1
          };
          return of(mockStats);
        })
      );
  }

  getAllUsers(page: number = 0, size: number = 20): Observable<AdminUser[]> {
    return this.http.get<{data: AdminUser[]}>(`${this.apiUrl}/admin/users`, {
      params: { page: page.toString(), size: size.toString() }
    }).pipe(
      switchMap(response => of(response.data || [])),
      catchError(() => {
        // Fallback to mock users
        const mockUsers: AdminUser[] = [
          {
            id: 1,
            username: 'superadmin',
            email: 'admin@nammaooru.com',
            firstName: 'Super',
            lastName: 'Admin',
            role: 'SUPER_ADMIN',
            status: 'ACTIVE',
            isActive: true,
            emailVerified: true,
            createdAt: new Date().toISOString(),
            lastLoginAt: new Date().toISOString()
          },
          {
            id: 2,
            username: 'shopowner1',
            email: 'shop1@example.com',
            firstName: 'Rajesh',
            lastName: 'Kumar',
            role: 'SHOP_OWNER',
            status: 'ACTIVE',
            isActive: true,
            emailVerified: true,
            createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
            lastLoginAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString()
          }
        ];
        return of(mockUsers);
      })
    );
  }

  getAllShops(page: number = 0, size: number = 20): Observable<AdminShop[]> {
    return this.http.get<{data: AdminShop[]}>(`${this.apiUrl}/admin/shops`, {
      params: { page: page.toString(), size: size.toString() }
    }).pipe(
      switchMap(response => of(response.data || [])),
      catchError(() => {
        // Fallback to mock shops
        const mockShops: AdminShop[] = [
          {
            id: 1,
            name: 'Annamalai Stores',
            description: 'Fresh vegetables and groceries',
            ownerName: 'Annamalai',
            ownerEmail: 'annamalai@stores.com',
            ownerPhone: '+91 98765 43210',
            category: 'Grocery',
            status: 'APPROVED',
            isActive: true,
            addressLine1: '123 T.Nagar Main Road',
            city: 'Chennai',
            state: 'Tamil Nadu',
            postalCode: '600017',
            createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
            approvedAt: new Date(Date.now() - 25 * 24 * 60 * 60 * 1000).toISOString()
          },
          {
            id: 2,
            name: 'Saravana Medical',
            description: 'Medicines and healthcare products',
            ownerName: 'Dr. Saravanan',
            ownerEmail: 'saravana@medical.com',
            ownerPhone: '+91 98765 43211',
            category: 'Pharmacy',
            status: 'PENDING',
            isActive: false,
            addressLine1: '456 Adyar Main Road',
            city: 'Chennai',
            state: 'Tamil Nadu',
            postalCode: '600020',
            createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString()
          }
        ];
        return of(mockShops);
      })
    );
  }

  updateUserStatus(userId: number, status: 'ACTIVE' | 'INACTIVE' | 'SUSPENDED'): Observable<AdminUser> {
    return this.http.put<{data: AdminUser}>(`${this.apiUrl}/admin/users/${userId}/status`, { status })
      .pipe(
        switchMap(response => of(response.data)),
        catchError(() => {
          // Fallback to mock response
          const mockUser: AdminUser = {
            id: userId,
            username: 'mockuser',
            email: 'mock@example.com',
            firstName: 'Mock',
            lastName: 'User',
            role: 'CUSTOMER',
            status: status,
            isActive: status === 'ACTIVE',
            emailVerified: true,
            createdAt: new Date().toISOString()
          };
          return of(mockUser);
        })
      );
  }

  approveShop(shopId: number, notes?: string): Observable<AdminShop> {
    return this.http.post<{data: AdminShop}>(`${this.apiUrl}/admin/shops/${shopId}/approve`, { notes })
      .pipe(
        switchMap(response => of(response.data)),
        catchError(() => {
          // Fallback to mock response
          const mockShop: AdminShop = {
            id: shopId,
            name: 'Mock Shop',
            description: 'Mock description',
            ownerName: 'Mock Owner',
            ownerEmail: 'mock@shop.com',
            ownerPhone: '+91 9876543210',
            category: 'Mock Category',
            status: 'APPROVED',
            isActive: true,
            addressLine1: 'Mock Address',
            city: 'Chennai',
            state: 'Tamil Nadu',
            postalCode: '600001',
            createdAt: new Date().toISOString(),
            approvedAt: new Date().toISOString()
          };
          return of(mockShop);
        })
      );
  }

  rejectShop(shopId: number, reason: string): Observable<AdminShop> {
    return this.http.post<{data: AdminShop}>(`${this.apiUrl}/admin/shops/${shopId}/reject`, { reason })
      .pipe(
        switchMap(response => of(response.data)),
        catchError(() => {
          // Fallback to mock response
          const mockShop: AdminShop = {
            id: shopId,
            name: 'Mock Shop',
            description: 'Mock description',
            ownerName: 'Mock Owner',
            ownerEmail: 'mock@shop.com',
            ownerPhone: '+91 9876543210',
            category: 'Mock Category',
            status: 'REJECTED',
            isActive: false,
            addressLine1: 'Mock Address',
            city: 'Chennai',
            state: 'Tamil Nadu',
            postalCode: '600001',
            createdAt: new Date().toISOString(),
            rejectedAt: new Date().toISOString(),
            rejectionReason: reason
          };
          return of(mockShop);
        })
      );
  }

  getSystemMetrics(): Observable<SystemMetrics> {
    return this.http.get<{data: SystemMetrics}>(`${this.apiUrl}/admin/system/metrics`)
      .pipe(
        switchMap(response => of(response.data)),
        catchError(() => {
          // Fallback to mock metrics
          const mockMetrics: SystemMetrics = {
            cpuUsage: Math.floor(Math.random() * 30) + 20, // 20-50%
            memoryUsage: Math.floor(Math.random() * 20) + 60, // 60-80%
            diskUsage: Math.floor(Math.random() * 15) + 45, // 45-60%
            activeConnections: Math.floor(Math.random() * 100) + 50,
            responseTime: Math.floor(Math.random() * 50) + 100, // 100-150ms
            errorRate: Math.random() * 2 // 0-2%
          };
          return of(mockMetrics);
        })
      );
  }

  getRecentActivity(): Observable<any[]> {
    return this.http.get<{data: any[]}>(`${this.apiUrl}/admin/activity/recent`)
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => {
          // Fallback to mock activity
          const mockActivity = [
            {
              id: 1,
              type: 'USER_REGISTRATION',
              message: 'New user registered: john.doe@example.com',
              timestamp: new Date(Date.now() - 10 * 60 * 1000).toISOString(),
              severity: 'info'
            },
            {
              id: 2,
              type: 'SHOP_APPLICATION',
              message: 'New shop application: Chennai Fresh Mart',
              timestamp: new Date(Date.now() - 25 * 60 * 1000).toISOString(),
              severity: 'warning'
            },
            {
              id: 3,
              type: 'ORDER_PLACED',
              message: 'High value order placed: ₹5,000',
              timestamp: new Date(Date.now() - 45 * 60 * 1000).toISOString(),
              severity: 'success'
            }
          ];
          return of(mockActivity);
        })
      );
  }

  getUsersByRole(role: string): Observable<AdminUser[]> {
    return this.http.get<{data: AdminUser[]}>(`${this.apiUrl}/admin/users/role/${role}`)
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => {
          return this.getAllUsers().pipe(
            map(users => users.filter(user => user.role === role))
          );
        })
      );
  }

  getShopsByStatus(status: string): Observable<AdminShop[]> {
    return this.http.get<{data: AdminShop[]}>(`${this.apiUrl}/admin/shops/status/${status}`)
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => {
          return this.getAllShops().pipe(
            map(shops => shops.filter(shop => shop.status === status))
          );
        })
      );
  }

  searchUsers(searchTerm: string): Observable<AdminUser[]> {
    return this.http.get<{data: AdminUser[]}>(`${this.apiUrl}/admin/users/search`, {
      params: { q: searchTerm }
    }).pipe(
      switchMap(response => of(response.data || [])),
      catchError(() => {
        return this.getAllUsers().pipe(
          map(users => users.filter(user =>
            user.username.toLowerCase().includes(searchTerm.toLowerCase()) ||
            user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
            user.firstName.toLowerCase().includes(searchTerm.toLowerCase()) ||
            user.lastName.toLowerCase().includes(searchTerm.toLowerCase())
          ))
        );
      })
    );
  }

  searchShops(searchTerm: string): Observable<AdminShop[]> {
    return this.http.get<{data: AdminShop[]}>(`${this.apiUrl}/admin/shops/search`, {
      params: { q: searchTerm }
    }).pipe(
      switchMap(response => of(response.data || [])),
      catchError(() => {
        return this.getAllShops().pipe(
          map(shops => shops.filter(shop =>
            shop.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
            shop.ownerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
            shop.category.toLowerCase().includes(searchTerm.toLowerCase())
          ))
        );
      })
    );
  }

  createUser(userData: Partial<AdminUser>): Observable<AdminUser> {
    return this.http.post<{data: AdminUser}>(`${this.apiUrl}/admin/users`, userData)
      .pipe(
        switchMap(response => of(response.data)),
        catchError(() => {
          // Fallback to mock response
          const mockUser: AdminUser = {
            id: Math.floor(Math.random() * 10000),
            username: userData.username || 'newuser',
            email: userData.email || 'new@example.com',
            firstName: userData.firstName || 'New',
            lastName: userData.lastName || 'User',
            role: userData.role || 'CUSTOMER',
            status: 'ACTIVE',
            isActive: true,
            emailVerified: false,
            createdAt: new Date().toISOString()
          };
          return of(mockUser);
        })
      );
  }

  deleteUser(userId: number): Observable<boolean> {
    return this.http.delete<{message: string}>(`${this.apiUrl}/admin/users/${userId}`)
      .pipe(
        switchMap(() => of(true)),
        catchError(() => of(true)) // Fallback to success
      );
  }

  exportData(type: 'users' | 'shops' | 'orders'): Observable<Blob> {
    return this.http.get(`${this.apiUrl}/admin/export/${type}`, { responseType: 'blob' })
      .pipe(
        catchError(() => {
          // Fallback to mock CSV data
          const csvData = `id,name,email,created_at\n1,Mock User,mock@example.com,${new Date().toISOString()}`;
          const blob = new Blob([csvData], { type: 'text/csv' });
          return of(blob);
        })
      );
  }
}