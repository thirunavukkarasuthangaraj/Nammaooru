import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-product-stats-card',
  template: `
    <mat-card class="stats-card" [class]="'stats-' + color">
      <mat-card-content>
        <div class="stats-content">
          <div class="stats-icon">
            <mat-icon [style.color]="iconColor">{{ icon }}</mat-icon>
          </div>
          <div class="stats-info">
            <div class="stats-value">
              <span *ngIf="!loading">{{ formattedValue }}</span>
              <mat-spinner *ngIf="loading" diameter="20"></mat-spinner>
            </div>
            <div class="stats-title">{{ title }}</div>
          </div>
        </div>
      </mat-card-content>
    </mat-card>
  `,
  styles: [`
    .stats-card {
      cursor: pointer;
      transition: transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out;
    }

    .stats-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    }

    .stats-content {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .stats-icon {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 48px;
      height: 48px;
      border-radius: 12px;
      background: rgba(0,0,0,0.05);
    }

    .stats-icon mat-icon {
      font-size: 24px;
      height: 24px;
      width: 24px;
    }

    .stats-info {
      flex: 1;
    }

    .stats-value {
      font-size: 24px;
      font-weight: 600;
      line-height: 1.2;
      margin-bottom: 4px;
      min-height: 32px;
      display: flex;
      align-items: center;
    }

    .stats-title {
      color: #666;
      font-size: 14px;
      font-weight: 500;
    }

    .stats-primary .stats-icon {
      background: rgba(63, 81, 181, 0.1);
    }

    .stats-primary .stats-value {
      color: #3f51b5;
    }

    .stats-accent .stats-icon {
      background: rgba(255, 64, 129, 0.1);
    }

    .stats-accent .stats-value {
      color: #ff4081;
    }

    .stats-warn .stats-icon {
      background: rgba(255, 152, 0, 0.1);
    }

    .stats-warn .stats-value {
      color: #ff9800;
    }

    @media (max-width: 768px) {
      .stats-content {
        gap: 12px;
      }

      .stats-icon {
        width: 40px;
        height: 40px;
      }

      .stats-icon mat-icon {
        font-size: 20px;
        height: 20px;
        width: 20px;
      }

      .stats-value {
        font-size: 20px;
      }

      .stats-title {
        font-size: 12px;
      }
    }
  `]
})
export class ProductStatsCardComponent {
  @Input() title = '';
  @Input() value: number | string = 0;
  @Input() icon = 'info';
  @Input() color: 'primary' | 'accent' | 'warn' = 'primary';
  @Input() loading = false;

  get formattedValue(): string {
    if (typeof this.value === 'number') {
      return this.value.toLocaleString();
    }
    return this.value.toString();
  }

  get iconColor(): string {
    switch (this.color) {
      case 'primary':
        return '#3f51b5';
      case 'accent':
        return '#ff4081';
      case 'warn':
        return '#ff9800';
      default:
        return '#3f51b5';
    }
  }
}