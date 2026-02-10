import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-partner-placeholder',
  template: `
    <div class="placeholder-container">
      <div class="placeholder-card">
        <mat-icon class="placeholder-icon">{{ icon }}</mat-icon>
        <h2>{{ title }}</h2>
        <p>This feature is coming soon!</p>
        <button mat-raised-button color="primary" routerLink="/delivery/partner/orders">
          <mat-icon>arrow_back</mat-icon>
          Back to My Orders
        </button>
      </div>
    </div>
  `,
  styles: [`
    .placeholder-container {
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 60vh;
      padding: 24px;
    }
    .placeholder-card {
      text-align: center;
      padding: 48px;
      background: white;
      border-radius: 16px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      max-width: 400px;
    }
    .placeholder-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      color: #667eea;
      margin-bottom: 16px;
    }
    h2 {
      margin: 0 0 8px;
      color: #333;
    }
    p {
      color: #666;
      margin: 0 0 24px;
    }
  `]
})
export class PartnerPlaceholderComponent implements OnInit {
  title = '';
  icon = 'construction';

  constructor(private router: Router) {}

  ngOnInit(): void {
    const url = this.router.url;
    if (url.includes('performance')) {
      this.title = 'Performance';
      this.icon = 'trending_up';
    } else if (url.includes('profile')) {
      this.title = 'Profile';
      this.icon = 'person';
    } else if (url.includes('vehicle')) {
      this.title = 'Vehicle Info';
      this.icon = 'two_wheeler';
    } else if (url.includes('help')) {
      this.title = 'Help Center';
      this.icon = 'help';
    } else if (url.includes('emergency')) {
      this.title = 'Emergency';
      this.icon = 'emergency';
    } else {
      this.title = 'Coming Soon';
      this.icon = 'construction';
    }
  }
}
