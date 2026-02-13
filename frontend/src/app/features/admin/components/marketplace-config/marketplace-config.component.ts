import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { MatSnackBar } from '@angular/material/snack-bar';
import { environment } from '../../../../../environments/environment';

@Component({
  selector: 'app-marketplace-config',
  templateUrl: './marketplace-config.component.html',
  styleUrls: ['./marketplace-config.component.scss']
})
export class MarketplaceConfigComponent implements OnInit {
  private settingsUrl = `${environment.apiUrl}/settings`;

  loading = false;
  saving = false;

  durationDays = 30;
  autoApprove = false;
  visibleStatuses: string[] = ['APPROVED'];
  reportThreshold = 3;

  durationOptions = [
    { label: '1 Month', value: 30 },
    { label: '2 Months', value: 60 },
    { label: '3 Months', value: 90 },
    { label: '6 Months', value: 180 },
    { label: '1 Year', value: 365 },
    { label: 'No Expiry', value: 0 }
  ];

  allStatuses = [
    'APPROVED',
    'PENDING_APPROVAL',
    'SOLD',
    'FLAGGED',
    'HOLD',
    'HIDDEN',
    'CORRECTION_REQUIRED'
  ];

  statusLabels: { [key: string]: string } = {
    'APPROVED': 'Approved',
    'PENDING_APPROVAL': 'Pending Approval',
    'SOLD': 'Sold',
    'FLAGGED': 'Flagged',
    'HOLD': 'Hold',
    'HIDDEN': 'Hidden',
    'CORRECTION_REQUIRED': 'Correction Required'
  };

  constructor(
    private http: HttpClient,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadSettings();
  }

  loadSettings(): void {
    this.loading = true;
    const keys = [
      'marketplace.post.duration_days',
      'marketplace.post.auto_approve',
      'marketplace.post.visible_statuses',
      'marketplace.post.report_threshold'
    ];

    let loaded = 0;
    const total = keys.length;

    keys.forEach(key => {
      this.http.get(`${this.settingsUrl}/key/${key}`).subscribe({
        next: (response: any) => {
          const value = response?.settingValue;
          if (value !== undefined && value !== null) {
            this.applySettingValue(key, value);
          }
          loaded++;
          if (loaded >= total) this.loading = false;
        },
        error: () => {
          loaded++;
          if (loaded >= total) this.loading = false;
        }
      });
    });
  }

  private applySettingValue(key: string, value: string): void {
    switch (key) {
      case 'marketplace.post.duration_days':
        this.durationDays = parseInt(value, 10) || 30;
        break;
      case 'marketplace.post.auto_approve':
        this.autoApprove = value === 'true';
        break;
      case 'marketplace.post.visible_statuses':
        try {
          this.visibleStatuses = JSON.parse(value);
        } catch {
          this.visibleStatuses = ['APPROVED'];
        }
        break;
      case 'marketplace.post.report_threshold':
        this.reportThreshold = parseInt(value, 10) || 3;
        break;
    }
  }

  isStatusChecked(status: string): boolean {
    return this.visibleStatuses.includes(status);
  }

  toggleStatus(status: string): void {
    const idx = this.visibleStatuses.indexOf(status);
    if (idx >= 0) {
      if (this.visibleStatuses.length > 1) {
        this.visibleStatuses.splice(idx, 1);
      } else {
        this.snackBar.open('At least one status must be selected', 'OK', { duration: 3000 });
      }
    } else {
      this.visibleStatuses.push(status);
    }
  }

  saveSettings(): void {
    this.saving = true;

    const settings: { [key: string]: string } = {
      'marketplace.post.duration_days': String(this.durationDays),
      'marketplace.post.auto_approve': String(this.autoApprove),
      'marketplace.post.visible_statuses': JSON.stringify(this.visibleStatuses),
      'marketplace.post.report_threshold': String(this.reportThreshold)
    };

    const keys = Object.keys(settings);
    let saved = 0;
    let hasError = false;

    keys.forEach(key => {
      this.http.put(`${this.settingsUrl}/value/${key}`, settings[key], {
        headers: { 'Content-Type': 'text/plain' }
      }).subscribe({
        next: () => {
          saved++;
          if (saved >= keys.length) {
            this.saving = false;
            if (!hasError) {
              this.snackBar.open('Settings saved successfully', 'OK', { duration: 3000 });
            }
          }
        },
        error: (err) => {
          hasError = true;
          saved++;
          if (saved >= keys.length) {
            this.saving = false;
          }
          this.snackBar.open('Error saving setting: ' + key, 'OK', { duration: 5000 });
        }
      });
    });
  }

  getDurationLabel(): string {
    const opt = this.durationOptions.find(o => o.value === this.durationDays);
    return opt ? opt.label : this.durationDays + ' days';
  }
}
