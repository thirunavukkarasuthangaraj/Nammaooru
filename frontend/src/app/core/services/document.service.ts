import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpEvent, HttpEventType } from '@angular/common/http';
import { Observable, map, catchError, throwError } from 'rxjs';
import { environment } from '../../../environments/environment';
import { ShopDocument, DocumentType, DocumentVerificationRequest, DocumentVerificationStatus } from '../models/shop.model';
import { ApiResponse, ApiResponseHelper } from '../models/api-response.model';

@Injectable({
  providedIn: 'root'
})
export class DocumentService {
  private apiUrl = `${environment.apiUrl}/documents`;

  constructor(private http: HttpClient) { }

  getShopDocuments(shopId: number): Observable<ShopDocument[]> {
    return this.http.get<ApiResponse<ShopDocument[]>>(`${this.apiUrl}/shop/${shopId}`).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }

  uploadDocument(
    shopId: number, 
    documentType: DocumentType, 
    documentName: string, 
    file: File
  ): Observable<any> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('documentType', documentType);
    formData.append('documentName', documentName);

    return this.http.post<ShopDocument>(`${this.apiUrl}/shop/${shopId}/upload`, formData, {
      reportProgress: true,
      observe: 'events'
    }).pipe(
      map(event => {
        if (event.type === HttpEventType.UploadProgress) {
          const progress = event.total ? Math.round(100 * event.loaded / event.total) : 0;
          return { type: 'progress', progress };
        } else if (event.type === HttpEventType.Response) {
          return { type: 'complete', data: event.body };
        }
        return { type: 'start' };
      })
    );
  }

  verifyDocument(documentId: number, request: DocumentVerificationRequest): Observable<ShopDocument> {
    return this.http.put<ApiResponse<ShopDocument>>(`${this.apiUrl}/${documentId}/verify`, request).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }

  downloadDocument(documentId: number): Observable<Blob> {
    return this.http.get(`${this.apiUrl}/${documentId}/download`, { 
      responseType: 'blob' 
    });
  }

  deleteDocument(documentId: number): Observable<any> {
    return this.http.delete<ApiResponse<any>>(`${this.apiUrl}/${documentId}`).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }

  getDocumentTypes(): Observable<any> {
    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/types`).pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          throw new Error(ApiResponseHelper.getErrorMessage(response));
        }
        return response.data;
      }),
      catchError(error => throwError(() => error))
    );
  }

  getRequiredDocuments(businessType: string): DocumentType[] {
    const allShopsRequired: DocumentType[] = [
      DocumentType.BUSINESS_LICENSE,
      DocumentType.GST_CERTIFICATE,
      DocumentType.PAN_CARD,
      DocumentType.AADHAR_CARD,
      DocumentType.ADDRESS_PROOF,
      DocumentType.OWNER_PHOTO,
      DocumentType.SHOP_PHOTO
    ];

    if (businessType === 'RESTAURANT') {
      allShopsRequired.push(DocumentType.FOOD_LICENSE);
      allShopsRequired.push(DocumentType.FSSAI_CERTIFICATE);
    } else if (businessType === 'GROCERY') {
      allShopsRequired.push(DocumentType.FSSAI_CERTIFICATE);
    } else if (businessType === 'PHARMACY') {
      allShopsRequired.push(DocumentType.DRUG_LICENSE);
    }

    return allShopsRequired;
  }

  getDocumentDisplayName(documentType: DocumentType): string {
    const displayNames = {
      [DocumentType.BUSINESS_LICENSE]: 'Business License',
      [DocumentType.GST_CERTIFICATE]: 'GST Registration Certificate',
      [DocumentType.PAN_CARD]: 'PAN Card',
      [DocumentType.AADHAR_CARD]: 'Aadhar Card',
      [DocumentType.BANK_STATEMENT]: 'Bank Account Statement',
      [DocumentType.ADDRESS_PROOF]: 'Address Proof',
      [DocumentType.OWNER_PHOTO]: 'Owner Photo',
      [DocumentType.SHOP_PHOTO]: 'Shop Photo',
      [DocumentType.FOOD_LICENSE]: 'Food Safety License',
      [DocumentType.FSSAI_CERTIFICATE]: 'FSSAI Food Safety Certificate',
      [DocumentType.DRUG_LICENSE]: 'Drug License',
      [DocumentType.TRADE_LICENSE]: 'Trade License',
      [DocumentType.OTHER]: 'Other Document'
    };
    return displayNames[documentType] || documentType;
  }
}