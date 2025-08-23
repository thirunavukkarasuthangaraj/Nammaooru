import { Component, OnInit, OnDestroy } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { MatSnackBar } from '@angular/material/snack-bar';
import { CartService, Cart } from '../../services/cart.service';
import { CheckoutService, DeliveryAddress } from '../../services/checkout.service';
import { FirebaseService } from '../../../../core/services/firebase.service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-checkout',
  templateUrl: './checkout.component.html',
  styleUrls: ['./checkout.component.scss']
})
export class CheckoutComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  
  checkoutForm: FormGroup;
  cart: Cart = {
    items: [],
    shopId: null,
    shopName: null,
    subtotal: 0,
    discount: 0,
    deliveryFee: 0,
    total: 0
  };
  
  placingOrder = false;
  orderPlaced = false;
  orderResponse: any = null;
  savedAddresses: DeliveryAddress[] = [];
  selectedPaymentMethod = 'CASH_ON_DELIVERY';
  estimatedDeliveryTime = '30-45 minutes';
  promoCode = '';
  promoDiscount = 0;
  
  paymentMethods = [
    { value: 'CASH_ON_DELIVERY', label: 'Cash on Delivery', icon: 'money' },
    { value: 'ONLINE_PAYMENT', label: 'Online Payment', icon: 'credit_card' },
    { value: 'UPI', label: 'UPI Payment', icon: 'account_balance' }
  ];

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private cartService: CartService,
    private checkoutService: CheckoutService,
    private firebaseService: FirebaseService,
    private snackBar: MatSnackBar
  ) {
    this.checkoutForm = this.createForm();
  }

  ngOnInit(): void {
    this.cartService.cart$.pipe(takeUntil(this.destroy$)).subscribe(cart => {
      this.cart = cart;
      if (cart.items.length === 0) {
        this.router.navigate(['/customer/shops']);
      }
    });

    // Pre-fill form with Chennai defaults
    this.checkoutForm.patchValue({
      city: 'Chennai',
      state: 'Tamil Nadu'
    });
    
    this.loadSavedAddresses();
    this.calculateDeliveryTime();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private createForm(): FormGroup {
    return this.fb.group({
      contactName: ['', [Validators.required, Validators.minLength(3)]],
      phone: ['', [Validators.required, Validators.pattern(/^[6-9]\d{9}$/)]],
      email: ['', [Validators.required, Validators.email]],
      address: ['', [Validators.required, Validators.minLength(10)]],
      landmark: [''],
      city: ['Chennai', [Validators.required]],
      state: ['Tamil Nadu', [Validators.required]],
      postalCode: ['', [Validators.required, Validators.pattern(/^\d{6}$/)]],
      notes: [''],
      saveAddress: [false]
    });
  }
  
  loadSavedAddresses(): void {
    this.checkoutService.getSavedAddresses().subscribe(addresses => {
      this.savedAddresses = addresses;
      if (addresses.length > 0) {
        const defaultAddress = addresses.find(a => a.isDefault) || addresses[0];
        this.selectAddress(defaultAddress);
      }
    });
  }
  
  selectAddress(address: DeliveryAddress): void {
    this.checkoutForm.patchValue({
      contactName: address.contactName,
      phone: address.phone,
      address: address.address,
      landmark: address.landmark || '',
      city: address.city,
      state: address.state,
      postalCode: address.postalCode
    });
  }
  
  calculateDeliveryTime(): void {
    if (this.cart && this.cart.shopId) {
      this.checkoutService.calculateDeliveryTime(this.cart.shopId).subscribe(time => {
        this.estimatedDeliveryTime = time;
      });
    }
  }
  
  applyPromoCode(): void {
    if (!this.promoCode) {
      Swal.fire('Error', 'Please enter a promo code', 'error');
      return;
    }

    this.checkoutService.applyPromoCode(this.promoCode).subscribe(discount => {
      if (discount > 0) {
        this.promoDiscount = discount;
        this.cartService.applyDiscount(discount);
        Swal.fire('Success', `Promo code applied! You saved ₹${discount}`, 'success');
      }
    });
  }

  async placeOrder(): Promise<void> {
    if (this.checkoutForm.invalid || this.cart.items.length === 0) {
      Swal.fire('Error', 'Please fill all required fields', 'error');
      return;
    }

    this.placingOrder = true;

    const formValue = this.checkoutForm.value;
    const deliveryAddress: DeliveryAddress = {
      contactName: formValue.contactName,
      phone: formValue.phone,
      address: formValue.address,
      city: formValue.city,
      state: formValue.state,
      postalCode: formValue.postalCode,
      landmark: formValue.landmark
    };
    
    // Save address if requested
    if (formValue.saveAddress) {
      this.checkoutService.saveAddress(deliveryAddress).subscribe();
    }

    // Place order
    this.checkoutService.placeOrder(deliveryAddress, this.selectedPaymentMethod, formValue.notes)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: async (response) => {
          if (response && response.id) {
            this.orderResponse = response;
            this.orderPlaced = true;
            this.placingOrder = false;

            // Send Firebase notification
            await this.sendOrderNotification(response);
            
            // Process payment if not COD
            if (this.selectedPaymentMethod !== 'CASH_ON_DELIVERY') {
              this.processPayment(response.id);
            }
          } else {
            this.placingOrder = false;
          }
        },
        error: (error) => {
          console.error('Error placing order:', error);
          this.placingOrder = false;
          Swal.fire('Error', 'Failed to place order. Please try again.', 'error');
        }
      });
  }
  
  processPayment(orderId: number): void {
    this.checkoutService.processPayment(orderId, this.selectedPaymentMethod).subscribe({
      next: (result) => {
        if (result.success) {
          Swal.fire('Payment Successful', 'Your payment has been processed', 'success');
        } else {
          Swal.fire('Payment Failed', 'Your order is placed but payment failed. Please pay on delivery.', 'warning');
        }
      },
      error: () => {
        Swal.fire('Payment Error', 'Payment processing failed. Order placed with COD.', 'warning');
      }
    });
  }

  private async sendOrderNotification(orderResponse: any): Promise<void> {
    try {
      // Send order confirmation notification
      this.firebaseService.sendOrderNotification(
        orderResponse.orderNumber,
        'CONFIRMED',
        `Estimated delivery: ${orderResponse.estimatedDeliveryTime || '30-45 minutes'}`
      );

      // Request notification permission if needed
      this.firebaseService.requestPermission().subscribe(
        (result) => {
          if (result) {
            console.log('Notification permission granted');
          }
        },
        (error) => {
          console.error('Error requesting notification permission:', error);
        }
      );

      console.log('Order notification sent:', orderResponse.orderNumber);
    } catch (error) {
      console.error('Error sending notification:', error);
    }
  }

  trackOrder(): void {
    if (this.orderResponse) {
      this.router.navigate(['/customer/track-order', this.orderResponse.orderNumber]);
    }
  }

  continueShopping(): void {
    this.router.navigate(['/customer/shops']);
  }

  goBackToCart(): void {
    this.router.navigate(['/customer/cart']);
  }
}
