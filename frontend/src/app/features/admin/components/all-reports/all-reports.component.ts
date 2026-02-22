import { Component, OnInit } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MarketplaceAdminService } from '../../services/marketplace.service';
import { FarmerProductsAdminService } from '../../services/farmer-products.service';
import { LabourAdminService } from '../../services/labour.service';
import { TravelAdminService } from '../../services/travel.service';
import { ParcelAdminService } from '../../services/parcel.service';
import { RentalAdminService } from '../../services/rental.service';
import { RealEstateAdminService } from '../../services/real-estate.service';
import { getImageUrl } from '../../../../core/utils/image-url.util';

interface StatusOption {
  value: string;
  label: string;
  icon: string;
  color: string;
}

interface TabState {
  posts: any[];
  loading: boolean;
  loaded: boolean;
  currentPage: number;
  totalPages: number;
  totalItems: number;
}

@Component({
  selector: 'app-all-reports',
  templateUrl: './all-reports.component.html',
  styleUrls: ['./all-reports.component.scss']
})
export class AllReportsComponent implements OnInit {
  selectedTabIndex = 0;
  pageSize = 20;

  statusOptions: StatusOption[] = [
    { value: 'APPROVED', label: 'Approve', icon: 'check_circle', color: '#4caf50' },
    { value: 'REJECTED', label: 'Reject', icon: 'cancel', color: '#f44336' },
    { value: 'HOLD', label: 'Hold', icon: 'pause_circle', color: '#ff9800' },
    { value: 'HIDDEN', label: 'Hide', icon: 'visibility_off', color: '#9e9e9e' },
    { value: 'CORRECTION_REQUIRED', label: 'Correction Required', icon: 'edit_note', color: '#2196f3' },
    { value: 'REMOVED', label: 'Remove', icon: 'delete_forever', color: '#b71c1c' }
  ];

  tabs = [
    { key: 'marketplace', label: 'Marketplace', icon: 'storefront' },
    { key: 'farmer', label: 'Farmer Products', icon: 'eco' },
    { key: 'labour', label: 'Labours', icon: 'construction' },
    { key: 'travel', label: 'Travels', icon: 'directions_car' },
    { key: 'parcel', label: 'Packers & Movers', icon: 'local_shipping' },
    { key: 'rental', label: 'Rentals', icon: 'vpn_key' },
    { key: 'realestate', label: 'Real Estate', icon: 'home_work' }
  ];

  tabStates: { [key: string]: TabState } = {};

  constructor(
    private marketplaceService: MarketplaceAdminService,
    private farmerService: FarmerProductsAdminService,
    private labourService: LabourAdminService,
    private travelService: TravelAdminService,
    private parcelService: ParcelAdminService,
    private rentalService: RentalAdminService,
    private realEstateService: RealEstateAdminService,
    private snackBar: MatSnackBar
  ) {
    for (const tab of this.tabs) {
      this.tabStates[tab.key] = {
        posts: [],
        loading: false,
        loaded: false,
        currentPage: 0,
        totalPages: 0,
        totalItems: 0
      };
    }
  }

  ngOnInit(): void {
    this.loadTab('marketplace');
  }

  onTabChange(index: number): void {
    this.selectedTabIndex = index;
    const tab = this.tabs[index];
    if (!this.tabStates[tab.key].loaded) {
      this.loadTab(tab.key);
    }
  }

  loadTab(key: string): void {
    const state = this.tabStates[key];
    state.loading = true;

    const service = this.getService(key);
    if (!service) return;

    service.getReportedPosts(state.currentPage, this.pageSize).subscribe({
      next: (response: any) => {
        const data = response.data;
        state.posts = data?.content || [];
        state.totalPages = data?.totalPages || 0;
        state.totalItems = data?.totalItems || 0;
        state.loading = false;
        state.loaded = true;
      },
      error: (err: any) => {
        console.error(`Error loading ${key} reported posts:`, err);
        state.loading = false;
        state.loaded = true;
        this.snackBar.open(`Failed to load ${key} reported posts`, 'Close', { duration: 3000 });
      }
    });
  }

  onPageChange(key: string, page: number): void {
    this.tabStates[key].currentPage = page;
    this.loadTab(key);
  }

