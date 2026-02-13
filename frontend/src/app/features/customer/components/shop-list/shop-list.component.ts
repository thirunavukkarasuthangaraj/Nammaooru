import { Component, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { Subject, takeUntil, debounceTime } from 'rxjs';
import { ShopService } from '../../services/shop.service';
import { FirebaseService } from '../../../../core/services/firebase.service';

interface Shop {
  id: number;
  name: string;
  description: string;
  image?: string;
  isOpen: boolean;
  rating?: number;
  distance?: string;
  deliveryTime?: string;
  deliveryFee?: number;
  categories: string[];
}

@Component({
  selector: 'app-shop-list',
  templateUrl: './shop-list.component.html',
  styleUrls: ['./shop-list.component.scss']
})
export class ShopListComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  private searchSubject = new Subject<string>();

  shops: Shop[] = [];
  loading = false;
  searchTerm = '';
  selectedCategory = '';

  private userLat: number | null = null;
  private userLng: number | null = null;
  locationStatus: 'loading' | 'granted' | 'denied' | 'unavailable' = 'loading';

  constructor(
    private router: Router,
    private shopService: ShopService,
    private firebaseService: FirebaseService
  ) {
    this.searchSubject
      .pipe(
        debounceTime(300),
        takeUntil(this.destroy$)
      )
      .subscribe(() => this.loadShops());
  }

  ngOnInit(): void {
    this.getUserLocation();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private getUserLocation(): void {
    if (!navigator.geolocation) {
      this.locationStatus = 'unavailable';
      this.loadShops();
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.userLat = position.coords.latitude;
        this.userLng = position.coords.longitude;
        this.locationStatus = 'granted';
        this.loadShops();
      },
      () => {
        this.locationStatus = 'denied';
        this.loadShops();
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 60000 }
    );
  }

  loadShops(): void {
    this.loading = true;

    if (this.userLat != null && this.userLng != null) {
      this.shopService.getNearbyShops(this.userLat, this.userLng, 10)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (shops) => {
            this.shops = this.applyFilters(shops);
            this.loading = false;
          },
          error: () => {
            this.loadAllShops();
          }
        });
    } else {
      this.loadAllShops();
    }
  }

  private loadAllShops(): void {
    this.shopService.getShops(this.searchTerm, this.selectedCategory)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (shops) => {
          this.shops = shops;
          this.loading = false;
        },
        error: (error) => {
          console.error('Error loading shops:', error);
          this.loading = false;
        }
      });
  }

  private applyFilters(shops: Shop[]): Shop[] {
    let filtered = shops;
    if (this.searchTerm) {
      const term = this.searchTerm.toLowerCase();
      filtered = filtered.filter(s =>
        s.name.toLowerCase().includes(term) ||
        s.description.toLowerCase().includes(term)
      );
    }
    if (this.selectedCategory) {
      filtered = filtered.filter(s =>
        s.categories.some(c => c.toLowerCase() === this.selectedCategory.toLowerCase())
      );
    }
    return filtered;
  }

  onSearch(): void {
    this.searchSubject.next(this.searchTerm);
  }

  onCategoryChange(): void {
    this.loadShops();
  }

  selectShop(shop: Shop): void {
    if (shop.isOpen) {
      this.router.navigate(['/customer/products', shop.id], { 
        queryParams: { shopName: shop.name } 
      });
    }
  }

  testNotification(): void {
    this.firebaseService.testNotification();
  }

  resetFilters(): void {
    this.searchTerm = '';
    this.selectedCategory = '';
    this.loadShops();
  }
}
