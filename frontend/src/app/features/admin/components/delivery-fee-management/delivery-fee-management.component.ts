import { Component, OnInit } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatDialog } from '@angular/material/dialog';
import { DeliveryFeeService, DeliveryFeeRange } from '../../../../core/services/delivery-fee.service';

@Component({
  selector: 'app-delivery-fee-management',
  templateUrl: './delivery-fee-management.component.html',
  styleUrls: ['./delivery-fee-management.component.scss']
})
export class DeliveryFeeManagementComponent implements OnInit {

  ranges: DeliveryFeeRange[] = [];
  isLoading = false;
  newRange: DeliveryFeeRange = {
    minDistanceKm: 0,
    maxDistanceKm: 0,
    deliveryFee: 0,
    partnerCommission: 0,
    isActive: true
  };
  editingRange: DeliveryFeeRange | null = null;
  isAddingRange = false;

  constructor(
    private deliveryFeeService: DeliveryFeeService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadRanges();
  }

  loadRanges(): void {
    this.isLoading = true;
    this.deliveryFeeService.getAllRanges().subscribe({
      next: (response) => {
        if (response.success) {
          this.ranges = response.data || [];
        } else {
          this.snackBar.open('Failed to load delivery fee ranges', 'Close', { duration: 3000 });
        }
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading ranges:', error);
        this.snackBar.open('Error loading delivery fee ranges', 'Close', { duration: 3000 });
        this.isLoading = false;
      }
    });
  }

  addRange(): void {
    if (!this.validateRange(this.newRange)) {
      return;
    }

    this.deliveryFeeService.createRange(this.newRange).subscribe({
      next: (response) => {
        if (response.success) {
          this.snackBar.open('Delivery fee range created successfully', 'Close', { duration: 3000 });
          this.loadRanges();
          this.resetNewRange();
          this.isAddingRange = false;
        } else {
          this.snackBar.open(response.message || 'Failed to create range', 'Close', { duration: 3000 });
        }
      },
      error: (error) => {
        console.error('Error creating range:', error);
        this.snackBar.open('Error creating delivery fee range', 'Close', { duration: 3000 });
      }
    });
  }

  updateRange(range: DeliveryFeeRange): void {
    if (!range.id || !this.validateRange(range)) {
      return;
    }

    this.deliveryFeeService.updateRange(range.id, range).subscribe({
      next: (response) => {
        if (response.success) {
          this.snackBar.open('Delivery fee range updated successfully', 'Close', { duration: 3000 });
          this.loadRanges();
          this.editingRange = null;
        } else {
          this.snackBar.open(response.message || 'Failed to update range', 'Close', { duration: 3000 });
        }
      },
      error: (error) => {
        console.error('Error updating range:', error);
        this.snackBar.open('Error updating delivery fee range', 'Close', { duration: 3000 });
      }
    });
  }

  deleteRange(id: number): void {
    if (!confirm('Are you sure you want to delete this delivery fee range?')) {
      return;
    }

    this.deliveryFeeService.deleteRange(id).subscribe({
      next: (response) => {
        if (response.success) {
          this.snackBar.open('Delivery fee range deleted successfully', 'Close', { duration: 3000 });
          this.loadRanges();
        } else {
          this.snackBar.open(response.message || 'Failed to delete range', 'Close', { duration: 3000 });
        }
      },
      error: (error) => {
        console.error('Error deleting range:', error);
        this.snackBar.open('Error deleting delivery fee range', 'Close', { duration: 3000 });
      }
    });
  }

  startEditing(range: DeliveryFeeRange): void {
    this.editingRange = { ...range };
  }

  cancelEditing(): void {
    this.editingRange = null;
  }

  startAdding(): void {
    this.isAddingRange = true;
    this.resetNewRange();
  }

  cancelAdding(): void {
    this.isAddingRange = false;
    this.resetNewRange();
  }

  resetNewRange(): void {
    this.newRange = {
      minDistanceKm: 0,
      maxDistanceKm: 0,
      deliveryFee: 0,
      partnerCommission: 0,
      isActive: true
    };
  }

  validateRange(range: DeliveryFeeRange): boolean {
    if (range.minDistanceKm < 0 || range.maxDistanceKm <= 0) {
      this.snackBar.open('Distance values must be positive', 'Close', { duration: 3000 });
      return false;
    }

    if (range.minDistanceKm >= range.maxDistanceKm) {
      this.snackBar.open('Maximum distance must be greater than minimum distance', 'Close', { duration: 3000 });
      return false;
    }

    if (range.deliveryFee <= 0 || range.partnerCommission <= 0) {
      this.snackBar.open('Fee and commission must be positive values', 'Close', { duration: 3000 });
      return false;
    }

    if (range.partnerCommission >= range.deliveryFee) {
      this.snackBar.open('Partner commission must be less than delivery fee', 'Close', { duration: 3000 });
      return false;
    }

    return true;
  }

  getDistanceRangeText(range: DeliveryFeeRange): string {
    if (range.maxDistanceKm >= 999) {
      return `${range.minDistanceKm}+ km`;
    }
    return `${range.minDistanceKm} - ${range.maxDistanceKm} km`;
  }
}