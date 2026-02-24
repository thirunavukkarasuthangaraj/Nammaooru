import { Component, OnInit, OnDestroy } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';
import { AuthService } from '../../../../core/services/auth.service';
import { OfflineStorageService, CachedCombo } from '../../../../core/services/offline-storage.service';
import { SwalService } from '../../../../core/services/swal.service';
import { ComboFormComponent } from './combo-form.component';

interface ComboItem {
  id: number;
  shopProductId: number;
  productName: string;
  quantity: number;
  unitPrice: number;
  imageUrl?: string;
}

interface Combo {
  id: number;
  name: string;
  nameTamil?: string;
  description?: string;
  originalPrice: number;
  comboPrice: number;
  discountPercentage: number;
  startDate: string;
  endDate: string;
  active?: boolean;
  isActive?: boolean;
  bannerImageUrl?: string;
  items: ComboItem[];
  itemCount: number;
}

@Component({
  selector: 'app-combo-list',
  templateUrl: './combo-list.component.html',
  styleUrls: ['./combo-list.component.css']
})
export class ComboListComponent implements OnInit, OnDestroy {
  combos: Combo[] = [];
  isLoading = false;
  shopId: number | null = null;
  displayedColumns = ['name', 'items', 'price', 'discount', 'validity', 'status', 'actions'];

  // Offline support
  isOffline = false;
  lastSyncTime: Date | null = null;

  constructor(
    private http: HttpClient,
    private authService: AuthService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    private offlineStorage: OfflineStorageService,
    private swalService: SwalService
  ) {}

  ngOnDestroy(): void {
    window.removeEventListener('online', this.handleOnline.bind(this));
    window.removeEventListener('offline', this.handleOffline.bind(this));
  }

  private handleOnline = (): void => {
    console.log('Network online - refreshing combos');
    this.isOffline = false;
    this.snackBar.open('Back online! Refreshing combos...', 'Close', { duration: 3000 });
    this.loadCombos();
  }

  private handleOffline = (): void => {
    console.log('Network offline - using cached combos');
    this.isOffline = true;
    this.snackBar.open('You are offline. Showing cached combos.', 'Close', { duration: 3000 });
  }

  getTimeSinceSync(): string {
    if (!this.lastSyncTime) return 'Never synced';

    const now = new Date();
    const diffMs = now.getTime() - this.lastSyncTime.getTime();
    const diffMins = Math.floor(diffMs / 60000);

    if (diffMins < 1) return 'Just now';
    if (diffMins === 1) return '1 minute ago';
    if (diffMins < 60) return `${diffMins} minutes ago`;

    const diffHours = Math.floor(diffMins / 60);
    if (diffHours === 1) return '1 hour ago';
    if (diffHours < 24) return `${diffHours} hours ago`;

    const diffDays = Math.floor(diffHours / 24);
    if (diffDays === 1) return '1 day ago';
    return `${diffDays} days ago`;
  }

  ngOnInit(): void {
    // Set up online/offline detection
    this.isOffline = !navigator.onLine;
    window.addEventListener('online', this.handleOnline.bind(this));
    window.addEventListener('offline', this.handleOffline.bind(this));

    this.loadShopId();
  }

  private loadShopId(): void {
    const user = this.authService.getCurrentUser();
    if (user?.shopId) {
      this.shopId = user.shopId;
      this.loadCombos();
    } else {
      this.http.get<any>(`${environment.apiUrl}/shops/my-shop`).subscribe({
        next: (response) => {
          this.shopId = response.data?.id || response.id;
          this.loadCombos();
        },
        error: () => {
          this.showSnackBar('Failed to load shop info', 'error');
        }
      });
    }
  }

  loadCombos(): void {
    if (!this.shopId) return;

    this.isLoading = true;

    // If offline, load from cache
    if (!navigator.onLine) {
      this.loadCombosFromCache();
      return;
    }

    this.http.get<any>(`${environment.apiUrl}/shops/${this.shopId}/combos`).subscribe({
      next: async (response) => {
        // API returns paginated response: { data: { content: [...] } }
        this.combos = response.data?.content || response.data || response.content || response || [];
        this.isLoading = false;
        this.isOffline = false;

        // Cache combos for offline use
        try {
          await this.offlineStorage.saveCombosCache(this.combos as CachedCombo[], this.shopId!);
          this.lastSyncTime = new Date();
          console.log('Combos cached successfully');
        } catch (cacheError) {
          console.warn('Error caching combos:', cacheError);
        }
      },
      error: async () => {
        // Try to load from cache on error
        await this.loadCombosFromCache();
      }
    });
  }

