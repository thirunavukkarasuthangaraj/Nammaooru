import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';
import { ApiResponse, ApiResponseHelper } from '../../../core/models/api-response.model';

export interface DeliveryLocation {
  id?: number;
  addressType: string;        // Home, Work, Other
  flatHouse: string;
  floor: string;
  street: string;
  area: string;
  village: string;
  landmark: string;
  city: string;
  state: string;
  pincode: string;
  latitude?: number;
  longitude?: number;
  isDefault: boolean;
  contactPersonName: string;
  contactMobileNumber: string;
}

@Injectable({
  providedIn: 'root'
})
export class AddressService {
  private apiUrl = `${environment.apiUrl}/customer/delivery-locations`;

  constructor(private http: HttpClient) {}

  /**
   * Get all delivery addresses for the current customer
   */
  getAddresses(): Observable<DeliveryLocation[]> {
    return this.http.get<ApiResponse<DeliveryLocation[]>>(this.apiUrl).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          const errorMessage = ApiResponseHelper.getErrorMessage(response);
          throw new Error(errorMessage);
        }
        return response.data;
      }),
      catchError(error => {
        console.error('Error fetching addresses:', error);
        return of([]);
      })
    );
  }

  /**
   * Add a new delivery address
   */
  addAddress(address: DeliveryLocation): Observable<DeliveryLocation> {
    return this.http.post<ApiResponse<DeliveryLocation>>(this.apiUrl, address).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          const errorMessage = ApiResponseHelper.getErrorMessage(response);
          throw new Error(errorMessage);
        }
        return response.data;
      }),
      catchError(error => {
        console.error('Error adding address:', error);
        throw error;
      })
    );
  }

  /**
   * Update an existing delivery address
   */
  updateAddress(id: number, address: DeliveryLocation): Observable<DeliveryLocation> {
    return this.http.put<ApiResponse<DeliveryLocation>>(`${this.apiUrl}/${id}`, address).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          const errorMessage = ApiResponseHelper.getErrorMessage(response);
          throw new Error(errorMessage);
        }
        return response.data;
      }),
      catchError(error => {
        console.error('Error updating address:', error);
        throw error;
      })
    );
  }

  /**
   * Delete a delivery address
   */
  deleteAddress(id: number): Observable<void> {
    return this.http.delete<ApiResponse<void>>(`${this.apiUrl}/${id}`).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          const errorMessage = ApiResponseHelper.getErrorMessage(response);
          throw new Error(errorMessage);
        }
        return;
      }),
      catchError(error => {
        console.error('Error deleting address:', error);
        throw error;
      })
    );
  }

  /**
   * Set an address as default
   */
  setDefaultAddress(id: number): Observable<DeliveryLocation> {
    return this.http.put<ApiResponse<DeliveryLocation>>(`${this.apiUrl}/${id}/set-default`, {}).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          const errorMessage = ApiResponseHelper.getErrorMessage(response);
          throw new Error(errorMessage);
        }
        return response.data;
      }),
      catchError(error => {
        console.error('Error setting default address:', error);
        throw error;
      })
    );
  }
}
