export interface PromoCode {
  id: number;
  code: string;
  title: string;
  description?: string;
  type: 'PERCENTAGE' | 'FIXED_AMOUNT' | 'FREE_SHIPPING' | 'BUY_X_GET_Y';
  discountValue: number;
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
  applicableShopIds?: number[];
  imageUrl?: string;
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
  code: string;
  title: string;
  description?: string;
  type: 'PERCENTAGE' | 'FIXED_AMOUNT' | 'FREE_SHIPPING' | 'BUY_X_GET_Y';
  discountValue: number;
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
}
