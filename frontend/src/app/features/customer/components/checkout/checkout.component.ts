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
  selectedDeliveryType: 'HOME_DELIVERY' | 'SELF_PICKUP' = 'HOME_DELIVERY';
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
      // Update cart with delivery fee based on delivery type
      this.updateDeliveryFee();
    });

    this.loadSavedAddresses();
    // Set default delivery time (API endpoint not available)
    this.estimatedDeliveryTime = '30-45 minutes';
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private createForm(): FormGroup {
    return this.fb.group({
      firstName: ['', [Validators.required, Validators.minLength(2)]],
      lastName: ['', [Validators.required, Validators.minLength(2)]],
      phone: ['', [Validators.required, Validators.pattern(/^[6-9]\d{9}$/)]],
      email: ['', [Validators.required, Validators.email]],
      streetAddress: ['', [Validators.required, Validators.minLength(10)]],
      landmark: [''],
      pincode: ['', [Validators.required, Validators.pattern(/^\d{6}$/)]],
      city: ['', [Validators.required]],
      state: ['', [Validators.required]],
      notes: [''],
      agreeToTerms: [false, [Validators.requiredTrue]]
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
    const names = (address.contactName || '').split(' ');
    this.checkoutForm.patchValue({
      firstName: names[0] || '',
      lastName: names.slice(1).join(' ') || '',
      phone: address.phone,
      streetAddress: address.address,
      landmark: address.landmark || '',
      city: address.city,
      state: address.state,
      pincode: address.postalCode
    });
  }

  onDeliveryTypeChange(deliveryType: 'HOME_DELIVERY' | 'SELF_PICKUP'): void {
    this.selectedDeliveryType = deliveryType;

    // Update form validators based on delivery type
    const addressFields = ['streetAddress', 'city', 'state', 'pincode'];

    if (deliveryType === 'SELF_PICKUP') {
      // Make address fields optional for self-pickup
      addressFields.forEach(field => {
        this.checkoutForm.get(field)?.clearValidators();
        this.checkoutForm.get(field)?.updateValueAndValidity();
      });
    } else {
      // Make address fields required for home delivery
      this.checkoutForm.get('streetAddress')?.setValidators([Validators.required, Validators.minLength(10)]);
      this.checkoutForm.get('city')?.setValidators([Validators.required]);
      this.checkoutForm.get('state')?.setValidators([Validators.required]);
      this.checkoutForm.get('pincode')?.setValidators([Validators.required, Validators.pattern(/^\d{6}$/)]);

      addressFields.forEach(field => {
        this.checkoutForm.get(field)?.updateValueAndValidity();
      });
    }

    // Update delivery fee
    this.updateDeliveryFee();
  }

  updateDeliveryFee(): void {
    const deliveryFee = this.selectedDeliveryType === 'SELF_PICKUP' ? 0 : 50;
    this.cartService.updateDeliveryFee(deliveryFee);
  }
  
  calculateDeliveryTime(): void {
    // Set default delivery time (API endpoint not available)
    this.estimatedDeliveryTime = '30-45 minutes';
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

    // For SELF_PICKUP, delivery address is optional
    let deliveryAddress: DeliveryAddress | null = null;
    if (this.selectedDeliveryType === 'HOME_DELIVERY') {
      deliveryAddress = {
        contactName: `${formValue.firstName} ${formValue.lastName}`.trim(),
        phone: formValue.phone,
        address: formValue.streetAddress,
        city: formValue.city,
        state: formValue.state,
        postalCode: formValue.pincode,
        landmark: formValue.landmark || ''
      };
    }

    console.log('Checkout form values:', formValue);
    console.log('Delivery type:', this.selectedDeliveryType);
    console.log('Delivery address:', deliveryAddress);

    // Place order with delivery type
    this.checkoutService.placeOrderWithDeliveryType(
      this.selectedDeliveryType,
      deliveryAddress,
      this.selectedPaymentMethod,
      formValue.notes
    )
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: async (response) => {
          if (response && response.id) {
            this.orderResponse = response;
            this.placingOrder = false;

            // Show success message
            const deliveryMessage = this.selectedDeliveryType === 'SELF_PICKUP'
              ? 'You can collect your order from the store once it\'s ready.'
              : `Your order #${response.orderNumber} will be delivered soon.`;

            Swal.fire({
              title: 'Order Placed Successfully!',
              text: deliveryMessage,
              icon: 'success',
              confirmButtonText: 'View Orders',
              showCancelButton: true,
              cancelButtonText: 'Continue Shopping'
            }).then((result) => {
              if (result.isConfirmed) {
                this.router.navigate(['/customer/orders']);
              } else {
                this.router.navigate(['/customer/shops']);
              }
            });

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
      this.router.navigate(['/customer/orders']);
    }
  }

  continueShopping(): void {
    this.router.navigate(['/customer/shops']);
  }

  goBackToCart(): void {
    this.router.navigate(['/customer/cart']);
  }
}
