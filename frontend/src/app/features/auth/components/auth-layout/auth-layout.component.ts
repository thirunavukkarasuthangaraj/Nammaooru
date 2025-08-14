import { Component } from '@angular/core';

@Component({
  selector: 'app-auth-layout',
  template: `
    <div class="auth-container">
      <div class="auth-card">
        <div class="auth-header">
          <h1>Shop Management System</h1>
          <p>Manage your shops efficiently</p>
        </div>
        <router-outlet></router-outlet>
      </div>
    </div>
  `,
  styles: [`
    .auth-container {
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      padding: 20px;
    }

    .auth-card {
      background: white;
      border-radius: 12px;
      box-shadow: 0 15px 35px rgba(0, 0, 0, 0.1);
      max-width: 450px;
      width: 100%;
      overflow: hidden;
    }

    .auth-header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 30px;
      text-align: center;
    }

    .auth-header h1 {
      margin: 0 0 8px 0;
      font-size: 24px;
      font-weight: 500;
    }

    .auth-header p {
      margin: 0;
      opacity: 0.9;
      font-size: 14px;
    }

    @media (max-width: 480px) {
      .auth-container {
        padding: 10px;
      }
      
      .auth-header {
        padding: 20px;
      }
      
      .auth-header h1 {
        font-size: 20px;
      }
    }
  `]
})
export class AuthLayoutComponent { }