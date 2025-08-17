import { Component, OnInit, Input } from '@angular/core';

@Component({
  selector: 'app-earnings-overview',
  templateUrl: './earnings-overview.component.html',
  styleUrls: ['./earnings-overview.component.scss']
})
export class EarningsOverviewComponent implements OnInit {
  @Input() partnerId?: number;
  @Input() totalEarnings = 0;
  
  todayEarnings = 0;
  weeklyEarnings = 0;
  monthlyEarnings = 0;

  constructor() {}

  ngOnInit(): void {
    this.loadEarningsData();
  }

  private loadEarningsData(): void {
    // Mock data - replace with actual service call
    this.totalEarnings = 15420;
    this.todayEarnings = 850;
    this.weeklyEarnings = 4200;
    this.monthlyEarnings = 12500;
  }
}