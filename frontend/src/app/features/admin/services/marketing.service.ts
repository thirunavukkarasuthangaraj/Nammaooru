import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

export interface MarketingMessageRequest {
  templateName: string;
  messageParam: string;
  messageParam2?: string; // Optional second parameter for templates that need it
  imageUrl?: string; // Optional image URL for templates with image headers
  targetAudience: string;
}

export interface MarketingMessageResponse {
  success: boolean;
  message: string;
  totalCustomers: number;
  successCount: number;
  failureCount: number;
  templateUsed: string;
  messageParam: string;
}

export interface TemplateInfo {
  templateName: string;
  displayName: string;
  description: string;
  parameterDescription: string;
}

export interface MarketingStats {
  totalCustomers: number;
  activeCustomers: number;
  smsEnabledCustomers: number;
  customersWithMobile: number;
  eligibleForMarketing: number;
}

@Injectable({
  providedIn: 'root'
})
export class MarketingService {
  private apiUrl = `${environment.apiUrl}/marketing`;

  constructor(private http: HttpClient) { }

  /**
   * Send bulk marketing messages
   */
  sendBulkMarketingMessage(request: MarketingMessageRequest): Observable<MarketingMessageResponse> {
    return this.http.post<MarketingMessageResponse>(`${this.apiUrl}/send-bulk`, request);
  }

  /**
   * Get available marketing templates
   */
  getAvailableTemplates(): Observable<TemplateInfo[]> {
    return this.http.get<TemplateInfo[]>(`${this.apiUrl}/templates`);
  }

  /**
   * Get marketing statistics
   */
  getMarketingStats(): Observable<MarketingStats> {
    return this.http.get<MarketingStats>(`${this.apiUrl}/stats`);
  }
}