  onStatusChange(key: string, post: any, newStatus: string): void {
    const postName = post.title || post.name || post.serviceName || 'Post';

    if (newStatus === 'REMOVED') {
      if (!confirm(`Remove "${postName}" permanently? This will delete the post.`)) {
        return;
      }
      const service = this.getService(key);
      if (!service) return;
      service.deletePost(post.id).subscribe({
        next: () => {
          this.snackBar.open(`"${postName}" removed`, 'OK', { duration: 3000 });
          this.loadTab(key);
        },
        error: () => {
          this.snackBar.open('Failed to remove post', 'Close', { duration: 3000 });
        }
      });
      return;
    }

    const option = this.statusOptions.find(o => o.value === newStatus);
    const label = option?.label || newStatus;
    const service = this.getService(key);
    if (!service) return;

    service.changePostStatus(post.id, newStatus).subscribe({
      next: () => {
        this.snackBar.open(`"${postName}" → ${label}`, 'OK', { duration: 3000 });
        this.loadTab(key);
      },
      error: () => {
        this.snackBar.open(`Failed to change status to ${label}`, 'Close', { duration: 3000 });
      }
    });
  }

  private getService(key: string): any {
    switch (key) {
      case 'marketplace': return this.marketplaceService;
      case 'farmer': return this.farmerService;
      case 'labour': return this.labourService;
      case 'travel': return this.travelService;
      case 'parcel': return this.parcelService;
      case 'rental': return this.rentalService;
      case 'realestate': return this.realEstateService;
      default: return null;
    }
  }

  // Image helpers
  getImageUrl(path: string | null): string {
    return getImageUrl(path);
  }

  getFirstImage(imageUrls: string | null): string {
    if (!imageUrls) return '';
    const first = imageUrls.split(',')[0]?.trim();
    return getImageUrl(first || null);
  }

  // Label helpers
  getStatusLabel(status: string): string {
    switch (status) {
      case 'FLAGGED': return 'Flagged';
      case 'PENDING_APPROVAL': return 'Pending';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      case 'SOLD': return 'Sold';
      case 'RENTED': return 'Rented';
      case 'HOLD': return 'On Hold';
      case 'HIDDEN': return 'Hidden';
      case 'CORRECTION_REQUIRED': return 'Correction Required';
      case 'REMOVED': return 'Removed';
      default: return status;
    }
  }

  getAvailableStatuses(post: any): StatusOption[] {
    return this.statusOptions.filter(o => o.value !== post.status);
  }

  formatPrice(price: number | null): string {
    if (price === null || price === undefined) return 'Negotiable';
    return '\u20B9' + price.toLocaleString('en-IN');
  }

  formatDate(dateStr: string): string {
    if (!dateStr) return '';
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  getLabourCategoryLabel(category: string): string {
    switch (category) {
      case 'PAINTER': return 'Painter';
      case 'ELECTRICIAN': return 'Electrician';
      case 'PLUMBER': return 'Plumber';
      case 'CARPENTER': return 'Carpenter';
      case 'MASON': return 'Mason';
      case 'WELDER': return 'Welder';
      case 'MECHANIC': return 'Mechanic';
      case 'DRIVER': return 'Driver';
      case 'CLEANER': return 'Cleaner';
      case 'GARDENER': return 'Gardener';
      case 'COOK': return 'Cook';
      case 'TAILOR': return 'Tailor';
      case 'AC_TECHNICIAN': return 'AC Technician';
      case 'CCTV_TECHNICIAN': return 'CCTV Technician';
      case 'COMPUTER_TECHNICIAN': return 'Computer Technician';
      case 'MOBILE_TECHNICIAN': return 'Mobile Technician';
      case 'OTHER': return 'Other';
      default: return category;
    }
  }

  getVehicleTypeLabel(type: string): string {
    switch (type) {
      case 'CAR': return 'Car';
      case 'SMALL_BUS': return 'Small Bus';
      case 'BUS': return 'Bus';
      default: return type;
    }
  }

  getServiceTypeLabel(type: string): string {
    switch (type) {
      case 'DOOR_TO_DOOR': return 'Door to Door';
      case 'PICKUP_POINT': return 'Pickup Point';
      case 'BOTH': return 'Both';
      default: return type;
    }
  }

  getRentalCategoryLabel(category: string): string {
    switch (category) {
      case 'SHOP': return 'Shop';
      case 'AUTO': return 'Auto';
      case 'BIKE': return 'Bike';
      case 'HOUSE': return 'House';
      case 'LAND': return 'Land';
      case 'EQUIPMENT': return 'Equipment';
      case 'FURNITURE': return 'Furniture';
      default: return category;
    }
  }
}
