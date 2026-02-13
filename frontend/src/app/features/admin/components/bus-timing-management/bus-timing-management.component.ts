import { Component, OnInit } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { BusTimingService, BusTiming } from '../../../../core/services/bus-timing.service';

@Component({
  selector: 'app-bus-timing-management',
  templateUrl: './bus-timing-management.component.html',
  styleUrls: ['./bus-timing-management.component.scss']
})
export class BusTimingManagementComponent implements OnInit {

  timings: BusTiming[] = [];
  filteredTimings: BusTiming[] = [];
  isLoading = false;
  searchTerm = '';
  filterLocation = '';
  locationOptions: string[] = [];

  newTiming: BusTiming = this.getEmptyTiming();
  editingTiming: BusTiming | null = null;
  isAddingTiming = false;

  displayedColumns = ['busNumber', 'route', 'departureTime', 'arrivalTime', 'busType', 'operatingDays', 'fare', 'locationArea', 'status', 'actions'];

  busTypeOptions = [
    { value: 'GOVERNMENT', label: 'Government' },
    { value: 'PRIVATE', label: 'Private' }
  ];

  operatingDaysOptions = [
    { value: 'DAILY', label: 'Daily' },
    { value: 'WEEKDAYS', label: 'Weekdays (Mon-Fri)' },
    { value: 'WEEKENDS', label: 'Weekends (Sat-Sun)' },
    { value: 'MON,WED,FRI', label: 'Mon, Wed, Fri' },
    { value: 'TUE,THU,SAT', label: 'Tue, Thu, Sat' }
  ];

  constructor(
    private busTimingService: BusTimingService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadTimings();
  }

  getEmptyTiming(): BusTiming {
    return {
      busNumber: '',
      busName: '',
      routeFrom: '',
      routeTo: '',
      viaStops: '',
      departureTime: '',
      arrivalTime: '',
      busType: 'GOVERNMENT',
      operatingDays: 'DAILY',
      fare: 0,
      locationArea: '',
      isActive: true
    };
  }

  loadTimings(): void {
    this.isLoading = true;
    this.busTimingService.getAllBusTimings().subscribe({
      next: (response) => {
        if (response.success) {
          this.timings = response.data || [];
          this.extractLocationOptions();
          this.applyFilters();
        } else {
          this.snackBar.open('Failed to load bus timings', 'Close', { duration: 3000 });
        }
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading bus timings:', error);
        this.snackBar.open('Error loading bus timings', 'Close', { duration: 3000 });
        this.isLoading = false;
      }
    });
  }

  extractLocationOptions(): void {
    const locations = new Set(this.timings.map(t => t.locationArea).filter(l => l));
    this.locationOptions = Array.from(locations).sort();
  }

  applyFilters(): void {
    let filtered = [...this.timings];

    if (this.filterLocation) {
      filtered = filtered.filter(t => t.locationArea === this.filterLocation);
    }

    if (this.searchTerm) {
      const term = this.searchTerm.toLowerCase();
      filtered = filtered.filter(t =>
        t.busNumber?.toLowerCase().includes(term) ||
        t.busName?.toLowerCase().includes(term) ||
        t.routeFrom?.toLowerCase().includes(term) ||
        t.routeTo?.toLowerCase().includes(term) ||
        t.viaStops?.toLowerCase().includes(term)
      );
    }

    this.filteredTimings = filtered;
  }

  onSearchChange(): void {
    this.applyFilters();
  }

  onLocationFilterChange(): void {
    this.applyFilters();
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.filterLocation = '';
    this.applyFilters();
  }

  startAdding(): void {
    this.isAddingTiming = true;
    this.newTiming = this.getEmptyTiming();
  }

  cancelAdding(): void {
    this.isAddingTiming = false;
    this.newTiming = this.getEmptyTiming();
  }

  addTiming(): void {
    if (!this.validateTiming(this.newTiming)) return;

    this.busTimingService.createBusTiming(this.newTiming).subscribe({
      next: (response) => {
        if (response.success) {
          this.snackBar.open('Bus timing created successfully', 'Close', { duration: 3000 });
          this.loadTimings();
          this.cancelAdding();
        } else {
          this.snackBar.open(response.message || 'Failed to create bus timing', 'Close', { duration: 3000 });
        }
      },
      error: (error) => {
        console.error('Error creating bus timing:', error);
        this.snackBar.open('Error creating bus timing', 'Close', { duration: 3000 });
      }
    });
  }

  startEditing(timing: BusTiming): void {
    this.editingTiming = { ...timing };
  }

  cancelEditing(): void {
    this.editingTiming = null;
  }

  updateTiming(timing: BusTiming): void {
    if (!timing.id || !this.validateTiming(timing)) return;

    this.busTimingService.updateBusTiming(timing.id, timing).subscribe({
      next: (response) => {
        if (response.success) {
          this.snackBar.open('Bus timing updated successfully', 'Close', { duration: 3000 });
          this.loadTimings();
          this.editingTiming = null;
        } else {
          this.snackBar.open(response.message || 'Failed to update bus timing', 'Close', { duration: 3000 });
        }
      },
      error: (error) => {
        console.error('Error updating bus timing:', error);
        this.snackBar.open('Error updating bus timing', 'Close', { duration: 3000 });
      }
    });
  }

  deleteTiming(id: number): void {
    if (!confirm('Are you sure you want to delete this bus timing?')) return;

    this.busTimingService.deleteBusTiming(id).subscribe({
      next: (response) => {
        if (response.success) {
          this.snackBar.open('Bus timing deleted successfully', 'Close', { duration: 3000 });
          this.loadTimings();
        } else {
          this.snackBar.open(response.message || 'Failed to delete bus timing', 'Close', { duration: 3000 });
        }
      },
      error: (error) => {
        console.error('Error deleting bus timing:', error);
        this.snackBar.open('Error deleting bus timing', 'Close', { duration: 3000 });
      }
    });
  }

  validateTiming(timing: BusTiming): boolean {
    if (!timing.busNumber?.trim()) {
      this.snackBar.open('Bus number is required', 'Close', { duration: 3000 });
      return false;
    }
    if (!timing.routeFrom?.trim()) {
      this.snackBar.open('Route From is required', 'Close', { duration: 3000 });
      return false;
    }
    if (!timing.routeTo?.trim()) {
      this.snackBar.open('Route To is required', 'Close', { duration: 3000 });
      return false;
    }
    if (!timing.departureTime?.trim()) {
      this.snackBar.open('Departure time is required', 'Close', { duration: 3000 });
      return false;
    }
    if (!timing.locationArea?.trim()) {
      this.snackBar.open('Location area is required', 'Close', { duration: 3000 });
      return false;
    }
    return true;
  }

  getBusTypeLabel(type: string): string {
    return type === 'GOVERNMENT' ? 'Govt' : 'Private';
  }

  getOperatingDaysLabel(days: string): string {
    const labels: {[key: string]: string} = {
      'DAILY': 'Daily',
      'WEEKDAYS': 'Mon-Fri',
      'WEEKENDS': 'Sat-Sun'
    };
    return labels[days] || days;
  }
}
