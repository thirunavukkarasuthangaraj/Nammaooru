import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

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

    return this.http.get<PageResponse<UserResponse>>(this.apiUrl, { params });
  }

  getUserById(id: number): Observable<UserResponse> {
    return this.http.get<UserResponse>(`${this.apiUrl}/${id}`);
  }

  getUserByUsername(username: string): Observable<UserResponse> {
    return this.http.get<UserResponse>(`${this.apiUrl}/username/${username}`);
  }

  getUserByEmail(email: string): Observable<UserResponse> {
    return this.http.get<UserResponse>(`${this.apiUrl}/email/${email}`);
  }

  createUser(user: UserRequest): Observable<UserResponse> {
    return this.http.post<UserResponse>(this.apiUrl, user);
  }

  updateUser(id: number, user: UserRequest): Observable<UserResponse> {
    return this.http.put<UserResponse>(`${this.apiUrl}/${id}`, user);
  }

  deleteUser(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }

  toggleUserStatus(id: number): Observable<UserResponse> {
    return this.http.put<UserResponse>(`${this.apiUrl}/${id}/toggle-status`, {});
  }

  lockUser(id: number, reason: string): Observable<UserResponse> {
    const params = new HttpParams().set('reason', reason);
    return this.http.put<UserResponse>(`${this.apiUrl}/${id}/lock`, {}, { params });
  }

  unlockUser(id: number): Observable<UserResponse> {
    return this.http.put<UserResponse>(`${this.apiUrl}/${id}/unlock`, {});
  }

  resetPassword(id: number): Observable<void> {
    return this.http.post<void>(`${this.apiUrl}/${id}/reset-password`, {});
  }

  getUsersByRole(role: string, page: number = 0, size: number = 10): Observable<PageResponse<UserResponse>> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<PageResponse<UserResponse>>(`${this.apiUrl}/role/${role}`, { params });
  }

  getUsersByStatus(status: string, page: number = 0, size: number = 10): Observable<PageResponse<UserResponse>> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<PageResponse<UserResponse>>(`${this.apiUrl}/status/${status}`, { params });
  }

  getUsersByDepartment(department: string, page: number = 0, size: number = 10): Observable<PageResponse<UserResponse>> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<PageResponse<UserResponse>>(`${this.apiUrl}/department/${department}`, { params });
  }

  searchUsers(searchTerm: string, page: number = 0, size: number = 10): Observable<PageResponse<UserResponse>> {
    const params = new HttpParams()
      .set('searchTerm', searchTerm)
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<PageResponse<UserResponse>>(`${this.apiUrl}/search`, { params });
  }

  getSubordinates(managerId: number): Observable<UserResponse[]> {
    return this.http.get<UserResponse[]>(`${this.apiUrl}/${managerId}/subordinates`);
  }

  getUserRoles(): Observable<any> {
    return this.http.get(`${this.apiUrl}/roles`);
  }
}