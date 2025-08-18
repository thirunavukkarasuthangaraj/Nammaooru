import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ApiResponse } from '../../../core/models/api-response.model';
import { environment } from '../../../../environments/environment';

export interface DeliveryTracking {
  id: number;
  assignmentId: number;
  orderNumber: string;
  
  // Location Data
  latitude: number;
  longitude: number;
  accuracy?: number;
  altitude?: number;
  speed?: number;
  heading?: number;
  
  // Tracking Details
  trackedAt: Date;
  batteryLevel?: number;
  isMoving: boolean;
  
  // Delivery Information
  estimatedArrivalTime?: Date;
  distanceToDestination?: number;
  
  // Partner Information
  partnerName: string;
  partnerPhone: string;
  vehicleType: string;
  vehicleNumber: string;
  
  // Order Information
  customerName: string;
  customerPhone: string;
  deliveryAddress: string;
  orderStatus: string;
  assignmentStatus: string;
  
  // Route Information
  totalDistance?: number;
  estimatedTimeMinutes?: number;
  isDelayed: boolean;
  
  // Historical Tracking Points
  trackingHistory?: TrackingPoint[];
}

export interface TrackingPoint {
  latitude: number;
  longitude: number;
  trackedAt: Date;
  speed?: number;
  isMoving: boolean;
}

export interface LocationUpdateRequest {
  assignmentId: number;
  latitude: number;
  longitude: number;
  accuracy?: number;
  altitude?: number;
  speed?: number;
  heading?: number;
  trackedAt?: Date;
  batteryLevel?: number;
  isMoving?: boolean;
  estimatedArrivalTime?: Date;
  distanceToDestination?: number;
}

@Injectable({
  providedIn: 'root'
})
export class DeliveryTrackingService {
  private readonly apiUrl = `${environment.apiUrl}/delivery/tracking`;

  constructor(private http: HttpClient) {}

  // Location Updates
  updateLocation(request: LocationUpdateRequest): Observable<ApiResponse<DeliveryTracking>> {
    return this.http.post<ApiResponse<DeliveryTracking>>(`${this.apiUrl}/update-location`, request);
  }

  // Tracking Data Retrieval
  getLatestTracking(assignmentId: number): Observable<ApiResponse<DeliveryTracking>> {
    // Mock data for testing
    const mockTracking: DeliveryTracking = {
      id: 1,
      assignmentId: assignmentId,
      orderNumber: 'ORD-2025-001',
      latitude: 12.9700,
      longitude: 77.5930,
      accuracy: 5,
      speed: 25,
      heading: 45,
      trackedAt: new Date(Date.now() - 120000), // 2 minutes ago
      batteryLevel: 85,
      isMoving: true,
      estimatedArrivalTime: new Date(Date.now() + 900000), // 15 minutes from now
      distanceToDestination: 2.5,
      partnerName: 'Raj Kumar',
      partnerPhone: '+91 9876543210',
      vehicleType: 'BIKE',
      vehicleNumber: 'KA05AB1234',
      customerName: 'Priya Sharma',
      customerPhone: '+91 9123456789',
      deliveryAddress: '123, MG Road, Bangalore, Karnataka 560001',
      orderStatus: 'CONFIRMED',
      assignmentStatus: 'IN_TRANSIT',
      totalDistance: 5.2,
      estimatedTimeMinutes: 15,
      isDelayed: false
    };

    return new Observable(observer => {
      setTimeout(() => {
        observer.next({
          statusCode: 'SUCCESS',
          message: 'Tracking data retrieved successfully',
          data: mockTracking,
          timestamp: new Date().toISOString()
        });
        observer.complete();
      }, 300);
    });
  }

  getTrackingHistory(assignmentId: number): Observable<ApiResponse<DeliveryTracking[]>> {
    // Mock tracking history for testing
    const mockHistory: DeliveryTracking[] = [
      {
        id: 3,
        assignmentId: assignmentId,
        orderNumber: 'ORD-2025-001',
        latitude: 12.9680,
        longitude: 77.5910,
        trackedAt: new Date(Date.now() - 600000), // 10 minutes ago
        isMoving: true,
        partnerName: 'Raj Kumar',
        partnerPhone: '+91 9876543210',
        vehicleType: 'BIKE',
        vehicleNumber: 'KA05AB1234',
        customerName: 'Priya Sharma',
        customerPhone: '+91 9123456789',
        deliveryAddress: '123, MG Road, Bangalore, Karnataka 560001',
        orderStatus: 'CONFIRMED',
        assignmentStatus: 'IN_TRANSIT',
        isDelayed: false
      },
      {
        id: 2,
        assignmentId: assignmentId,
        orderNumber: 'ORD-2025-001',
        latitude: 12.9690,
        longitude: 77.5920,
        trackedAt: new Date(Date.now() - 300000), // 5 minutes ago
        isMoving: true,
        partnerName: 'Raj Kumar',
        partnerPhone: '+91 9876543210',
        vehicleType: 'BIKE',
        vehicleNumber: 'KA05AB1234',
        customerName: 'Priya Sharma',
        customerPhone: '+91 9123456789',
        deliveryAddress: '123, MG Road, Bangalore, Karnataka 560001',
        orderStatus: 'CONFIRMED',
        assignmentStatus: 'IN_TRANSIT',
        isDelayed: false
      }
    ];

    return new Observable(observer => {
      setTimeout(() => {
        observer.next({
          statusCode: 'SUCCESS',
          message: 'Tracking history retrieved successfully',
          data: mockHistory,
          timestamp: new Date().toISOString()
        });
        observer.complete();
      }, 200);
    });
  }

  getTrackingWithHistory(assignmentId: number): Observable<ApiResponse<DeliveryTracking>> {
    return this.http.get<ApiResponse<DeliveryTracking>>(`${this.apiUrl}/assignment/${assignmentId}/full`);
  }

