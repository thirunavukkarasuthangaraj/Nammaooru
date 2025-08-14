import { Component, OnInit } from '@angular/core';
import { AuthService } from '@core/services/auth.service';
import { User } from '@core/models/auth.model';

@Component({
  selector: 'app-root',
  template: `<router-outlet></router-outlet>`
})
export class AppComponent implements OnInit {
  title = 'Shop Management System';

  constructor(private authService: AuthService) {}

  ngOnInit(): void {
    // Initialize authentication state
    // This will check if user is already logged in from localStorage
  }
}