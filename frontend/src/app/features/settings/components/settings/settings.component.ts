import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { SettingsService, Setting } from '../../../../core/services/settings.service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-settings',
  templateUrl: './settings.component.html',
  styleUrls: ['./settings.component.scss']
})
export class SettingsComponent implements OnInit {
  loading = false;
  settingsForm: FormGroup;
  
  // Settings from API
  settings: Setting[] = [];

  categories: string[] = [];

  constructor(
    private fb: FormBuilder,
    private snackBar: MatSnackBar,
    private settingsService: SettingsService
  ) {
    this.settingsForm = this.fb.group({});
  }

  ngOnInit(): void {
    this.loadSettings();
  }

  createForm(): FormGroup {
    const group: any = {};
    this.settings.forEach(setting => {
      group[setting.key] = [setting.value];
    });
    return this.fb.group(group);
  }

  loadSettings(): void {
    this.loading = true;
    this.settingsService.getAllSettings().subscribe({
      next: (settings) => {
        this.settings = settings;
        // Build categories dynamically from API data
        const seen = new Set<string>();
        this.categories = settings
          .map(s => s.category)
          .filter(c => c && !seen.has(c) && seen.add(c));
        this.settingsForm = this.createForm();
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading settings:', error);
        this.loadMockData();
        this.loading = false;
      }
    });
  }

  private loadMockData(): void {
    const mockSettings: any[] = [
      // General Settings
      {
        id: 1,
        key: 'app.name',
        value: 'Nammaooru Thiru Software',
        description: 'Application name',
        category: 'General',
        type: 'text',
        defaultValue: 'Nammaooru Thiru Software',
        isEditable: true
      },
      {
        id: 2,
        key: 'app.version',
        value: '1.0.9',
        description: 'Current application version',
        category: 'General',
        type: 'text',
        defaultValue: '1.0.0',
        isEditable: false
      },
      {
        id: 3,
        key: 'general.timezone',
        value: 'Asia/Kolkata',
        description: 'Default timezone',
        category: 'General',
        type: 'select',
        defaultValue: 'Asia/Kolkata',
        isEditable: true
      },
      {
        id: 4,
        key: 'general.currency',
        value: 'INR',
        description: 'Default currency',
        category: 'General',
        type: 'select',
        defaultValue: 'INR',
        isEditable: true
      },
      {
        id: 5,
        key: 'general.maintenance.enabled',
        value: 'false',
        description: 'Enable maintenance mode',
        category: 'General',
        type: 'boolean',
        defaultValue: 'false',
        isEditable: true
      },

      // Email Settings
      {
        id: 6,
        key: 'email.enabled',
        value: 'true',
        description: 'Enable email notifications',
        category: 'Email',
        type: 'boolean',
        defaultValue: 'true',
        isEditable: true
      },
      {
        id: 7,
        key: 'email.smtp.host',
        value: 'smtp.gmail.com',
        description: 'SMTP server host',
        category: 'Email',
        type: 'text',
        defaultValue: 'localhost',
        isEditable: true
      },
      {
        id: 8,
        key: 'email.smtp.port',
        value: '587',
        description: 'SMTP server port',
        category: 'Email',
        type: 'number',
        defaultValue: '25',
        isEditable: true
      },
      {
        id: 9,
        key: 'email.from.address',
        value: 'noreply@nammaooru.com',
        description: 'Default sender email address',
        category: 'Email',
        type: 'email',
        defaultValue: 'noreply@example.com',
        isEditable: true
      },

      // Notifications Settings
      {
        id: 10,
        key: 'notifications.order.enabled',
        value: 'true',
        description: 'Enable order notifications',
        category: 'Notifications',
        type: 'boolean',
        defaultValue: 'true',
        isEditable: true
      },
      {
        id: 11,
        key: 'notifications.shop.enabled',
        value: 'true',
        description: 'Enable shop notifications',
        category: 'Notifications',
        type: 'boolean',
        defaultValue: 'true',
        isEditable: true
      },
      {
        id: 12,
        key: 'notifications.push.enabled',
        value: 'true',
        description: 'Enable push notifications',
        category: 'Notifications',
        type: 'boolean',
        defaultValue: 'false',
        isEditable: true
      },
      {
        id: 13,
        key: 'notifications.sms.enabled',
        value: 'false',
        description: 'Enable SMS notifications',
        category: 'Notifications',
        type: 'boolean',
        defaultValue: 'false',
        isEditable: true
      },

      // Security Settings
      {
        id: 14,
        key: 'security.password.minLength',
        value: '8',
        description: 'Minimum password length',
        category: 'Security',
        type: 'number',
        defaultValue: '6',
        isEditable: true
      },
      {
        id: 15,
        key: 'security.session.timeout',
        value: '30',
        description: 'Session timeout in minutes',
        category: 'Security',
        type: 'number',
        defaultValue: '60',
        isEditable: true
      },
      {
        id: 16,
        key: 'security.twoFactor.enabled',
        value: 'false',
        description: 'Enable two-factor authentication',
        category: 'Security',
        type: 'boolean',
        defaultValue: 'false',
        isEditable: true
      },
      {
        id: 17,
        key: 'security.maxLoginAttempts',
        value: '5',
        description: 'Maximum login attempts before lockout',
        category: 'Security',
        type: 'number',
        defaultValue: '3',
        isEditable: true
      },

      // Shop Settings
      {
        id: 18,
        key: 'shop.approval.autoApprove',
        value: 'false',
        description: 'Auto-approve new shop registrations',
        category: 'Shop',
        type: 'boolean',
        defaultValue: 'false',
        isEditable: true
      },
      {
        id: 19,
        key: 'shop.commission.rate',
        value: '10',
        description: 'Default commission rate (%)',
        category: 'Shop',
        type: 'number',
        defaultValue: '5',
        isEditable: true
      },
      {
        id: 20,
        key: 'shop.delivery.maxRadius',
        value: '15',
        description: 'Maximum delivery radius (km)',
        category: 'Shop',
        type: 'number',
        defaultValue: '10',
        isEditable: true
      },
      {
        id: 21,
        key: 'shop.minOrderValue',
        value: '100',
        description: 'Minimum order value (INR)',
        category: 'Shop',
        type: 'number',
        defaultValue: '50',
        isEditable: true
      }
    ];

    this.settings = mockSettings;
    this.settingsForm = this.createForm();
    this.snackBar.open('Loaded mock settings - API not available', 'Close', { duration: 3000 });
  }