  private async loadCombosFromCache(): Promise<void> {
    if (!this.shopId) {
      this.isLoading = false;
      return;
    }

    console.log('Loading combos from cache...');
    this.isOffline = true;

    try {
      const cachedCombos = await this.offlineStorage.getCombosCache(this.shopId);
      this.lastSyncTime = await this.offlineStorage.getCombosCacheSyncTime(this.shopId);

      if (cachedCombos && cachedCombos.length > 0) {
        console.log('Loaded', cachedCombos.length, 'combos from cache');
        this.combos = cachedCombos as Combo[];
        this.showSnackBar(`Showing ${cachedCombos.length} cached combos`, 'success');
      } else {
        console.log('No cached combos found');
        this.combos = [];
        this.showSnackBar('No cached combos available. Connect to internet to load combos.', 'error');
      }
    } catch (error) {
      console.error('Error loading combos from cache:', error);
      this.showSnackBar('Failed to load cached combos', 'error');
    }

    this.isLoading = false;
  }

  openCreateDialog(): void {
    if (!this.shopId) {
      this.showSnackBar('Shop ID not loaded. Please refresh the page.', 'error');
      return;
    }
    const dialogRef = this.dialog.open(ComboFormComponent, {
      width: '800px',
      maxHeight: '90vh',
      data: { mode: 'create', shopId: this.shopId }
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.loadCombos();
      }
    });
  }

  openEditDialog(combo: Combo): void {
    // Fetch full combo details with items before opening edit dialog
    this.http.get<any>(`${environment.apiUrl}/shops/${this.shopId}/combos/${combo.id}`).subscribe({
      next: (response) => {
        const fullCombo = response.data || response;
        const dialogRef = this.dialog.open(ComboFormComponent, {
          width: '800px',
          maxHeight: '90vh',
          data: { mode: 'edit', combo: fullCombo, shopId: this.shopId }
        });

        dialogRef.afterClosed().subscribe(result => {
          if (result) {
            this.loadCombos();
          }
        });
      },
      error: () => {
        this.showSnackBar('Failed to load combo details', 'error');
      }
    });
  }

  isComboActive(combo: Combo): boolean {
    return combo.isActive ?? combo.active ?? false;
  }

  toggleStatus(combo: Combo): void {
    if (!this.shopId) return;

    const isCurrentlyActive = this.isComboActive(combo);
    const endpoint = `${environment.apiUrl}/shops/${this.shopId}/combos/${combo.id}/toggle-status`;

    this.http.patch<any>(endpoint, {}).subscribe({
      next: (response) => {
        const updatedCombo = response.data;
        combo.isActive = updatedCombo?.isActive ?? !isCurrentlyActive;
        combo.active = combo.isActive;
        this.showSnackBar(`Combo ${combo.isActive ? 'activated' : 'deactivated'}`, 'success');
      },
      error: () => {
        this.showSnackBar('Failed to update combo status', 'error');
      }
    });
  }

  async deleteCombo(combo: Combo): Promise<void> {
    if (!this.shopId) return;

    const result = await this.swalService.confirmDelete(combo.name);
    if (!result.isConfirmed) return;

    this.http.delete(`${environment.apiUrl}/shops/${this.shopId}/combos/${combo.id}`).subscribe({
      next: () => {
        this.combos = this.combos.filter(c => c.id !== combo.id);
        this.swalService.success('Deleted!', 'Combo deleted successfully');
      },
      error: () => {
        this.swalService.error('Error', 'Failed to delete combo');
      }
    });
  }

  isExpired(combo: Combo): boolean {
    return new Date(combo.endDate) < new Date();
  }

  isUpcoming(combo: Combo): boolean {
    return new Date(combo.startDate) > new Date();
  }

  getStatusClass(combo: Combo): string {
    if (!this.isComboActive(combo)) return 'status-inactive';
    if (this.isExpired(combo)) return 'status-expired';
    if (this.isUpcoming(combo)) return 'status-upcoming';
    return 'status-active';
  }

  getStatusText(combo: Combo): string {
    if (!this.isComboActive(combo)) return 'Inactive';
    if (this.isExpired(combo)) return 'Expired';
    if (this.isUpcoming(combo)) return 'Upcoming';
    return 'Active';
  }

  private showSnackBar(message: string, type: 'success' | 'error'): void {
    this.snackBar.open(message, 'Close', {
      duration: 3000,
      horizontalPosition: 'end',
      verticalPosition: 'top',
      panelClass: type === 'success' ? 'snackbar-success' : 'snackbar-error'
    });
  }

  getImageUrl(url: string | undefined): string {
    if (!url) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return `${environment.imageBaseUrl}${url.startsWith('/') ? '' : '/'}${url}`;
  }
}
