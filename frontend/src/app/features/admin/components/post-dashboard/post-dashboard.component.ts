import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { PostDashboardService } from '../../services/post-dashboard.service';

interface PostStats {
  total: number;
  pending: number;
  approved: number;
  rejected: number;
  reported: number;
}

@Component({
  selector: 'app-post-dashboard',
  templateUrl: './post-dashboard.component.html',
  styleUrls: ['./post-dashboard.component.scss']
})
export class PostDashboardComponent implements OnInit {
  labourStats: PostStats = { total: 0, pending: 0, approved: 0, rejected: 0, reported: 0 };
  travelStats: PostStats = { total: 0, pending: 0, approved: 0, rejected: 0, reported: 0 };
  parcelStats: PostStats = { total: 0, pending: 0, approved: 0, rejected: 0, reported: 0 };
  isLoading = true;
  errorMessage = '';

  constructor(
    private dashboardService: PostDashboardService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadStats();
  }

  loadStats(): void {
    this.isLoading = true;
    this.errorMessage = '';
    this.dashboardService.getStats().subscribe({
      next: (response: any) => {
        const data = response.data || response;
        this.labourStats = data.labour || this.labourStats;
        this.travelStats = data.travel || this.travelStats;
        this.parcelStats = data.parcel || this.parcelStats;
        this.isLoading = false;
      },
      error: (err) => {
        this.errorMessage = 'Failed to load dashboard stats';
        this.isLoading = false;
        console.error('Dashboard stats error:', err);
      }
    });
  }

  navigateTo(route: string): void {
    this.router.navigate([route]);
  }
}
