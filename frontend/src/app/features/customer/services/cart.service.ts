import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../environments/environment';
import { catchError, switchMap } from 'rxjs/operators';

export interface CartItem {
  productId: number;
  productName: string;
  productImage: string;
  price: number;
  quantity: number;
  unit: string;
  shopId: number;
  shopName: string;
}

export interface Cart {
  items: CartItem[];
  shopId: number | null;
  shopName: string | null;
  subtotal: number;
  discount: number;
  deliveryFee: number;
  total: number;
}

@Injectable({
  providedIn: 'root'
})
export class CartService {
  private readonly CART_KEY = 'nammaooru_cart';
  private readonly DELIVERY_FEE = 40; // Fixed delivery fee
  private apiUrl = `${environment.apiUrl}`;
  
  private cartSubject = new BehaviorSubject<Cart>(this.getEmptyCart());
  public cart$: Observable<Cart> = this.cartSubject.asObservable();

  constructor(
    private snackBar: MatSnackBar,
    private http: HttpClient
  ) {
    this.loadCart();
  }

  private getEmptyCart(): Cart {
    return {
      items: [],
      shopId: null,
      shopName: null,
      subtotal: 0,
      discount: 0,
      deliveryFee: 0,
      total: 0
    };
  }

  private loadCart(): void {
    const savedCart = localStorage.getItem(this.CART_KEY);
    if (savedCart) {
      const cart = JSON.parse(savedCart);
      this.cartSubject.next(cart);
    }
  }

  private saveCart(cart: Cart): void {
    localStorage.setItem(this.CART_KEY, JSON.stringify(cart));
    this.cartSubject.next(cart);
    this.syncCartWithBackend(cart);
  }

  // Sync cart with backend
  private syncCartWithBackend(cart: Cart): void {
    const customerId = this.getCustomerId();
    if (customerId && cart.items.length > 0) {
      this.http.post(`${this.apiUrl}/customers/${customerId}/cart/sync`, cart)
        .pipe(catchError(() => of(null)))
        .subscribe();
    }
  }

  // Get customer ID from auth
  private getCustomerId(): number | null {
    const user = localStorage.getItem('currentUser');
    if (user) {
      try {
        const userData = JSON.parse(user);
        return userData.id || null;
      } catch {
        return null;
      }
    }
    return null;
  }

  // Load cart from backend
  loadCartFromBackend(): Observable<Cart> {
    const customerId = this.getCustomerId();
    if (!customerId) {
      return of(this.cartSubject.value);
    }
    
    return this.http.get<{data: Cart}>(`${this.apiUrl}/customers/${customerId}/cart`)
      .pipe(
        switchMap(response => {
          if (response.data && response.data.items.length > 0) {
            this.cartSubject.next(response.data);
            localStorage.setItem(this.CART_KEY, JSON.stringify(response.data));
          }
          return of(response.data || this.cartSubject.value);
        }),
        catchError(() => of(this.cartSubject.value))
      );
  }

  addToCart(product: any, shopId: number, shopName: string): boolean {
    const currentCart = this.cartSubject.value;
    
    // Check if cart has items from different shop
    if (currentCart.shopId && currentCart.shopId !== shopId) {
      this.snackBar.open(
        'You can only order from one shop at a time. Clear cart to order from different shop.',
        'Clear Cart',
        { duration: 5000 }
      ).onAction().subscribe(() => {
        this.clearCart();
        this.addToCart(product, shopId, shopName);
      });
      return false;
    }

    // Set shop details if first item
    if (!currentCart.shopId) {
      currentCart.shopId = shopId;
      currentCart.shopName = shopName;
    }

    // Check if product already in cart
    const existingItem = currentCart.items.find(item => item.productId === product.id);
    
    if (existingItem) {
      existingItem.quantity++;
    } else {
      const cartItem: CartItem = {
        productId: product.id,
        productName: product.name,
        productImage: product.image || '/assets/images/product-placeholder.jpg',
        price: product.price,
        quantity: 1,
        unit: product.unit || 'item',
        shopId: shopId,
        shopName: shopName
      };
      currentCart.items.push(cartItem);
    }

    this.updateCartTotals(currentCart);
    this.saveCart(currentCart);
    
    this.snackBar.open(`${product.name} added to cart`, 'View Cart', { 
      duration: 3000 
    });
    
    return true;
  }

  updateQuantity(productId: number, quantity: number): void {
    const currentCart = this.cartSubject.value;
    const item = currentCart.items.find(i => i.productId === productId);
    
    if (item) {
      if (quantity <= 0) {
        this.removeFromCart(productId);
      } else {
        item.quantity = quantity;
        this.updateCartTotals(currentCart);
        this.saveCart(currentCart);
      }
    }
  }

  removeFromCart(productId: number): void {
    const currentCart = this.cartSubject.value;
    currentCart.items = currentCart.items.filter(item => item.productId !== productId);
    
    // Clear shop details if cart is empty
    if (currentCart.items.length === 0) {
      currentCart.shopId = null;
      currentCart.shopName = null;
    }
    
    this.updateCartTotals(currentCart);
    this.saveCart(currentCart);
  }

  applyDiscount(discountAmount: number): void {
    const currentCart = this.cartSubject.value;
    currentCart.discount = discountAmount;
    this.updateCartTotals(currentCart);
    this.saveCart(currentCart);
  }

  private updateCartTotals(cart: Cart): void {
    cart.subtotal = cart.items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    cart.deliveryFee = cart.items.length > 0 ? this.DELIVERY_FEE : 0;
    cart.total = cart.subtotal - cart.discount + cart.deliveryFee;
  }

  clearCart(): void {
    const emptyCart = this.getEmptyCart();
    this.saveCart(emptyCart);
  }

  getCart(): Cart {
    return this.cartSubject.value;
  }

  getItemCount(): number {
    return this.cartSubject.value.items.reduce((count, item) => count + item.quantity, 0);
  }

  getTotalAmount(): number {
    return this.cartSubject.value.total;
  }

  getCurrentShopId(): number | null {
    return this.cartSubject.value.shopId;
  }
}
