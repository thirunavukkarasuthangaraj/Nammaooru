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
    this.loadShops();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadShops(): void {
    this.loading = true;
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
}
