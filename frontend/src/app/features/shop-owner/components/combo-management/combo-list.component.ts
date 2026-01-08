import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';
import { AuthService } from '../../../../core/services/auth.service';
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
  active: boolean;
  bannerImageUrl?: string;
  items: ComboItem[];
  itemCount: number;
}

@Component({
  selector: 'app-combo-list',
  templateUrl: './combo-list.component.html',
  styleUrls: ['./combo-list.component.css']
})
export class ComboListComponent implements OnInit {
  combos: Combo[] = [];
  isLoading = false;
  shopId: number | null = null;
  displayedColumns = ['name', 'items', 'price', 'discount', 'validity', 'status', 'actions'];

  constructor(
    private http: HttpClient,
    private authService: AuthService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
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
    this.http.get<any>(`${environment.apiUrl}/shops/${this.shopId}/combos`).subscribe({
      next: (response) => {
        this.combos = response.data || response || [];
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading combos:', error);
        this.isLoading = false;
        this.showSnackBar('Failed to load combos', 'error');
      }
    });
  }

  openCreateDialog(): void {
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
    const dialogRef = this.dialog.open(ComboFormComponent, {
      width: '800px',
      maxHeight: '90vh',
      data: { mode: 'edit', combo, shopId: this.shopId }
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.loadCombos();
      }
    });
  }

  toggleStatus(combo: Combo): void {
    if (!this.shopId) return;

    const endpoint = combo.active
      ? `${environment.apiUrl}/shops/${this.shopId}/combos/${combo.id}/deactivate`
      : `${environment.apiUrl}/shops/${this.shopId}/combos/${combo.id}/activate`;

    this.http.patch<any>(endpoint, {}).subscribe({
      next: () => {
        combo.active = !combo.active;
        this.showSnackBar(`Combo ${combo.active ? 'activated' : 'deactivated'}`, 'success');
      },
      error: () => {
        this.showSnackBar('Failed to update combo status', 'error');
      }
    });
  }

  deleteCombo(combo: Combo): void {
    if (!this.shopId) return;
    if (!confirm(`Are you sure you want to delete "${combo.name}"?`)) return;

    this.http.delete(`${environment.apiUrl}/shops/${this.shopId}/combos/${combo.id}`).subscribe({
      next: () => {
        this.combos = this.combos.filter(c => c.id !== combo.id);
        this.showSnackBar('Combo deleted successfully', 'success');
      },
      error: () => {
        this.showSnackBar('Failed to delete combo', 'error');
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
    if (!combo.active) return 'status-inactive';
    if (this.isExpired(combo)) return 'status-expired';
    if (this.isUpcoming(combo)) return 'status-upcoming';
    return 'status-active';
  }

  getStatusText(combo: Combo): string {
    if (!combo.active) return 'Inactive';
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
}
