import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, map, catchError, throwError } from 'rxjs';
import { environment } from '../../../environments/environment';
import { ApiResponse, ApiResponseHelper } from '../models/api-response.model';

export interface UserResponse {
  id: number;
  username: string;
  email: string;
  firstName: string;
  lastName: string;
  fullName: string;
  mobileNumber: string;
  role: string;
  status: string;
  profileImageUrl: string;
  lastLogin: string;
  failedLoginAttempts: number;
  accountLockedUntil: string;
  emailVerified: boolean;
  mobileVerified: boolean;
  twoFactorEnabled: boolean;
  department: string;
  designation: string;
  reportsTo: number;
  reportsToName: string;
  permissions: PermissionResponse[];
  isActive: boolean;
  isTemporaryPassword: boolean;
  passwordChangeRequired: boolean;
  lastPasswordChange: string;
  createdAt: string;
  updatedAt: string;
  createdBy: string;
  updatedBy: string;
  roleLabel: string;
  statusLabel: string;
  isLocked: boolean;
  isAdmin: boolean;
  assignedShopIds: number[];
  accountAge: string;
  lastLoginFormatted: string;
}

export interface PermissionResponse {
  id: number;
  name: string;
  description: string;
  category: string;
  resourceType: string;
  actionType: string;
}

export interface UserRequest {
  username: string;
  email: string;
  password?: string;
  firstName: string;
  lastName: string;
  mobileNumber?: string;
  role: string;
  status?: string;
  profileImageUrl?: string;
  department?: string;
  designation?: string;
  reportsTo?: number;
  permissionIds?: number[];
  emailVerified?: boolean;
  mobileVerified?: boolean;
  twoFactorEnabled?: boolean;
  passwordChangeRequired?: boolean;
}

export interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
}

@Injectable({
  providedIn: 'root'
})
export class UserService {
  private apiUrl = `${environment.apiUrl}/users`;

  constructor(private http: HttpClient) {}

  getAllUsers(page: number = 0, size: number = 10, sortBy: string = 'firstName', sortDirection: string = 'asc'): Observable<PageResponse<UserResponse>> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString())
      .set('sortBy', sortBy)
      .set('sortDirection', sortDirection);

    return this.http.get<ApiResponse<any>>(this.apiUrl, { params }).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        // Backend now returns paginated data in response.data
        const paginatedData = response.data;
        return {
          content: paginatedData.content || paginatedData.items || [],
          totalElements: paginatedData.totalItems || paginatedData.totalElements || 0,
          totalPages: paginatedData.totalPages || 0,
          size: paginatedData.pageSize || paginatedData.size || size,
          number: paginatedData.currentPage || paginatedData.number || page
        };
      }),
      catchError(error => throwError(() => error))
    );
  }

  getUserById(id: number): Observable<UserResponse> {
    return this.http.get<ApiResponse<UserResponse>>(`${this.apiUrl}/${id}`).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }

  getUserByUsername(username: string): Observable<UserResponse> {
    return this.http.get<ApiResponse<UserResponse>>(`${this.apiUrl}/username/${username}`).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }

  getUserByEmail(email: string): Observable<UserResponse> {
    return this.http.get<ApiResponse<UserResponse>>(`${this.apiUrl}/email/${email}`).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }

  createUser(user: UserRequest): Observable<UserResponse> {
    return this.http.post<ApiResponse<UserResponse>>(this.apiUrl, user).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }

  updateUser(id: number, user: UserRequest): Observable<UserResponse> {
    return this.http.put<ApiResponse<UserResponse>>(`${this.apiUrl}/${id}`, user).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }

  deleteUser(id: number): Observable<void> {
    return this.http.delete<ApiResponse<void>>(`${this.apiUrl}/${id}`).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }

  toggleUserStatus(id: number): Observable<UserResponse> {
    return this.http.put<ApiResponse<UserResponse>>(`${this.apiUrl}/${id}/toggle-status`, {}).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }

  lockUser(id: number, reason: string): Observable<UserResponse> {
    const params = new HttpParams().set('reason', reason);
    return this.http.put<ApiResponse<UserResponse>>(`${this.apiUrl}/${id}/lock`, {}, { params }).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }

  unlockUser(id: number): Observable<UserResponse> {
    return this.http.put<ApiResponse<UserResponse>>(`${this.apiUrl}/${id}/unlock`, {}).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }

  resetPassword(id: number): Observable<void> {
    return this.http.post<ApiResponse<void>>(`${this.apiUrl}/${id}/reset-password`, {}).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }

  getUsersByRole(role: string, page: number = 0, size: number = 10): Observable<PageResponse<UserResponse>> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/role/${role}`, { params }).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        const paginatedData = response.data;
        return {
          content: paginatedData.content || paginatedData.items || [],
          totalElements: paginatedData.totalItems || paginatedData.totalElements || 0,
          totalPages: paginatedData.totalPages || 0,
          size: paginatedData.pageSize || paginatedData.size || size,
          number: paginatedData.currentPage || paginatedData.number || page
        };
      }),
      catchError(error => throwError(() => error))
    );
  }

  getUsersByStatus(status: string, page: number = 0, size: number = 10): Observable<PageResponse<UserResponse>> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/status/${status}`, { params }).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        const paginatedData = response.data;
        return {
          content: paginatedData.content || paginatedData.items || [],
          totalElements: paginatedData.totalItems || paginatedData.totalElements || 0,
          totalPages: paginatedData.totalPages || 0,
          size: paginatedData.pageSize || paginatedData.size || size,
          number: paginatedData.currentPage || paginatedData.number || page
        };
      }),
      catchError(error => throwError(() => error))
    );
  }

  getUsersByDepartment(department: string, page: number = 0, size: number = 10): Observable<PageResponse<UserResponse>> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/department/${department}`, { params }).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        const paginatedData = response.data;
        return {
          content: paginatedData.content || paginatedData.items || [],
          totalElements: paginatedData.totalItems || paginatedData.totalElements || 0,
          totalPages: paginatedData.totalPages || 0,
          size: paginatedData.pageSize || paginatedData.size || size,
          number: paginatedData.currentPage || paginatedData.number || page
        };
      }),
      catchError(error => throwError(() => error))
    );
  }

  searchUsers(searchTerm: string, page: number = 0, size: number = 10): Observable<PageResponse<UserResponse>> {
    const params = new HttpParams()
      .set('searchTerm', searchTerm)
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/search`, { params }).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        const paginatedData = response.data;
        return {
          content: paginatedData.content || paginatedData.items || [],
          totalElements: paginatedData.totalItems || paginatedData.totalElements || 0,
          totalPages: paginatedData.totalPages || 0,
          size: paginatedData.pageSize || paginatedData.size || size,
          number: paginatedData.currentPage || paginatedData.number || page
        };
      }),
      catchError(error => throwError(() => error))
    );
  }

  getSubordinates(managerId: number): Observable<UserResponse[]> {
    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/${managerId}/subordinates`).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data.items || response.data || [];
      }),
      catchError(error => throwError(() => error))
    );
  }

  assignDriverToShop(userId: number, shopId: number): Observable<UserResponse> {
    return this.http.put<ApiResponse<UserResponse>>(`${this.apiUrl}/${userId}/assign-shop/${shopId}`, {}).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }

  unassignDriverFromShop(userId: number): Observable<UserResponse> {
    return this.http.put<ApiResponse<UserResponse>>(`${this.apiUrl}/${userId}/unassign-shop`, {}).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }

  getUserRoles(): Observable<any> {
    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/roles`).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }
}