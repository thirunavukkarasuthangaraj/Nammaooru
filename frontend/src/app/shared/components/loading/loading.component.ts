import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-loading',
  template: `
    <div class="loading-container" [style.height.px]="height">
      <div class="loading-content">
        <mat-spinner [diameter]="diameter" [strokeWidth]="strokeWidth"></mat-spinner>
        <p *ngIf="message" class="loading-message">{{message}}</p>
      </div>
    </div>
  `,
  styles: [`
    .loading-container {
      display: flex;
      justify-content: center;
      align-items: center;
      width: 100%;
      min-height: 200px;
    }

    .loading-content {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
    }

    .loading-message {
      margin: 0;
      color: #666;
      font-size: 14px;
      text-align: center;
    }
  `]
})
export class LoadingComponent {
  @Input() message: string = '';
  @Input() diameter: number = 40;
  @Input() strokeWidth: number = 4;
  @Input() height: number = 200;
}