import { Component } from '@angular/core';

@Component({
  selector: 'app-unauthorized',
  template: `
    <div class="unauthorized-container">
      <mat-card>
        <mat-card-header>
          <mat-card-title>
            <mat-icon color="warn">warning</mat-icon>
            Access Denied
          </mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <p>You don't have permission to access this resource.</p>
        </mat-card-content>
        <mat-card-actions>
          <button mat-button routerLink="/shops">Go to Shops</button>
        </mat-card-actions>
      </mat-card>
    </div>
  `,
  styles: [`
    .unauthorized-container {
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 50vh;
      padding: 20px;
    }
    
    mat-card {
      text-align: center;
      max-width: 400px;
    }
    
    mat-card-title {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
    }
  `]
})
export class UnauthorizedComponent { }