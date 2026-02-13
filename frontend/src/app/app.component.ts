import { Component, HostListener, OnInit } from '@angular/core';
import { AuthService } from '@core/services/auth.service';
import { PwaInstallService } from '@core/services/pwa-install.service';
import { User } from '@core/models/auth.model';

@Component({
  selector: 'app-root',
  template: `<router-outlet></router-outlet>`
})
export class AppComponent implements OnInit {
  title = 'Thiru Software System';

  constructor(
    private authService: AuthService,
    private pwaService: PwaInstallService  // Initializes auto-update checking
  ) {}

  ngOnInit(): void {
    // Initialize authentication state
    // This will check if user is already logged in from localStorage
    // PWA auto-update is handled by PwaInstallService
  }

  // Prevent scroll from changing number input values
  @HostListener('document:wheel', ['$event'])
  onWheel(event: WheelEvent): void {
    const target = event.target as HTMLElement;
    if (target && target.tagName === 'INPUT' && (target as HTMLInputElement).type === 'number') {
      (target as HTMLInputElement).blur();
    }
  }
}