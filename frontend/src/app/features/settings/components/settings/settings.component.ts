import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { SettingsService, Setting } from '../../../../core/services/settings.service';

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

  categories = ['General', 'Email', 'Notifications', 'Security', 'Shop'];

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
        this.settingsForm = this.createForm();
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading settings:', error);
        this.snackBar.open('Error loading settings', 'Close', { duration: 3000 });
        this.loading = false;
      }
    });
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
          this.snackBar.open('Settings updated successfully', 'Close', { duration: 3000 });
          this.loading = false;
        },
        error: (error) => {
          console.error('Error updating settings:', error);
          this.snackBar.open('Error updating settings', 'Close', { duration: 3000 });
          this.loading = false;
        }
      });
    }
  }

  resetToDefaults(): void {
    if (confirm('Are you sure you want to reset all settings to default values?')) {
      this.loading = true;
      
      this.settingsService.resetToDefaults().subscribe({
        next: (resetSettings) => {
          this.settings = resetSettings;
          this.settingsForm = this.createForm();
          this.snackBar.open('Settings reset to defaults', 'Close', { duration: 3000 });
          this.loading = false;
        },
        error: (error) => {
          console.error('Error resetting settings:', error);
          this.snackBar.open('Error resetting settings', 'Close', { duration: 3000 });
          this.loading = false;
        }
      });
    }
  }

  isToggleSetting(key: string): boolean {
    return key.includes('enabled') || key.includes('active');
  }

  getSettingDisplayName(key: string): string {
    return key.split('.').pop()?.replace(/([A-Z])/g, ' $1').trim() || key;
  }
}