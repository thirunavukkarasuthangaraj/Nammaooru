import { Component, OnInit } from '@angular/core';
import { forkJoin } from 'rxjs';
import {
  PromoCodeService,
  PromoVideoReviewItem,
  ComboReviewItem
} from '../../../../core/services/promo-code.service';
import { SwalService } from '../../../../core/services/swal.service';
import { environment } from '../../../../../environments/environment';

type ReviewFilter = 'PENDING' | 'APPROVED' | 'REJECTED';

/**
 * One row on the review page. Promotions and combos are different entities
 * with different fields, so they are flattened to this shape up front and the
 * template never has to care which is which - only approve()/reject() do.
 */
interface BannerReviewItem {
  kind: 'promo' | 'combo';
  id: number;
  title: string;
  code: string;
  shopName: string;
  description?: string;
  imageUrl?: string;
  videoUrl?: string;
  videoThumbnailUrl?: string;
  /** Review state of each attached asset; a combo has exactly one ("image"). */
  assetStates: string[];
  reviewNote?: string;
  submittedAt?: string;
  submittedBy?: string;
  reviewedBy?: string;
  reviewedAt?: string;
  startDate?: string;
  endDate?: string;
  priceLine?: string;
}

/**
 * Super-admin review queue for everything shop owners can put on the customer
 * home "SPECIAL OFFERS" carousel: promotion banners (image + video) and combos.
 *
 * No customer-facing API hands any of it out until it is approved here:
 * /promotions/active, /customer/combos and /featured-posts all drop
 * unapproved items, so the app falls back to its plain card or skips them.
 */
