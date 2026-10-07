/**
 * PROMO_CODE - a redeemable code (the default). IMAGE_BANNER - artwork only
 * for the customer home carousel: no code / type / discountValue, optional
 * linkUrl opened on tap.
 */
export type PromoBannerType = 'PROMO_CODE' | 'IMAGE_BANNER';

export interface PromoCode {
  id: number;
  bannerType?: PromoBannerType;
  linkUrl?: string;
  // Absent (null) for an IMAGE_BANNER.
  code?: string;
  title: string;
  description?: string;
  type?: 'PERCENTAGE' | 'FIXED_AMOUNT' | 'FREE_SHIPPING' | 'BUY_X_GET_Y';
  discountValue?: number;
  minimumOrderAmount?: number;
  maximumDiscountAmount?: number;
  startDate: string;
  endDate: string;
  status: 'ACTIVE' | 'INACTIVE' | 'EXPIRED';
  usageLimit?: number;
  usageLimitPerCustomer?: number;
  currentUsageCount?: number;
  firstTimeOnly: boolean;
  applicableToAllShops: boolean;
  // What the backend entity actually serialises for the same flag.
  isPublic?: boolean;
  applicableShopIds?: number[];
  imageUrl?: string;
  // Banner video for the customer home carousel. Shown only once videoStatus
  // is APPROVED - an admin's own upload is approved on save.
  videoUrl?: string;
  videoThumbnailUrl?: string;
  videoStatus?: 'PENDING' | 'APPROVED' | 'REJECTED';
  videoReviewNote?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface PromoCodeUsage {
  id: number;
  promotion: PromoCode;
  customer: {
    id: number;
    name: string;
    email: string;
  };
  order: {
    id: number;
    orderNumber: string;
  };
  deviceUuid: string;
  customerPhone: string;
  discountApplied: number;
  orderAmount: number;
  usedAt: string;
}

export interface PromoCodeValidationRequest {
  promoCode: string;
  customerId?: number;
  deviceUuid?: string;
  phone?: string;
  orderAmount: number;
  shopId?: number;
}

export interface PromoCodeValidationResponse {
  valid: boolean;
  message: string;
  discountAmount: number;
  promotionId?: number;
  promotionTitle?: string;
  discountType?: string;
}

export interface PromoCodeStats {
  totalUsage: number;
  uniqueCustomers: number;
  totalDiscountGiven: number;
  averageOrderValue: number;
  remainingUses?: number;
}

export interface CreatePromoCodeRequest {
  // Defaults to PROMO_CODE on the server when omitted.
  bannerType?: PromoBannerType;
  linkUrl?: string | null;
  // Required for PROMO_CODE; omitted/null for IMAGE_BANNER.
  code?: string | null;
  title: string;
  description?: string;
  type?: 'PERCENTAGE' | 'FIXED_AMOUNT' | 'FREE_SHIPPING' | 'BUY_X_GET_Y' | null;
  discountValue?: number | null;
  minimumOrderAmount?: number;
  maximumDiscountAmount?: number;
  startDate: string;
  endDate: string;
  status: 'ACTIVE' | 'INACTIVE';
  usageLimit?: number;
  usageLimitPerCustomer?: number;
  firstTimeOnly: boolean;
  applicableToAllShops: boolean;
  applicableShopIds?: number[];
  imageUrl?: string;
  videoUrl?: string;
  videoThumbnailUrl?: string;
}
