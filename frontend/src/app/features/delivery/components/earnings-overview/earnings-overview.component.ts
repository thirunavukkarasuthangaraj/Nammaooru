import { Component, OnInit, Input } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { AuthService } from '../../../../core/services/auth.service';
import { environment } from '../../../../../environments/environment';

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
  totalDeliveries = 0;
  isLoading = true;

  constructor(
    private http: HttpClient,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    if (!this.partnerId) {
      const user = this.authService.getCurrentUser();
      if (user) {
        this.partnerId = user.id;
      }
    }
    this.loadEarningsData();
  }

  private loadEarningsData(): void {
    if (!this.partnerId) {
      this.isLoading = false;
      return;
    }

    this.http.get<any>(`${environment.apiUrl}/mobile/delivery-partner/earnings/${this.partnerId}`)
      .subscribe({
        next: (response) => {
          if (response.success) {
            this.todayEarnings = response.todayEarnings || 0;
            this.weeklyEarnings = response.weeklyEarnings || 0;
            this.monthlyEarnings = response.monthlyEarnings || 0;
            this.totalEarnings = response.totalEarnings || 0;
            this.totalDeliveries = response.totalDeliveries || 0;
          }
          this.isLoading = false;
        },
        error: (error) => {
          console.error('Error loading earnings:', error);
          this.isLoading = false;
        }
      });
  }
}