  getSettingsByCategory(category: string): Setting[] {
    return this.settings.filter(setting => setting.category === category);
  }

  onSubmit(): void {
    if (this.settingsForm.valid) {
      this.loading = true;
      
      const formValues = this.settingsForm.value;
      this.settingsService.updateMultipleSettings(formValues).subscribe({
        next: (updatedSettings) => {
          this.settings = updatedSettings;
          this.loading = false;
          Swal.fire({
            title: 'Success!',
            text: 'Settings updated successfully.',
            icon: 'success',
            confirmButtonText: 'OK'
          });
        },
        error: (error) => {
          console.error('Error updating settings:', error);
          this.loading = false;
          Swal.fire({
            title: 'Error!',
            text: 'Failed to update settings. Please try again.',
            icon: 'error',
            confirmButtonText: 'OK'
          });
        }
      });
    }
  }

  resetToDefaults(): void {
    Swal.fire({
      title: 'Reset Settings',
      text: 'Are you sure you want to reset all settings to default values? This action cannot be undone.',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, reset',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.loading = true;
        
        this.settingsService.resetToDefaults().subscribe({
          next: (resetSettings) => {
            this.settings = resetSettings;
            this.settingsForm = this.createForm();
            this.loading = false;
            Swal.fire({
              title: 'Success!',
              text: 'Settings have been reset to defaults.',
              icon: 'success',
              confirmButtonText: 'OK'
            });
          },
          error: (error) => {
            console.error('Error resetting settings:', error);
            this.loading = false;
            Swal.fire({
              title: 'Error!',
              text: 'Failed to reset settings. Please try again.',
              icon: 'error',
              confirmButtonText: 'OK'
            });
          }
        });
      }
    });
  }

  isToggleSetting(key: string): boolean {
    return key.includes('enabled') || key.includes('active');
  }

  getSettingDisplayName(key: string): string {
    return key.split('.').pop()?.replace(/([A-Z])/g, ' $1').trim() || key;
  }
}