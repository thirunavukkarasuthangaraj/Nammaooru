import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { DeliveryFeeService, DeliveryFeeRange } from '../../../../core/services/delivery-fee.service';
import { SwalService } from '../../../../core/services/swal.service';

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
    private swal: SwalService
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
          this.swal.toast('Failed to load delivery fee ranges', 'error');
        }
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading ranges:', error);
        this.swal.toast('Error loading delivery fee ranges', 'error');
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
          this.swal.toast('Delivery fee range created successfully', 'success');
          this.loadRanges();
          this.resetNewRange();
          this.isAddingRange = false;
        } else {
          this.swal.toast(response.message || 'Failed to create range', 'error');
        }
      },
      error: (error) => {
        console.error('Error creating range:', error);
        this.swal.toast('Error creating delivery fee range', 'error');
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
          this.swal.toast('Delivery fee range updated successfully', 'success');
          this.loadRanges();
          this.editingRange = null;
        } else {
          this.swal.toast(response.message || 'Failed to update range', 'error');
        }
      },
      error: (error) => {
        console.error('Error updating range:', error);
        this.swal.toast('Error updating delivery fee range', 'error');
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
          this.swal.toast('Delivery fee range deleted successfully', 'success');
          this.loadRanges();
        } else {
          this.swal.toast(response.message || 'Failed to delete range', 'error');
        }
      },
      error: (error) => {
        console.error('Error deleting range:', error);
        this.swal.toast('Error deleting delivery fee range', 'error');
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
      this.swal.toast('Distance values must be positive', 'warning');
      return false;
    }

    if (range.minDistanceKm >= range.maxDistanceKm) {
      this.swal.toast('Maximum distance must be greater than minimum distance', 'warning');
      return false;
    }

    if (range.deliveryFee <= 0 || range.partnerCommission <= 0) {
      this.swal.toast('Fee and commission must be positive values', 'warning');
      return false;
    }

    if (range.partnerCommission >= range.deliveryFee) {
      this.swal.toast('Partner commission must be less than delivery fee', 'warning');
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