@Component({
  selector: 'app-promo-video-approvals',
  templateUrl: './promo-video-approvals.component.html',
  styleUrls: ['./promo-video-approvals.component.css']
})
export class PromoVideoApprovalsComponent implements OnInit {
  items: BannerReviewItem[] = [];
  isLoading = false;
  filter: ReviewFilter = 'PENDING';
  // Keys ("promo:12") currently being decided, so one slow request doesn't
  // lock the whole queue and a card can't be double-submitted.
  busyKeys = new Set<string>();

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
    forkJoin({
      promos: this.promoCodeService.getVideoReviewQueue(this.filter),
      combos: this.promoCodeService.getComboReviewQueue(this.filter)
    }).subscribe({
      next: ({ promos, combos }) => {
        this.items = [
          ...promos.map(p => this.fromPromo(p)),
          ...combos.map(c => this.fromCombo(c))
        ].sort((a, b) => (a.submittedAt ?? '').localeCompare(b.submittedAt ?? ''));
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Failed to load banner review queue', error);
        this.isLoading = false;
        this.swal.toast(error.error?.message || 'Failed to load banners', 'error');
      }
    });
  }

  private fromPromo(p: PromoVideoReviewItem): BannerReviewItem {
    const assetStates: string[] = [];
    if (p.imageUrl) assetStates.push(p.imageStatus ?? '');
    if (p.videoUrl) assetStates.push(p.videoStatus ?? '');
    return {
      kind: 'promo',
      id: p.id,
      title: p.title,
      code: p.code,
      shopName: p.shopName || 'Platform Offer',
      description: p.description,
      imageUrl: p.imageUrl,
      videoUrl: p.videoUrl,
      videoThumbnailUrl: p.videoThumbnailUrl,
      assetStates,
      reviewNote: p.videoReviewNote || p.imageReviewNote,
      submittedAt: p.videoSubmittedAt || p.imageSubmittedAt,
      submittedBy: p.submittedBy,
      reviewedBy: p.reviewedBy,
      reviewedAt: p.reviewedAt,
      startDate: p.startDate,
      endDate: p.endDate
    };
  }

  private fromCombo(c: ComboReviewItem): BannerReviewItem {
    const price = c.comboPrice != null ? `₹${c.comboPrice}` : '';
    const was = c.originalPrice != null ? ` (was ₹${c.originalPrice})` : '';
    return {
      kind: 'combo',
      id: c.id,
      title: c.name,
      code: 'COMBO',
      shopName: c.shopName || 'Shop',
      description: c.description,
      imageUrl: c.bannerImageUrl,
      assetStates: [c.bannerStatus ?? ''],
      reviewNote: c.bannerReviewNote,
      submittedAt: c.bannerSubmittedAt,
      submittedBy: c.createdBy,
      startDate: c.startDate,
      endDate: c.endDate,
      priceLine: price ? `${price}${was}` : undefined
    };
  }

  setFilter(filter: ReviewFilter): void {
    if (this.filter === filter) return;
    this.filter = filter;
    this.load();
  }

  /** Uploads are stored as /uploads/... paths; <video>/<img> need a full origin. */
  mediaUrl(url?: string): string {
    if (!url) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    const path = url.startsWith('/') ? url : `/${url}`;
    return `${environment.imageBaseUrl}${path.startsWith('/uploads/') ? path : '/uploads' + path}`;
  }

  key(item: BannerReviewItem): string {
    return `${item.kind}:${item.id}`;
  }

  isBusy(item: BannerReviewItem): boolean {
    return this.busyKeys.has(this.key(item));
  }

  /**
   * A promo can carry an image, a video, or both, and the backend decides on
   * all of them at once - so a button only disappears when every attached
   * asset already sits in that state.
   */
  isFullyApproved(item: BannerReviewItem): boolean {
    return item.assetStates.length > 0 && item.assetStates.every(s => s === 'APPROVED');
  }

  isFullyRejected(item: BannerReviewItem): boolean {
    return item.assetStates.length > 0 && item.assetStates.every(s => s === 'REJECTED');
  }

  approve(item: BannerReviewItem): void {
    const k = this.key(item);
    this.busyKeys.add(k);
    const call = item.kind === 'combo'
      ? this.promoCodeService.approveComboBanner(item.id)
      : this.promoCodeService.approvePromoVideo(item.id);
    call.subscribe({
      next: () => {
        this.busyKeys.delete(k);
        this.swal.toast(`"${item.title}" is now live on the home screen`, 'success');
        this.removeFromCurrentList(item);
      },
      error: (error) => {
        this.busyKeys.delete(k);
        this.swal.toast(error.error?.message || 'Failed to approve', 'error');
      }
    });
  }

  async reject(item: BannerReviewItem): Promise<void> {
    const result = await this.swal.prompt(
      item.kind === 'combo' ? 'Reject this combo?' : 'Reject this banner?',
      'The shop owner sees this note, so say what needs fixing.'
    );
    // Dismissing the dialog is a cancel, not an empty reason - nothing should
    // be rejected on a stray Escape.
    if (!result.isConfirmed) return;

    const reason = (result.value ?? '').toString().trim();
    const k = this.key(item);
    this.busyKeys.add(k);
    const call = item.kind === 'combo'
      ? this.promoCodeService.rejectComboBanner(item.id, reason)
      : this.promoCodeService.rejectPromoVideo(item.id, reason);
    call.subscribe({
      next: () => {
        this.busyKeys.delete(k);
        this.swal.toast('Rejected', 'success');
        this.removeFromCurrentList(item);
      },
      error: (error) => {
        this.busyKeys.delete(k);
        this.swal.toast(error.error?.message || 'Failed to reject', 'error');
      }
    });
  }

  /**
   * A decision moves the item out of whichever list is on screen (a just-
   * approved item is no longer "Waiting"), so drop it locally instead of
   * refetching the whole queue.
   */
  private removeFromCurrentList(item: BannerReviewItem): void {
    const k = this.key(item);
    this.items = this.items.filter(i => this.key(i) !== k);
  }

  trackByKey(_index: number, item: BannerReviewItem): string {
    return this.key(item);
  }
}
