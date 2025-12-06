import { Component } from '@angular/core';

@Component({
  selector: 'app-footer',
  template: `
    <footer class="app-footer">
      <div class="footer-content">
        <div class="footer-section">
          <h4>Thiru Software System</h4>
          <p>Efficiently manage your shops and business operations</p>
        </div>
        
        <div class="footer-section">
          <h4>Quick Links</h4>
          <ul>
            <li><a routerLink="/shops">Browse Shops</a></li>
            <li><a routerLink="/auth/register">Register</a></li>
            <li><a routerLink="/about">About</a></li>
            <li><a routerLink="/contact">Contact</a></li>
          </ul>
        </div>
        
        <div class="footer-section">
          <h4>Support</h4>
          <ul>
            <li><a href="mailto:support@shopmanagement.com">Help Center</a></li>
            <li><a href="/privacy">Privacy Policy</a></li>
            <li><a href="/terms">Terms of Service</a></li>
          </ul>
        </div>
        
        <div class="footer-section">
          <h4>Connect</h4>
          <div class="social-links">
            <button mat-icon-button>
              <mat-icon>facebook</mat-icon>
            </button>
            <button mat-icon-button>
              <mat-icon>email</mat-icon>
            </button>
            <button mat-icon-button>
              <mat-icon>phone</mat-icon>
            </button>
          </div>
        </div>
      </div>
      
      <div class="footer-bottom">
        <div class="footer-content">
          <p>&copy; {{currentYear}} Thiru Software System. All rights reserved.</p>
          <p>Built with Angular & Spring Boot</p>
        </div>
      </div>
    </footer>
  `,
  styles: [`
    .app-footer {
      background-color: #2c3e50;
      color: white;
      margin-top: auto;
    }

    .footer-content {
      max-width: 1200px;
      margin: 0 auto;
      padding: 40px 20px 20px;
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 30px;
    }

    .footer-section h4 {
      margin: 0 0 16px 0;
      font-size: 18px;
      font-weight: 500;
      color: #ecf0f1;
    }

    .footer-section p {
      margin: 0 0 12px 0;
      color: #bdc3c7;
      line-height: 1.5;
    }

    .footer-section ul {
      list-style: none;
      padding: 0;
      margin: 0;
    }

    .footer-section ul li {
      margin: 8px 0;
    }

    .footer-section ul li a {
      color: #bdc3c7;
      text-decoration: none;
      transition: color 0.2s;
    }

    .footer-section ul li a:hover {
      color: #3498db;
    }

    .social-links {
      display: flex;
      gap: 8px;
    }

    .social-links button {
      color: #bdc3c7;
    }

    .social-links button:hover {
      color: #3498db;
    }

    .footer-bottom {
      border-top: 1px solid #34495e;
      background-color: #1a252f;
    }

    .footer-bottom .footer-content {
      padding: 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      grid-template-columns: 1fr;
    }

    .footer-bottom p {
      margin: 0;
      color: #95a5a6;
      font-size: 14px;
    }

    @media (max-width: 768px) {
      .footer-content {
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 20px;
        padding: 30px 15px 15px;
      }

      .footer-bottom .footer-content {
        flex-direction: column;
        gap: 8px;
        text-align: center;
        padding: 15px;
      }

      .social-links {
        justify-content: center;
      }
    }

    @media (max-width: 480px) {
      .footer-content {
        grid-template-columns: 1fr;
      }

      .footer-section {
        text-align: center;
      }
    }
  `]
})
export class FooterComponent {
  currentYear = new Date().getFullYear();
}