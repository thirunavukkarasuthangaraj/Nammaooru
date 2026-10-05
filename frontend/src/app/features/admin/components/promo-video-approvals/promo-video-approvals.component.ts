import { Component, OnInit } from '@angular/core';
import { PromoCodeService, PromoVideoReviewItem } from '../../../../core/services/promo-code.service';
import { SwalService } from '../../../../core/services/swal.service';
import { environment } from '../../../../../environments/environment';

type ReviewFilter = 'PENDING' | 'APPROVED' | 'REJECTED';

/**
 * Super-admin review queue for promotion banner videos.
 *
 * A shop owner's video is uploaded and attached to their promo, but the
 * customer home carousel never receives it until it is approved here - the
 * /promotions/active API omits videoUrl entirely for anything not APPROVED.
 */
@Component({
  selector: 'app-promo-video-approvals',
  templateUrl: './promo-video-approvals.component.html',
  styleUrls: ['./promo-video-approvals.component.css']
})
export class PromoVideoApprovalsComponent implements OnInit {
  items: PromoVideoReviewItem[] = [];
  isLoading = false;
  filter: ReviewFilter = 'PENDING';
  // Ids currently being approved/rejected, so one slow request doesn't lock
  // the whole queue (and a card can't be double-submitted).
  busyIds = new Set<number>();

  filters: { value: ReviewFilter; label: string; icon: string }[] = [
    { value: 'PENDING', label: 'Waiting', icon: 'hourglass_top' },
    { value: 'APPROVED', label: 'Approved', icon: 'check_circle' },
    { value: 'REJECTED', label: 'Rejected', icon: 'cancel' }
  ];

  constructor(
    private promoCodeService: PromoCodeService,
    private swal: SwalService
  ) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.isLoading = true;
    this.promoCodeService.getVideoReviewQueue(this.filter).subscribe({
      next: (items) => {
        this.items = items;
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Failed to load promo video queue', error);
        this.isLoading = false;
        this.swal.toast(error.error?.message || 'Failed to load videos', 'error');
      }
    });
  }

  setFilter(filter: ReviewFilter): void {
    if (this.filter === filter) return;
    this.filter = filter;
    this.load();
  }

  /** Uploads are stored as /uploads/... paths; <video> needs a full origin. */
  mediaUrl(url?: string): string {
    if (!url) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    const path = url.startsWith('/') ? url : `/${url}`;
    return `${environment.imageBaseUrl}${path.startsWith('/uploads/') ? path : '/uploads' + path}`;
  }

  isBusy(id: number): boolean {
    return this.busyIds.has(id);
  }

  approve(item: PromoVideoReviewItem): void {
    this.busyIds.add(item.id);
    this.promoCodeService.approvePromoVideo(item.id).subscribe({
      next: () => {
        this.busyIds.delete(item.id);
        this.swal.toast(`"${item.title}" is now live on the home banner`, 'success');
        this.removeFromCurrentList(item.id);
      },
      error: (error) => {
        this.busyIds.delete(item.id);
        this.swal.toast(error.error?.message || 'Failed to approve video', 'error');
      }
    });
  }

  async reject(item: PromoVideoReviewItem): Promise<void> {
    const result = await this.swal.prompt(
      'Reject this video?',
      'The shop owner sees this note, so say what needs fixing.'
    );
    // Dismissing the dialog is a cancel, not an empty reason - nothing should
    // be rejected on a stray Escape.
    if (!result.isConfirmed) return;

    const reason = (result.value ?? '').toString().trim();

    this.busyIds.add(item.id);
    this.promoCodeService.rejectPromoVideo(item.id, reason).subscribe({
      next: () => {
        this.busyIds.delete(item.id);
        this.swal.toast('Video rejected', 'success');
        this.removeFromCurrentList(item.id);
      },
      error: (error) => {
        this.busyIds.delete(item.id);
        this.swal.toast(error.error?.message || 'Failed to reject video', 'error');
      }
    });
  }

  /**
   * A decision moves the item out of whichever list is on screen (a just-
   * approved video is no longer "Waiting"), so drop it locally instead of
   * refetching the whole queue.
   */
  private removeFromCurrentList(id: number): void {
    this.items = this.items.filter(item => item.id !== id);
  }

  trackById(_index: number, item: PromoVideoReviewItem): number {
    return item.id;
  }
}
