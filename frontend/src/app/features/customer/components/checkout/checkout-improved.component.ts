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
  selector: 'app-checkout-improved',
  templateUrl: './checkout-improved.component.html',
  styleUrls: ['./checkout-improved.component.scss']
})
export class CheckoutImprovedComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  checkoutForm: FormGroup;
  cart: Cart = {
    items: [],
    shopId: null,
    shopName: null,
    subtotal: 0,
    discount: 0,
    deliveryFee: 50,
    total: 0
  };

  // Delivery Type Selection
  selectedDeliveryType: 'HOME_DELIVERY' | 'SELF_PICKUP' = 'HOME_DELIVERY';
  shopAddress = 'Test Address, T Nagar, Chennai - 600017'; // Will be loaded from shop data

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
      // Update total when cart changes
      this.updateTotal();
    });

    this.loadSavedAddresses();
    this.loadShopDetails();
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
      streetAddress: [''],
      landmark: [''],
      pincode: [''],
      city: [''],
      state: [''],
      notes: [''],
      agreeToTerms: [false, [Validators.requiredTrue]]
    });
  }

  // ===== DELIVERY TYPE SELECTION =====

  selectDeliveryType(type: 'HOME_DELIVERY' | 'SELF_PICKUP'): void {
    this.selectedDeliveryType = type;

    if (type === 'SELF_PICKUP') {
      // Self-pickup: FREE delivery, no address required
      this.cart.deliveryFee = 0;
      this.estimatedDeliveryTime = '20-30 minutes';

      // Clear address validation
      this.checkoutForm.get('streetAddress')?.clearValidators();
      this.checkoutForm.get('pincode')?.clearValidators();
      this.checkoutForm.get('city')?.clearValidators();
      this.checkoutForm.get('state')?.clearValidators();
    } else {
      // Home delivery: ₹50 fee, address required
      this.cart.deliveryFee = 50;
      this.estimatedDeliveryTime = '30-45 minutes';

      // Add address validation
      this.checkoutForm.get('streetAddress')?.setValidators([Validators.required, Validators.minLength(10)]);
      this.checkoutForm.get('pincode')?.setValidators([Validators.required, Validators.pattern(/^\d{6}$/)]);
      this.checkoutForm.get('city')?.setValidators([Validators.required]);
      this.checkoutForm.get('state')?.setValidators([Validators.required]);
    }

    // Update validators
    this.checkoutForm.get('streetAddress')?.updateValueAndValidity();
    this.checkoutForm.get('pincode')?.updateValueAndValidity();
    this.checkoutForm.get('city')?.updateValueAndValidity();
    this.checkoutForm.get('state')?.updateValueAndValidity();

    // Update total
    this.updateTotal();

    console.log(`Delivery type selected: ${type}, Fee: ₹${this.cart.deliveryFee}`);
  }

  calculateTotal(): number {
    const subtotal = this.cart.subtotal || 0;
    const discount = this.cart.discount || 0;
    const deliveryFee = this.selectedDeliveryType === 'SELF_PICKUP' ? 0 : (this.cart.deliveryFee || 50);
    return subtotal - discount + deliveryFee;
  }

  private updateTotal(): void {
    this.cart.total = this.calculateTotal();
  }

  // ===== SHOP DETAILS =====

  private loadShopDetails(): void {
    // Load shop details from service
    // For now using hardcoded data
    if (this.cart.shopId) {
      // In real app, fetch shop details from API
      this.shopAddress = 'Shop Address will be loaded from API';
    }
  }

  openMaps(): void {
    // Open Google Maps with shop location
    const encodedAddress = encodeURIComponent(this.shopAddress);
    window.open(`https://www.google.com/maps/search/?api=1&query=${encodedAddress}`, '_blank');
  }

  // ===== ADDRESS MANAGEMENT =====

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

  // ===== PROMO CODE =====

  applyPromoCode(): void {
    if (!this.promoCode) {
      Swal.fire('Error', 'Please enter a promo code', 'error');
      return;
    }

    this.checkoutService.applyPromoCode(this.promoCode).subscribe(discount => {
      if (discount > 0) {
        this.promoDiscount = discount;
        this.cartService.applyDiscount(discount);
        this.updateTotal();
        Swal.fire('Success', `Promo code applied! You saved ₹${discount}`, 'success');
      }
    });
  }

  // ===== FORM VALIDATION =====

  isFormValid(): boolean {
    // For self-pickup, only basic details required
    if (this.selectedDeliveryType === 'SELF_PICKUP') {
      return this.checkoutForm.get('firstName')?.valid &&
             this.checkoutForm.get('lastName')?.valid &&
             this.checkoutForm.get('phone')?.valid &&
             this.checkoutForm.get('email')?.valid &&
             this.checkoutForm.get('agreeToTerms')?.value === true &&
             this.cart.items.length > 0;
    }

    // For home delivery, all fields required
    return this.checkoutForm.valid && this.cart.items.length > 0;
  }

  // ===== ORDER PLACEMENT =====

  async placeOrder(): Promise<void> {
    if (!this.isFormValid()) {
      Swal.fire('Error', 'Please fill all required fields', 'error');
      return;
    }

    this.placingOrder = true;

    const formValue = this.checkoutForm.value;

    // Prepare order data based on delivery type
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

    console.log('=== Placing Order ===');
    console.log('Delivery Type:', this.selectedDeliveryType);
    console.log('Delivery Address:', deliveryAddress);
    console.log('Payment Method:', this.selectedPaymentMethod);
    console.log('Total Amount:', this.cart.total);

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
            this.orderPlaced = true;
            this.placingOrder = false;

            // Send Firebase notification
            await this.sendOrderNotification(response);

            // Show success message based on delivery type
            const message = this.selectedDeliveryType === 'SELF_PICKUP'
              ? `Order placed! Come to the shop to collect in ${this.estimatedDeliveryTime}`
              : `Order placed! Will be delivered in ${this.estimatedDeliveryTime}`;

            this.snackBar.open(message, 'Close', { duration: 5000 });

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
        `Estimated ${this.selectedDeliveryType === 'SELF_PICKUP' ? 'pickup' : 'delivery'}: ${this.estimatedDeliveryTime}`
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

  // ===== NAVIGATION =====

  trackOrder(): void {
    if (this.orderResponse) {
      this.router.navigate(['/customer/orders', this.orderResponse.id]);
    }
  }

  continueShopping(): void {
    this.cartService.clearCart();
    this.router.navigate(['/customer/shops']);
  }

  goBackToCart(): void {
    this.router.navigate(['/customer/cart']);
  }
}
