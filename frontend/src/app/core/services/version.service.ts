import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class VersionService {

  private apiUrl = `${environment.apiUrl}/version`;

  constructor(private http: HttpClient) { }

  getVersion(): string {
    return `v${environment.version}`;
  }

  getBuildDate(): string {
    if (environment.buildDate) {
      return new Date(environment.buildDate).toLocaleDateString('en-US', { 
        year: 'numeric', 
        month: 'short', 
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    }
    return new Date().toLocaleDateString('en-US', { 
      year: 'numeric', 
      month: 'short', 
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  getServerVersion(): Observable<any> {
    return this.http.get<any>(this.apiUrl).pipe(
      catchError(error => {
        console.error('Error fetching server version:', error);
        return of({ version: 'Unknown', name: 'Server' });
      })
    );
  }

  getVersionInfo(): Observable<{client: string, server: any}> {
    return new Observable(observer => {
      const clientVersion = this.getVersion();
      this.getServerVersion().subscribe(serverInfo => {
        observer.next({
          client: clientVersion,
          server: serverInfo
        });
        observer.complete();
      });
    });
  }
}