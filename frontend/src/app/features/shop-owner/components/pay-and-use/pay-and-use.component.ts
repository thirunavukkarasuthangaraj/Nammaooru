import { Component, NgZone, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSnackBarModule } from '@angular/material/snack-bar';
import { Router } from '@angular/router';
import { PaymentCollectService, ShopPaymentStatus } from '../../../../core/services/payment-collect.service';
import { AuthService } from '../../../../core/services/auth.service';
import { PwaInstallService } from '../../../../core/services/pwa-install.service';
import { SwalService } from '../../../../core/services/swal.service';

declare const Razorpay: any;

@Component({
  selector: 'app-pay-and-use',
  standalone: true,
  imports: [CommonModule, MatCardModule, MatButtonModule, MatIconModule, MatProgressSpinnerModule, MatSnackBarModule],
  templateUrl: './pay-and-use.component.html',
  styleUrls: ['./pay-and-use.component.scss']
})
export class PayAndUseComponent implements OnInit, OnDestroy {
  status: ShopPaymentStatus | null = null;
  loading = true;
  paying = false;
  isOnline = navigator.onLine;
  today = new Date();

  private onlineHandler = () => { this.isOnline = true; };
  private offlineHandler = () => { this.isOnline = false; };

  constructor(
    private paymentCollectService: PaymentCollectService,
    private authService: AuthService,
    private router: Router,
    private swal: SwalService,
    private ngZone: NgZone
  ) {}

  ngOnInit(): void {
    window.addEventListener('online', this.onlineHandler);
    window.addEventListener('offline', this.offlineHandler);
    this.loadStatus();
  }

  ngOnDestroy(): void {
    window.removeEventListener('online', this.onlineHandler);
    window.removeEventListener('offline', this.offlineHandler);
  }

  loadStatus(): void {
    this.loading = true;
    this.paymentCollectService.getStatus().subscribe({
      next: status => {
        this.status = status;
        this.loading = false;
        if (status.paid) {
          this.router.navigate(['/shop-owner/dashboard']);
        }
      },
      error: err => {
        this.loading = false;
        // Offline: show the last known status so the owner still sees what's due
        // and the "connect to the internet to pay" banner instead of a blank card.
        const cached = this.paymentCollectService.getCachedStatus();
        if (!navigator.onLine && cached) {
          this.status = cached;
          return;
        }
        this.swal.toast(err.message || 'Failed to load payment status', 'error');
      }
    });
  }

  pay(): void {
    if (!this.isOnline) {
      this.swal.toast('Please connect to the internet to pay', 'warning');
      return;
    }
    this.paying = true;
    // Hold app auto-update reloads for the whole checkout - a reload here could
    // take the money without ever running the verify step.
    PwaInstallService.beginCriticalFlow();

    this.paymentCollectService.loadRazorpayScript().then(loaded => {
      if (!loaded) {
        this.paying = false;
        PwaInstallService.endCriticalFlow();
        this.swal.toast('Could not load payment gateway. Check your internet connection and try again.', 'error');
        return;
      }

      this.paymentCollectService.createOrder().subscribe({
        next: order => {
          const options: any = {
            key: order.keyId,
            amount: order.amount,
            currency: order.currency,
            name: 'NammaOoru',
            description: `Shop usage payment${this.status ? ' - ' + this.status.shopName : ''}`,
            order_id: order.testMode ? undefined : order.orderId,
            // Razorpay callbacks fire outside Angular's zone; without ngZone.run the
            // UI never updates (e.g. the button stays stuck on "Processing...").
            handler: (response: any) => this.ngZone.run(() => {
              this.verify(order.orderId, response.razorpay_payment_id, response.razorpay_signature, order.testMode);
            }),
            modal: {
              ondismiss: () => this.ngZone.run(() => { this.paying = false; PwaInstallService.endCriticalFlow(); })
            },
            theme: { color: '#2e7d32' }
          };

          if (order.testMode) {
            // No real gateway in test mode - simulate success directly, mirroring backend's mock-order flow
            this.verify(order.orderId, 'test_pay_' + Date.now(), 'test_sig', true);
            return;
          }

          const rzp = new Razorpay(options);
          rzp.open();
        },
        error: err => {
          this.paying = false;
          PwaInstallService.endCriticalFlow();
          this.swal.toast(err.message || 'Failed to start payment', 'error');
        }
      });
    });
  }

  private verify(orderId: string, paymentId: string, signature: string, testMode: boolean): void {
    this.paymentCollectService.verifyPayment({
      razorpay_order_id: orderId,
      razorpay_payment_id: paymentId,
      razorpay_signature: signature
    }).subscribe({
      next: () => {
        this.paying = false;
        PwaInstallService.endCriticalFlow();
        this.swal.toast('Payment successful. You can now use the app.', 'success');
        this.router.navigate(['/shop-owner/dashboard']);
      },
      error: err => {
        this.paying = false;
        PwaInstallService.endCriticalFlow();
        this.swal.toast(err.message || 'Payment verification failed', 'error');
      }
    });
  }

  logout(): void {
    this.authService.logout();
  }
}
