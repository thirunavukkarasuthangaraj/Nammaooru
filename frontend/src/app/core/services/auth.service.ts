import { Injectable, Inject, PLATFORM_ID } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { BehaviorSubject, Observable, tap, catchError, throwError, map } from 'rxjs';
import { Router } from '@angular/router';
import { isPlatformBrowser } from '@angular/common';
import { MatSnackBar } from '@angular/material/snack-bar';
import { environment } from '@environments/environment';
import { AuthResponse, LoginRequest, RegisterRequest, User, UserRole } from '../models/auth.model';
import { ApiResponse, ApiResponseHelper } from '../models/api-response.model';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly API_URL = `${environment.apiUrl}/auth`;
  private readonly TOKEN_KEY = 'shop_management_token';
  private readonly USER_KEY = 'shop_management_user';

  private currentUserSubject = new BehaviorSubject<User | null>(this.getCurrentUserFromStorage());
  public currentUser$ = this.currentUserSubject.asObservable();

  constructor(
    private http: HttpClient,
    private router: Router,
    private snackBar: MatSnackBar,
    @Inject(PLATFORM_ID) private platformId: Object
  ) {}

  login(credentials: LoginRequest): Observable<AuthResponse> {
    // Clear any existing auth data first to avoid role conflicts
    this.clearStoredAuth();
    return this.http.post<ApiResponse<AuthResponse>>(`${this.API_URL}/login`, credentials)
      .pipe(
        map(response => {
          // Use ApiResponseHelper to check if response is successful
          if (ApiResponseHelper.isError(response)) {
            const errorMessage = ApiResponseHelper.getErrorMessage(response);
            throw new Error(errorMessage);
          }
          
          // Extract the actual auth data from the ApiResponse format
          return response.data;
        }),
        tap(authData => {
          this.setSession(authData);
          this.showSnackBar('Welcome back! Login successful.', 'success');
        }),
        catchError(error => {
          this.handleAuthError(error);
          return throwError(() => error);
        })
      );
  }

  register(userData: RegisterRequest): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.API_URL}/register`, userData)
      .pipe(
        tap(response => this.setSession(response)),
        catchError(error => {
          this.handleAuthError(error);
          return throwError(() => error);
        })
      );
  }

  // OTP-based forgot password methods
  sendPasswordResetOtp(email: string): Observable<any> {
    return this.http.post<ApiResponse<any>>(`${this.API_URL}/forgot-password/send-otp`, { email })
      .pipe(
        tap(response => {
          if (ApiResponseHelper.isError(response)) {
            const errorMessage = ApiResponseHelper.getErrorMessage(response);
            throw new Error(errorMessage);
          }
        }),
        catchError(error => {
          this.handleAuthError(error);
          return throwError(() => error);
        })
      );
  }

  verifyPasswordResetOtp(email: string, otp: string): Observable<any> {
    return this.http.post<ApiResponse<any>>(`${this.API_URL}/forgot-password/verify-otp`, { email, otp })
      .pipe(
        tap(response => {
          if (ApiResponseHelper.isError(response)) {
            const errorMessage = ApiResponseHelper.getErrorMessage(response);
            throw new Error(errorMessage);
          }
        }),
        catchError(error => {
          this.handleAuthError(error);
          return throwError(() => error);
        })
      );
  }

  resetPasswordWithOtp(email: string, otp: string, newPassword: string): Observable<any> {
    return this.http.post<ApiResponse<any>>(`${this.API_URL}/forgot-password/reset-password`, { 
      email, otp, newPassword 
    })
      .pipe(
        tap(response => {
          if (ApiResponseHelper.isError(response)) {
            const errorMessage = ApiResponseHelper.getErrorMessage(response);
            throw new Error(errorMessage);
          }
        }),
        catchError(error => {
          this.handleAuthError(error);
          return throwError(() => error);
        })
      );
  }

  resendPasswordResetOtp(email: string): Observable<any> {
    return this.http.post<ApiResponse<any>>(`${this.API_URL}/forgot-password/resend-otp`, { email })
      .pipe(
        tap(response => {
          if (ApiResponseHelper.isError(response)) {
            const errorMessage = ApiResponseHelper.getErrorMessage(response);
            throw new Error(errorMessage);
          }
        }),
        catchError(error => {
          this.handleAuthError(error);
          return throwError(() => error);
        })
      );
  }

  // Legacy method (keep for backward compatibility)
  forgotPassword(usernameOrEmail: string): Observable<any> {
    return this.http.post(`${this.API_URL}/password/forgot`, { usernameOrEmail })
      .pipe(
        catchError(error => {
          this.handleAuthError(error);
          return throwError(() => error);
        })
      );
  }

  logout(): void {
    const token = this.getToken();
    
    // Call logout API if token exists
    if (token) {
      this.http.post(`${this.API_URL}/logout`, {}).subscribe({
        next: () => {
          console.log('Logout successful');
        },
        error: (error) => {
          console.error('Logout API error:', error);
          // Continue with local logout even if API fails
        },
        complete: () => {
          this.performLocalLogout();
        }
      });
    } else {
      this.performLocalLogout();
    }
  }
  
  private performLocalLogout(): void {
    this.clearStoredAuth();
    this.currentUserSubject.next(null);
    this.router.navigate(['/auth/login'], { replaceUrl: true });
    this.showSnackBar('You have been logged out successfully.', 'info');
  }

  getToken(): string | null {
    if (isPlatformBrowser(this.platformId)) {
      return localStorage.getItem(this.TOKEN_KEY);
    }
    return null;
  }

  getCurrentUser(): User | null {
    return this.currentUserSubject.value;
  }

  isAuthenticated(): boolean {
    const token = this.getToken();
    if (!token) {
      return false;
    }

    // Check if token is expired
    try {
      const tokenPayload = JSON.parse(atob(token.split('.')[1]));
      const currentTime = Date.now() / 1000;
      return tokenPayload.exp > currentTime;
    } catch (error) {
      return false;
    }
  }
  
  private setMockUserIfNeeded(): void {
    if (!this.getCurrentUser()) {
      // Set a mock super admin user for testing
      const mockUser: User = {
        id: 1,
        username: 'admin',
        email: 'admin@shop.com',
        role: UserRole.SUPER_ADMIN,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      
      if (isPlatformBrowser(this.platformId)) {
        localStorage.setItem(this.USER_KEY, JSON.stringify(mockUser));
        localStorage.setItem(this.TOKEN_KEY, 'mock-token-for-testing');
      }
      this.currentUserSubject.next(mockUser);
    }
  }

  hasRole(role: UserRole): boolean {
    const user = this.getCurrentUser();
    return user?.role === role;
  }

  hasAnyRole(roles: UserRole[]): boolean {
    const user = this.getCurrentUser();
    return user ? roles.includes(user.role) : false;
  }

  isSuperAdmin(): boolean {
    return this.hasRole(UserRole.SUPER_ADMIN);
  }

  isAdmin(): boolean {
    return this.hasAnyRole([UserRole.SUPER_ADMIN, UserRole.ADMIN]);
  }

  isShopOwner(): boolean {
    return this.hasRole(UserRole.SHOP_OWNER);
  }

  canManageShops(): boolean {
    return this.hasAnyRole([UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.SHOP_OWNER]);
  }

  changePassword(request: { currentPassword: string; newPassword: string; confirmPassword: string }): Observable<any> {
    return this.http.post(`${this.API_URL}/change-password`, request)
      .pipe(
        tap(() => {
          // Clear password status after successful change
          if (isPlatformBrowser(this.platformId)) {
            localStorage.removeItem('passwordChangeRequired');
            localStorage.removeItem('isTemporaryPassword');
          }
        }),
        catchError(error => {
          this.handleAuthError(error);
          return throwError(() => error);
        })
      );
  }

  getPasswordStatus(): Observable<{ isTemporaryPassword: boolean; passwordChangeRequired: boolean; lastPasswordChange?: Date }> {
    return this.http.get<{ isTemporaryPassword: boolean; passwordChangeRequired: boolean; lastPasswordChange?: Date }>(`${this.API_URL}/password-status`)
      .pipe(
        catchError(error => {
          this.handleAuthError(error);
          return throwError(() => error);
        })
      );
  }

  private setSession(authResponse: AuthResponse): void {
    if (isPlatformBrowser(this.platformId)) {
      localStorage.setItem(this.TOKEN_KEY, authResponse.accessToken);
      
      const user: User = {
        id: 0, // Will be updated from backend if needed
        username: authResponse.username,
        email: authResponse.email,
        role: authResponse.role as UserRole,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
      };

      localStorage.setItem(this.USER_KEY, JSON.stringify(user));
      
      // Store password status for use in components
      if (authResponse.passwordChangeRequired || authResponse.isTemporaryPassword) {
        localStorage.setItem('passwordChangeRequired', 'true');
        localStorage.setItem('isTemporaryPassword', authResponse.isTemporaryPassword ? 'true' : 'false');
      }
      
      this.currentUserSubject.next(user);
    }
  }

  isPasswordChangeRequired(): boolean {
    if (isPlatformBrowser(this.platformId)) {
      return localStorage.getItem('passwordChangeRequired') === 'true';
    }
    return false;
  }

  isTemporaryPassword(): boolean {
    if (isPlatformBrowser(this.platformId)) {
      return localStorage.getItem('isTemporaryPassword') === 'true';
    }
    return false;
  }

  private getCurrentUserFromStorage(): User | null {
    if (isPlatformBrowser(this.platformId)) {
      const userData = localStorage.getItem(this.USER_KEY);
      if (userData) {
        try {
          return JSON.parse(userData);
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }
  
  private getMockUser(): User {
    return {
      id: 1,
      username: 'admin',
      email: 'admin@shop.com',
      role: UserRole.SUPER_ADMIN,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date()
    };
  }

  private clearStoredAuth(): void {
    if (isPlatformBrowser(this.platformId)) {
      localStorage.removeItem(this.TOKEN_KEY);
      localStorage.removeItem(this.USER_KEY);
      localStorage.removeItem('passwordChangeRequired');
      localStorage.removeItem('isTemporaryPassword');
    }
  }

  private handleAuthError(error: HttpErrorResponse): void {
    let errorMessage = 'An error occurred during authentication.';
    
    if (error.error?.message) {
      errorMessage = error.error.message;
    } else if (error.status === 401) {
      errorMessage = 'Invalid credentials. Please try again.';
    } else if (error.status === 403) {
      errorMessage = 'Access denied. Please contact support.';
    }

    this.showSnackBar(errorMessage, 'error');
  }

  private showSnackBar(message: string, type: 'success' | 'error' | 'warning' | 'info'): void {
    this.snackBar.open(message, 'Close', {
      duration: 5000,
      horizontalPosition: 'end',
      verticalPosition: 'top',
      panelClass: [`${type}-snackbar`]
    });
  }
}