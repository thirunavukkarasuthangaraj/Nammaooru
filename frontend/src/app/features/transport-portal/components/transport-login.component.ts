import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';
import { TransportOwnerService } from '../../../core/services/transport-owner.service';

@Component({
  selector: 'app-transport-login',
  template: `
<div class="tp-login">
  <div class="card">
    <div class="brand">
      <mat-icon>directions_bus</mat-icon>
      <div>
        <h1>Fleet Owner Login</h1>
        <p>Nammaooru Transport &amp; Live Tracking</p>
      </div>
    </div>

    <div class="notice warn" *ngIf="notice">{{ notice }}</div>
    <div class="notice err" *ngIf="error">{{ error }}</div>

    <ng-container *ngIf="step === 'phone'">
      <p class="hint">Enter the mobile number registered as a transporter. We will send a one-time password by SMS.</p>
      <mat-form-field appearance="outline" class="full">
        <mat-label>Mobile number</mat-label>
        <span matPrefix>+91&nbsp;</span>
        <input matInput [(ngModel)]="phone" maxlength="10" inputmode="numeric" placeholder="9876543210" (keyup.enter)="sendOtp()">
      </mat-form-field>
      <button mat-raised-button color="primary" class="full" [disabled]="busy || phone.length !== 10" (click)="sendOtp()">
        {{ busy ? 'Sending...' : 'Send OTP' }}
      </button>
    </ng-container>

    <ng-container *ngIf="step === 'otp'">
      <p class="hint">OTP sent to +91 {{ phone }}. <a (click)="step = 'phone'; otp = ''">Change number</a></p>
      <mat-form-field appearance="outline" class="full">
        <mat-label>6-digit OTP</mat-label>
        <input matInput [(ngModel)]="otp" maxlength="6" inputmode="numeric" (keyup.enter)="verify()" autofocus>
      </mat-form-field>
      <button mat-raised-button color="primary" class="full" [disabled]="busy || otp.length !== 6" (click)="verify()">
        {{ busy ? 'Verifying...' : 'Login' }}
      </button>
      <button mat-button class="full" [disabled]="busy" (click)="sendOtp()">Resend OTP</button>
    </ng-container>

    <div class="foot">
      <p>Not a transporter yet? Register from the Nammaooru app (Where is Bus &rarr; menu) or ask the admin to add your number.</p>
      <a routerLink="/auth/login">Admin / shop login</a>
    </div>
  </div>
</div>`,
  styles: [`
    .tp-login { min-height: 100vh; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #0d47a1, #1976d2 60%, #42a5f5); padding: 16px; }
    .card { width: 100%; max-width: 420px; background: #fff; border-radius: 18px; padding: 28px 26px; box-shadow: 0 20px 50px rgba(0,0,0,.25); }
    .brand { display: flex; gap: 14px; align-items: center; margin-bottom: 18px; mat-icon { font-size: 44px; width: 44px; height: 44px; color: #1565c0; } h1 { margin: 0; font-size: 22px; } p { margin: 2px 0 0; color: #6b7280; font-size: 13px; } }
    .hint { color: #4b5563; font-size: 13.5px; margin: 0 0 12px; a { color: #1565c0; cursor: pointer; } }
    .full { width: 100%; }
    button.full { height: 46px; margin-top: 4px; }
    .notice { padding: 10px 12px; border-radius: 10px; font-size: 13px; margin-bottom: 12px; }
    .warn { background: #fff8e1; color: #8d6e00; border: 1px solid #ffe082; }
    .err { background: #ffebee; color: #c62828; border: 1px solid #ffcdd2; }
    .foot { margin-top: 18px; font-size: 12.5px; color: #6b7280; a { color: #1565c0; } }
  `]
})
export class TransportLoginComponent implements OnInit {
  step: 'phone' | 'otp' = 'phone';
  phone = '';
  otp = '';
  busy = false;
  error = '';
  notice = '';

  constructor(private auth: AuthService, private svc: TransportOwnerService, private router: Router, private route: ActivatedRoute) {}

  ngOnInit(): void {
    const st = this.route.snapshot.queryParamMap.get('status');
    if (st === 'PENDING') this.notice = 'Your transporter registration is waiting for admin approval.';
    else if (st === 'BLOCKED') this.notice = 'This transporter account is blocked. Please contact Nammaooru support.';
    else if (st === 'none') this.notice = 'This number is not registered as a transporter yet.';
    // Already logged in as an owner? Go straight in.
    if (this.auth.isAuthenticated()) {
      this.svc.me().subscribe({ next: me => { if (me?.isOwner) this.router.navigate(['/transport/dashboard']); }, error: () => {} });
    }
  }

  sendOtp(): void {
    this.error = '';
    const p = this.phone.replace(/\D/g, '');
    if (p.length !== 10) { this.error = 'Enter a 10-digit mobile number'; return; }
    this.busy = true;
    this.svc.sendLoginOtp(p).subscribe({
      next: (r: any) => {
        this.busy = false;
        if (r && r.success === false) { this.error = r.message || 'Could not send OTP'; return; }
        this.step = 'otp';
      },
      error: (e) => { this.busy = false; this.error = e?.error?.message || 'Could not send OTP'; }
    });
  }

  verify(): void {
    this.error = '';
    this.busy = true;
    this.auth.verifyLoginOtp(this.phone, this.otp).subscribe({
      next: () => {
        this.svc.me().subscribe({
          next: me => {
            this.busy = false;
            if (me?.isOwner) { this.router.navigate(['/transport/dashboard']); return; }
            const s = me?.transporter?.status;
            this.notice = s === 'PENDING' ? 'Logged in, but your transporter registration is still waiting for approval.'
              : s === 'BLOCKED' ? 'This transporter account is blocked.'
              : 'This number is not registered as a transporter. Register from the app or ask the admin.';
            this.step = 'phone';
          },
          error: () => { this.busy = false; this.error = 'Logged in, but could not load transporter profile.'; }
        });
      },
      error: (e) => { this.busy = false; this.error = e?.message || e?.error?.message || 'Wrong or expired OTP'; }
    });
  }
}
