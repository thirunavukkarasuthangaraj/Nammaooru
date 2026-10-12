import { Component, OnInit } from '@angular/core';
import { DeliveryHour, DeliveryHoursService } from '../../services/delivery-hours.service';
import { MatSnackBar } from '@angular/material/snack-bar';

const DAYS: { key: string; label: string }[] = [
  { key: 'MONDAY', label: 'Monday' },
  { key: 'TUESDAY', label: 'Tuesday' },
  { key: 'WEDNESDAY', label: 'Wednesday' },
  { key: 'THURSDAY', label: 'Thursday' },
  { key: 'FRIDAY', label: 'Friday' },
  { key: 'SATURDAY', label: 'Saturday' },
  { key: 'SUNDAY', label: 'Sunday' },
];

/**
 * Editor for when a shop DELIVERS, which is a different question from when it is open.
 *
 * These hours are what generate the delivery windows a customer can book, so a window
 * can never be offered for a time the shop does not deliver. Most shops never need the
 * two to differ, which is why this screen defaults to "Same as opening hours" and only
 * becomes editable when that is switched off.
 */
@Component({
  selector: 'app-delivery-hours',
  templateUrl: './delivery-hours.component.html',
  styleUrls: ['./delivery-hours.component.scss'],
})
export class DeliveryHoursComponent implements OnInit {
  readonly days = DAYS;

  shopId: number | null = null;
  loading = false;
  saving = false;

  /** When on, delivery hours mirror opening hours and the grid is read-only. */
  sameAsBusinessHours = true;

  hours: DeliveryHour[] = [];

  constructor(
    private deliveryHoursService: DeliveryHoursService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    const stored = localStorage.getItem('current_shop_id');
    this.shopId = stored ? parseInt(stored, 10) : null;
    if (this.shopId) {
      this.load();
    }
  }

  private blankWeek(): DeliveryHour[] {
    return DAYS.map(d => ({
      dayOfWeek: d.key,
      openTime: '09:00',
      closeTime: '21:00',
      isOpen: true,
      is24Hours: false,
    }));
  }

  load(): void {
    if (!this.shopId) return;
    this.loading = true;

    this.deliveryHoursService.getByShop(this.shopId).subscribe({
      next: rows => {
        // Order the API rows by weekday and fill in any day the shop has never set,
        // so the grid always shows seven rows rather than a ragged list.
        this.hours = DAYS.map(d => {
          const match = rows.find(r => r.dayOfWeek === d.key);
          return match ?? {
            dayOfWeek: d.key,
            openTime: null,
            closeTime: null,
            isOpen: false,
            is24Hours: false,
          };
        });
        this.loading = false;
      },
      error: () => {
        this.hours = this.blankWeek();
        this.loading = false;
        this.snackBar.open('Could not load delivery hours', 'Close', { duration: 4000 });
      },
    });

    this.deliveryHoursService.matchesBusinessHours(this.shopId).subscribe({
      next: res => (this.sameAsBusinessHours = res.matches),
      error: () => (this.sameAsBusinessHours = false),
    });
  }

  label(dayKey: string): string {
    return DAYS.find(d => d.key === dayKey)?.label ?? dayKey;
  }

  /**
   * Turning the toggle back on copies opening hours across immediately, so the shop can
   * see what it reverted to rather than being told it happened.
   */
  onSameAsBusinessHoursChange(enabled: boolean): void {
    this.sameAsBusinessHours = enabled;
    if (!enabled || !this.shopId) return;

    this.saving = true;
    this.deliveryHoursService.copyFromBusinessHours(this.shopId).subscribe({
      next: () => {
        this.saving = false;
        this.snackBar.open('Delivery hours now match your opening hours', 'Close', { duration: 3000 });
        this.load();
      },
      error: () => {
        this.saving = false;
        this.sameAsBusinessHours = false;
        this.snackBar.open('Could not copy your opening hours', 'Close', { duration: 4000 });
      },
    });
  }

  copyFirstOpenDayToAll(): void {
    const source = this.hours.find(h => h.isOpen);
    if (!source) return;
    this.hours = this.hours.map(h => ({
      ...h,
      openTime: source.openTime,
      closeTime: source.closeTime,
      breakStartTime: source.breakStartTime,
      breakEndTime: source.breakEndTime,
      isOpen: true,
    }));
  }

  /** A day a shop does not deliver produces no windows at all, which is the point. */
  private invalidDays(): string[] {
    return this.hours
      .filter(h => h.isOpen && !h.is24Hours)
      .filter(h => !h.openTime || !h.closeTime || h.openTime >= h.closeTime)
      .map(h => this.label(h.dayOfWeek));
  }

  save(): void {
    if (!this.shopId) return;

    const bad = this.invalidDays();
    if (bad.length) {
      this.snackBar.open(
        `Closing time must be after opening time: ${bad.join(', ')}`,
        'Close',
        { duration: 5000 }
      );
      return;
    }

    this.saving = true;
    this.deliveryHoursService.replaceWeek(this.shopId, this.hours).subscribe({
      next: () => {
        this.saving = false;
        this.sameAsBusinessHours = false;
        this.snackBar.open('Delivery hours saved', 'Close', { duration: 3000 });
      },
      error: () => {
        this.saving = false;
        this.snackBar.open('Could not save delivery hours', 'Close', { duration: 4000 });
      },
    });
  }
}
