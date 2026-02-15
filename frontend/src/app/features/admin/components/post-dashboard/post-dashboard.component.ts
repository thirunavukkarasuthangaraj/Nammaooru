import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { PostDashboardService } from '../../services/post-dashboard.service';

interface PostStats {
  total: number;
  pending: number;
  approved: number;
  rejected: number;
  reported: number;
}

@Component({
  selector: 'app-post-dashboard',
  templateUrl: './post-dashboard.component.html',
  styleUrls: ['./post-dashboard.component.scss']
})
export class PostDashboardComponent implements OnInit {
  labourStats: PostStats = { total: 0, pending: 0, approved: 0, rejected: 0, reported: 0 };
  travelStats: PostStats = { total: 0, pending: 0, approved: 0, rejected: 0, reported: 0 };
  parcelStats: PostStats = { total: 0, pending: 0, approved: 0, rejected: 0, reported: 0 };
  marketplaceStats: PostStats = { total: 0, pending: 0, approved: 0, rejected: 0, reported: 0 };
  farmerStats: PostStats = { total: 0, pending: 0, approved: 0, rejected: 0, reported: 0 };
  realEstateStats: PostStats = { total: 0, pending: 0, approved: 0, rejected: 0, reported: 0 };
  isLoading = true;
  errorMessage = '';

  // Featured posts
  featuredPosts: any = {};
  featuredLoading = false;
  featuredError = '';

  constructor(
    private dashboardService: PostDashboardService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadStats();
    this.loadFeaturedPosts();
  }

  loadStats(): void {
    this.isLoading = true;
    this.errorMessage = '';
    this.dashboardService.getStats().subscribe({
      next: (response: any) => {
        const data = response.data || response;
        this.labourStats = data.labour || this.labourStats;
        this.travelStats = data.travel || this.travelStats;
        this.parcelStats = data.parcel || this.parcelStats;
        this.marketplaceStats = data.marketplace || this.marketplaceStats;
        this.farmerStats = data.farmer || this.farmerStats;
        this.realEstateStats = data.realEstate || this.realEstateStats;
        this.isLoading = false;
      },
      error: (err) => {
        this.errorMessage = 'Failed to load dashboard stats';
        this.isLoading = false;
        console.error('Dashboard stats error:', err);
      }
    });
  }

  loadFeaturedPosts(): void {
    this.featuredLoading = true;
    this.featuredError = '';
    this.dashboardService.getFeaturedPosts().subscribe({
      next: (response: any) => {
        this.featuredPosts = response.data || response || {};
        this.featuredLoading = false;
      },
      error: (err) => {
        this.featuredError = 'Failed to load featured posts';
        this.featuredLoading = false;
        console.error('Featured posts error:', err);
      }
    });
  }

  getFeaturedCount(): number {
    let count = 0;
    for (const key of Object.keys(this.featuredPosts)) {
      const items = this.featuredPosts[key];
      if (Array.isArray(items)) {
        count += items.length;
      }
    }
    return count;
  }

  getCategoryLabel(key: string): string {
    const labels: { [key: string]: string } = {
      'combos': 'Combos',
      'marketplace': 'Marketplace',
      'farmer': 'Farmer Products',
      'labour': 'Labour',
      'travel': 'Travel',
      'parcel': 'Parcel Service',
      'realEstate': 'Real Estate'
    };
    return labels[key] || key;
  }

  getCategoryIcon(key: string): string {
    const icons: { [key: string]: string } = {
      'combos': 'local_offer',
      'marketplace': 'store',
      'farmer': 'agriculture',
      'labour': 'construction',
      'travel': 'directions_car',
      'parcel': 'local_shipping',
      'realEstate': 'home'
    };
    return icons[key] || 'article';
  }

  getCategoryRoute(key: string): string {
    const routes: { [key: string]: string } = {
      'marketplace': '/admin/marketplace',
      'farmer': '/admin/farmer-products',
      'labour': '/admin/labours',
      'travel': '/admin/travels',
      'parcel': '/admin/parcels',
      'realEstate': '/admin/real-estate'
    };
    return routes[key] || '';
  }

  getPostTitle(post: any, category: string): string {
    if (category === 'combos') return post.name || 'Combo';
    if (category === 'labour') return post.name || 'Labour Post';
    if (category === 'parcel') return post.serviceName || 'Parcel Service';
    return post.title || 'Post';
  }

  getPostSubtitle(post: any, category: string): string {
    if (category === 'combos') return post.shopName ? `by ${post.shopName}` : '';
    if (category === 'labour') {
      const cat = post.category || '';
      return this.formatEnumValue(cat);
    }
    if (category === 'travel') {
      return [post.fromLocation, post.toLocation].filter(Boolean).join(' → ');
    }
    if (category === 'parcel') {
      return [post.fromLocation, post.toLocation].filter(Boolean).join(' → ');
    }
    if (category === 'realEstate') {
      const type = post.propertyType || '';
      return this.formatEnumValue(type);
    }
    return post.category ? this.formatEnumValue(post.category) : (post.location || '');
  }

  formatEnumValue(val: string): string {
    if (!val) return '';
    return val.replaceAll('_', ' ').split(' ').map(w =>
      w.length > 0 ? w[0].toUpperCase() + w.substring(1).toLowerCase() : w
    ).join(' ');
  }

  navigateTo(route: string): void {
    if (route) {
      this.router.navigate([route]);
    }
  }
}
