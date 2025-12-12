import { Component, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { Location } from '@angular/common';
import { CartService, Cart, CartItem } from '../../services/cart.service';
import { MatSnackBar } from '@angular/material/snack-bar';
import { getImageUrl } from '../../../../core/utils/image-url.util';

@Component({
  selector: 'app-shopping-cart',
  templateUrl: './shopping-cart.component.html',
  styleUrls: ['./shopping-cart.component.scss']
})
export class ShoppingCartComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  
  cart: Cart = {
    items: [],
    shopId: null,
    shopName: null,
    subtotal: 0,
    discount: 0,
    deliveryFee: 0,
    total: 0
  };
  
  cartItems: CartItem[] = [];
  
  // Discount functionality
  discountCode = '';
  discountApplied = false;
  discountMessage = '';
  applyingDiscount = false;

  constructor(
    private router: Router,
    private location: Location,
    private cartService: CartService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.cartService.cart$.pipe(takeUntil(this.destroy$)).subscribe(cart => {
      this.cart = cart;
      this.cartItems = cart.items;
    });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  increaseQuantity(item: CartItem): void {
    this.cartService.updateQuantity(item.productId, item.quantity + 1);
  }

  decreaseQuantity(item: CartItem): void {
    if (item.quantity > 1) {
      this.cartService.updateQuantity(item.productId, item.quantity - 1);
    } else {
      this.removeItem(item);
    }
  }

  removeItem(item: CartItem): void {
    this.cartService.removeFromCart(item.productId);
    this.snackBar.open(`${item.productName} removed from cart`, 'Close', { 
      duration: 2000 
    });
  }

  clearCart(): void {
    this.cartService.clearCart();
    this.discountApplied = false;
    this.discountCode = '';
    this.discountMessage = '';
    this.snackBar.open('Cart cleared', 'Close', { 
      duration: 2000 
    });
  }

  applyDiscount(): void {
    if (!this.discountCode.trim()) return;
    
    this.applyingDiscount = true;
    
    // Mock discount codes - replace with actual API call
    const discountCodes: { [key: string]: number } = {
      'WELCOME10': 10,
      'SAVE20': 20,
      'NEWUSER': 15,
      'CHENNAI5': 5
    };
    
    const discountPercent = discountCodes[this.discountCode.toUpperCase()];
    
    setTimeout(() => {
      if (discountPercent) {
        const discountAmount = Math.round((this.cart.subtotal * discountPercent) / 100);
        this.cartService.applyDiscount(discountAmount);
        this.discountApplied = true;
        this.discountMessage = `${discountPercent}% discount applied!`;
        this.snackBar.open(`Discount of ₹${discountAmount} applied!`, 'Close', { 
          duration: 3000 
        });
      } else {
        this.discountMessage = 'Invalid discount code';
        this.snackBar.open('Invalid discount code', 'Close', { 
          duration: 2000 
        });
      }
      this.applyingDiscount = false;
    }, 1000);
  }

  proceedToCheckout(): void {
    if (this.cartItems.length === 0) return;
    
    this.router.navigate(['/customer/checkout']);
  }

  goToShops(): void {
    this.router.navigate(['/customer/shops']);
  }

  goBack(): void {
    this.location.back();
  }

  /**
   * Get product image URL with proper fallback
   */
  getProductImageUrl(imageUrl: string | null | undefined): string {
    if (!imageUrl || imageUrl === '') {
      return '/assets/images/product-placeholder.jpg';
    }

    // If image starts with /assets, return as is (local asset)
    if (imageUrl.startsWith('/assets')) {
      return imageUrl;
    }

    return getImageUrl(imageUrl);
  }

  /**
   * Handle image load error - fallback to placeholder
   */
  onImageError(event: Event): void {
    const imgElement = event.target as HTMLImageElement;
    imgElement.src = '/assets/images/product-placeholder.jpg';
  }
}