  getTrackingByTimeRange(
    assignmentId: number, 
    startTime: Date, 
    endTime: Date
  ): Observable<ApiResponse<DeliveryTracking[]>> {
    const params = new HttpParams()
      .set('startTime', startTime.toISOString())
      .set('endTime', endTime.toISOString());
    
    return this.http.get<ApiResponse<DeliveryTracking[]>>(
      `${this.apiUrl}/assignment/${assignmentId}/range`, 
      { params }
    );
  }

  getRecentPartnerTracking(partnerId: number, minutes: number = 60): Observable<ApiResponse<DeliveryTracking[]>> {
    const params = new HttpParams().set('minutes', minutes.toString());
    return this.http.get<ApiResponse<DeliveryTracking[]>>(
      `${this.apiUrl}/partner/${partnerId}/recent`, 
      { params }
    );
  }

  // Tracking Analytics
  getTrackingPointCount(assignmentId: number): Observable<ApiResponse<number>> {
    return this.http.get<ApiResponse<number>>(`${this.apiUrl}/assignment/${assignmentId}/count`);
  }

  getLowBatteryAlerts(): Observable<ApiResponse<DeliveryTracking[]>> {
    return this.http.get<ApiResponse<DeliveryTracking[]>>(`${this.apiUrl}/alerts/low-battery`);
  }

  // Partner Status Updates
  updatePartnerOnlineStatus(partnerId: number, isOnline: boolean): Observable<ApiResponse<string>> {
    return this.http.post<ApiResponse<string>>(
      `${this.apiUrl}/partner/${partnerId}/online-status`, 
      { isOnline }
    );
  }

  // Tracking Status Checks
  isPartnerMoving(assignmentId: number): Observable<ApiResponse<boolean>> {
    return this.http.get<ApiResponse<boolean>>(`${this.apiUrl}/assignment/${assignmentId}/is-moving`);
  }

  isTrackingRecent(assignmentId: number, minutes: number = 5): Observable<ApiResponse<boolean>> {
    const params = new HttpParams().set('minutes', minutes.toString());
    return this.http.get<ApiResponse<boolean>>(
      `${this.apiUrl}/assignment/${assignmentId}/is-recent`, 
      { params }
    );
  }

  // Admin Functions
  cleanupOldTrackingData(daysToKeep: number = 30): Observable<ApiResponse<string>> {
    const params = new HttpParams().set('daysToKeep', daysToKeep.toString());
    return this.http.post<ApiResponse<string>>(`${this.apiUrl}/cleanup`, {}, { params });
  }

  // Utility Methods
  formatTrackingTime(date: Date | string): string {
    const trackingDate = new Date(date);
    const now = new Date();
    const diffMs = now.getTime() - trackingDate.getTime();
    const diffMinutes = Math.floor(diffMs / (1000 * 60));
    
    if (diffMinutes < 1) {
      return 'Just now';
    } else if (diffMinutes < 60) {
      return `${diffMinutes} minutes ago`;
    } else if (diffMinutes < 1440) { // 24 hours
      const hours = Math.floor(diffMinutes / 60);
      return `${hours} hour${hours > 1 ? 's' : ''} ago`;
    } else {
      return trackingDate.toLocaleDateString();
    }
  }

  isTrackingDataRecent(trackedAt: Date | string, maxMinutes: number = 5): boolean {
    const trackingDate = new Date(trackedAt);
    const now = new Date();
    const diffMs = now.getTime() - trackingDate.getTime();
    const diffMinutes = diffMs / (1000 * 60);
    return diffMinutes <= maxMinutes;
  }

  calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Radius of the Earth in kilometers
    const dLat = this.toRadians(lat2 - lat1);
    const dLon = this.toRadians(lon2 - lon1);
    
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(this.toRadians(lat1)) * Math.cos(this.toRadians(lat2)) *
              Math.sin(dLon / 2) * Math.sin(dLon / 2);
    
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c;
    
    return Math.round(distance * 100) / 100; // Round to 2 decimal places
  }

  private toRadians(degrees: number): number {
    return degrees * (Math.PI / 180);
  }

  formatDistance(distance: number): string {
    if (distance < 1) {
      return `${Math.round(distance * 1000)}m`;
    }
    return `${distance.toFixed(1)}km`;
  }

  formatSpeed(speed: number): string {
    return `${Math.round(speed)}km/h`;
  }

  formatBatteryLevel(level: number): string {
    return `${level}%`;
  }

  getMovementStatus(isMoving: boolean, speed?: number): string {
    if (!isMoving) return 'Stationary';
    if (!speed) return 'Moving';
    if (speed < 5) return 'Moving slowly';
    if (speed < 20) return 'Moving';
    return 'Moving fast';
  }

  getAccuracyStatus(accuracy: number): string {
    if (accuracy <= 5) return 'High';
    if (accuracy <= 15) return 'Medium';
    return 'Low';
  }

  estimateArrivalTime(
    currentLat: number, 
    currentLng: number, 
    destLat: number, 
    destLng: number, 
    averageSpeed: number = 25
  ): Date {
    const distance = this.calculateDistance(currentLat, currentLng, destLat, destLng);
    const timeHours = distance / averageSpeed;
    const timeMs = timeHours * 60 * 60 * 1000;
    return new Date(Date.now() + timeMs);
  }

  isDelayed(estimatedTime?: Date, bufferMinutes: number = 15): boolean {
    if (!estimatedTime) return false;
    const now = new Date();
    const estimated = new Date(estimatedTime);
    const delayMs = now.getTime() - estimated.getTime() - (bufferMinutes * 60 * 1000);
    return delayMs > 0;
  }
}