import { Component, OnInit, OnDestroy } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Subject, takeUntil, debounceTime } from 'rxjs';
import { ShopService, Shop, Product, ShopCategoryNode } from '../../services/shop.service';
import { CartService } from '../../services/cart.service';
import { Location } from '@angular/common';
import { environment } from '../../../../../environments/environment';
import { getImageUrl as getImageUrlUtil } from '../../../../core/utils/image-url.util';

@Component({
  selector: 'app-product-list',
  templateUrl: './product-list.component.html',
  styleUrls: ['./product-list.component.scss']
})
export class ProductListComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  private searchSubject = new Subject<string>();
  
  shop: Shop | null = null;
  products: Product[] = [];
  categories: string[] = [];
  loading = false;

  // Filters
  searchTerm = '';
  selectedCategory = '';
  selectedSubcategory = '';
  sortBy = 'name';

  // Category -> its subgroups (e.g. Rice -> Rice Bag, Loose Rice Packing),
  // keyed by the parent category's own name. Populated from the same
  // hierarchy-aware endpoint the customer mobile app uses.
  subcategoriesByParent: Map<string, ShopCategoryNode[]> = new Map();
  
  // Cart info
  cartItemCount = 0;
  cartTotal = 0;
  
  shopId: number = 0;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private location: Location,
    private shopService: ShopService,
    private cartService: CartService
  ) {
    this.searchSubject
      .pipe(
        debounceTime(300),
        takeUntil(this.destroy$)
      )
      .subscribe(() => this.loadProducts());
  }

  ngOnInit(): void {
    this.route.params.pipe(takeUntil(this.destroy$)).subscribe(params => {
      this.shopId = +params['id'];
      this.loadShop();
      this.loadProducts();
      this.loadCategories();
    });

    // Subscribe to cart changes
    this.cartService.cart$.pipe(takeUntil(this.destroy$)).subscribe(cart => {
      this.cartItemCount = this.cartService.getItemCount();
      this.cartTotal = cart.total;
    });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadShop(): void {
    this.shopService.getShopById(this.shopId)
      .pipe(takeUntil(this.destroy$))
      .subscribe(shop => {
        this.shop = shop;
      });
  }

  loadProducts(): void {
    this.loading = true;
    const effectiveCategory = this.selectedSubcategory || this.selectedCategory;
    this.shopService.getProductsByShop(this.shopId, effectiveCategory, this.searchTerm)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (products) => {
          this.products = this.sortProducts(products);
          this.loading = false;
        },
        error: (error) => {
          console.error('Error loading products:', error);
          this.loading = false;
        }
      });
  }

  loadCategories(): void {
    this.shopService.getShopCategoriesHierarchy(this.shopId)
      .pipe(takeUntil(this.destroy$))
      .subscribe(nodes => {
        const roots = nodes.filter(n => !n.parentName);
        this.categories = roots.map(r => r.name);

        const byParent = new Map<string, ShopCategoryNode[]>();
        nodes.filter(n => n.parentName).forEach(sub => {
          const list = byParent.get(sub.parentName!) || [];
          list.push(sub);
          byParent.set(sub.parentName!, list);
        });
        this.subcategoriesByParent = byParent;
      });
  }

  get currentSubcategories(): ShopCategoryNode[] {
    return this.subcategoriesByParent.get(this.selectedCategory) || [];
  }

  sortProducts(products: Product[]): Product[] {
    switch (this.sortBy) {
      case 'name':
        return products.sort((a, b) => a.name.localeCompare(b.name));
      case 'price-low':
        return products.sort((a, b) => a.price - b.price);
      case 'price-high':
        return products.sort((a, b) => b.price - a.price);
      case 'popular':
        return products; // Keep original order for now
      default:
        return products;
    }
  }

  onSearch(): void {
    this.searchSubject.next(this.searchTerm);
  }

  onCategoryChange(): void {
    this.selectedSubcategory = '';
    this.loadProducts();
  }

  onSubcategoryChange(): void {
    this.loadProducts();
  }

  onSortChange(): void {
    this.products = this.sortProducts([...this.products]);
  }

  addToCart(product: Product): void {
    if (this.shop) {
      this.cartService.addToCart(product, this.shop.id, this.shop.name);
    }
  }

  increaseQuantity(product: Product): void {
    const currentQuantity = this.getProductCartQuantity(product.id);
    this.cartService.updateQuantity(product.id, currentQuantity + 1);
  }

  decreaseQuantity(product: Product): void {
    const currentQuantity = this.getProductCartQuantity(product.id);
    if (currentQuantity > 1) {
      this.cartService.updateQuantity(product.id, currentQuantity - 1);
    } else {
      this.cartService.removeFromCart(product.id);
    }
  }

  getProductCartQuantity(productId: number): number {
    const cart = this.cartService.getCart();
    const item = cart.items.find(item => item.productId === productId);
    return item ? item.quantity : 0;
  }

  goToCart(): void {
    this.router.navigate(['/customer/cart']);
  }

  goBack(): void {
    this.location.back();
  }

  /**
   * Get product image URL with proper fallback
   */
  getProductImageUrl(product: Product): string {
    if (!product.image || product.image === '') {
      return '/assets/images/product-placeholder.jpg';
    }

    // If image starts with /assets, return as is (local asset)
    if (product.image.startsWith('/assets')) {
      return product.image;
    }

    return getImageUrlUtil(product.image);
  }

  /**
   * Handle image load error - fallback to placeholder
   */
  onImageError(event: Event): void {
    const imgElement = event.target as HTMLImageElement;
    imgElement.src = '/assets/images/product-placeholder.jpg';
  }

  /**
   * Handle shop image load error - fallback to placeholder
   */
  onShopImageError(event: Event): void {
    const imgElement = event.target as HTMLImageElement;
    imgElement.src = '/assets/images/shop-placeholder.jpg';
  }
}
