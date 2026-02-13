import { Component, OnInit } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { BusTimingService, BusTiming } from '../../../../core/services/bus-timing.service';

interface BusStop {
  name: string;
  time: string;
}

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
  newStops: BusStop[] = [];
  editingTiming: BusTiming | null = null;
  editingStops: BusStop[] = [];
  isAddingTiming = false;

  displayedColumns = ['busNumber', 'route', 'stops', 'busType', 'operatingDays', 'fare', 'locationArea', 'status', 'actions'];

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

  // --- Stops management ---

  addStop(stops: BusStop[]): void {
    stops.push({ name: '', time: '' });
  }

  removeStop(stops: BusStop[], index: number): void {
    stops.splice(index, 1);
  }

  autoCalculateTimes(stops: BusStop[], departureTime: string, arrivalTime: string): void {
    if (!departureTime || !arrivalTime || stops.length === 0) {
      this.snackBar.open('Enter departure time, arrival time, and at least one stop', 'Close', { duration: 3000 });
      return;
    }

    const depMinutes = this.timeToMinutes(departureTime);
    const arrMinutes = this.timeToMinutes(arrivalTime);

    if (depMinutes === null || arrMinutes === null) {
      this.snackBar.open('Invalid time format. Use HH:MM AM/PM (e.g., 06:30 AM)', 'Close', { duration: 3000 });
      return;
    }

    const totalMinutes = arrMinutes > depMinutes ? arrMinutes - depMinutes : (arrMinutes + 1440) - depMinutes;
    const interval = totalMinutes / (stops.length + 1);

    for (let i = 0; i < stops.length; i++) {
      const stopMinutes = depMinutes + Math.round(interval * (i + 1));
      stops[i].time = this.minutesToTime(stopMinutes % 1440);
    }
  }

  timeToMinutes(timeStr: string): number | null {
    if (!timeStr) return null;
    const clean = timeStr.trim().toUpperCase();

    // Try HH:MM AM/PM format
    const match12 = clean.match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/);
    if (match12) {
      let hours = parseInt(match12[1], 10);
      const minutes = parseInt(match12[2], 10);
      const period = match12[3];
      if (period === 'PM' && hours !== 12) hours += 12;
      if (period === 'AM' && hours === 12) hours = 0;
      return hours * 60 + minutes;
    }

    // Try HH:MMAM/PM (no space)
    const matchNoSpace = clean.match(/^(\d{1,2}):(\d{2})(AM|PM)$/);
    if (matchNoSpace) {
      let hours = parseInt(matchNoSpace[1], 10);
      const minutes = parseInt(matchNoSpace[2], 10);
      const period = matchNoSpace[3];
      if (period === 'PM' && hours !== 12) hours += 12;
      if (period === 'AM' && hours === 12) hours = 0;
      return hours * 60 + minutes;
    }

    // Try 24-hour HH:MM
    const match24 = clean.match(/^(\d{1,2}):(\d{2})$/);
    if (match24) {
      return parseInt(match24[1], 10) * 60 + parseInt(match24[2], 10);
    }

    return null;
  }

  minutesToTime(totalMinutes: number): string {
    let hours = Math.floor(totalMinutes / 60) % 24;
    const minutes = totalMinutes % 60;
    const period = hours >= 12 ? 'PM' : 'AM';
    if (hours === 0) hours = 12;
    else if (hours > 12) hours -= 12;
    return `${hours}:${minutes.toString().padStart(2, '0')} ${period}`;
  }

  stopsToJson(stops: BusStop[]): string {
    const validStops = stops.filter(s => s.name.trim());
    if (validStops.length === 0) return '';
    return JSON.stringify(validStops);
  }

  jsonToStops(json: string): BusStop[] {
    if (!json) return [];
    try {
      const parsed = JSON.parse(json);
      if (Array.isArray(parsed)) {
        return parsed.map((s: any) => ({ name: s.name || '', time: s.time || '' }));
      }
    } catch {
      // Legacy comma-separated format
      if (json.includes(',') || json.trim().length > 0) {
        return json.split(',').map(s => ({ name: s.trim(), time: '' }));
      }
    }
    return [];
  }

  getStopsDisplay(viaStops: string): BusStop[] {
    return this.jsonToStops(viaStops);
  }

  getStopsCount(viaStops: string): number {
    return this.getStopsDisplay(viaStops).length;
  }

  // --- CRUD ---

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
    this.newStops = [];
  }

  cancelAdding(): void {
    this.isAddingTiming = false;
    this.newTiming = this.getEmptyTiming();
    this.newStops = [];
  }

  addTiming(): void {
    if (!this.validateTiming(this.newTiming)) return;

    // Serialize stops to JSON
    this.newTiming.viaStops = this.stopsToJson(this.newStops);

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
    this.editingStops = this.jsonToStops(timing.viaStops);
  }

  cancelEditing(): void {
    this.editingTiming = null;
    this.editingStops = [];
  }

  updateTiming(timing: BusTiming): void {
    if (!timing.id || !this.validateTiming(timing)) return;

    timing.viaStops = this.stopsToJson(this.editingStops);

    this.busTimingService.updateBusTiming(timing.id, timing).subscribe({
      next: (response) => {
        if (response.success) {
          this.snackBar.open('Bus timing updated successfully', 'Close', { duration: 3000 });
          this.loadTimings();
          this.editingTiming = null;
          this.editingStops = [];
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
