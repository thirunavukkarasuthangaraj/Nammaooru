import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-metric-card',
  templateUrl: './metric-card.component.html',
  styleUrls: ['./metric-card.component.scss']
})
export class MetricCardComponent {
  @Input() title: string = '';
  @Input() value: string = '';
  @Input() icon: string = '';
  @Input() color: 'primary' | 'accent' | 'warn' = 'primary';
  @Input() growth: number | null = null;

  get isPositiveGrowth(): boolean {
    return this.growth !== null && this.growth > 0;
  }

  get isNegativeGrowth(): boolean {
    return this.growth !== null && this.growth < 0;
  }

  get growthIcon(): string {
    if (this.isPositiveGrowth) return 'trending_up';
    if (this.isNegativeGrowth) return 'trending_down';
    return 'trending_flat';
  }

  get growthColor(): string {
    if (this.isPositiveGrowth) return 'success';
    if (this.isNegativeGrowth) return 'error';
    return 'neutral';
  }
}