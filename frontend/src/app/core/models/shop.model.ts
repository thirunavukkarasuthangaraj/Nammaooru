export interface Shop {
  id: number;
  name: string;
  nameTamil?: string;
  description?: string;
  shopId: string;
  slug: string;
  ownerName: string;
  ownerEmail: string;
  ownerPhone: string;
  businessName?: string;
  businessType: BusinessType;
  addressLine1: string;
  city: string;
  state: string;
  postalCode: string;
  country: string;
  latitude?: number;
  longitude?: number;
  minOrderAmount: number;
  deliveryRadius: number;
  freeDeliveryAbove?: number;
  commissionRate: number;
  gstNumber?: string;
  panNumber?: string;
  status: ShopStatus;
  isActive: boolean;
  isVerified: boolean;
  isFeatured: boolean;
  rating: number;
  totalOrders: number;
  totalRevenue: number;
  productCount?: number;
  createdBy?: string;
  updatedBy?: string;
  createdAt: Date;
  updatedAt: Date;
  images: ShopImage[];
  documents: ShopDocument[];
}

export interface ShopImage {
  id: number;
  imageUrl: string;
  imageType: ImageType;
  isPrimary: boolean;
  createdAt: Date;
}

export interface ShopCreateRequest {
  name: string;
  nameTamil?: string;
  description?: string;
  ownerName: string;
  ownerEmail: string;
  ownerPhone: string;
  businessName?: string;
  businessType: BusinessType;
  addressLine1: string;
  city: string;
  state: string;
  postalCode: string;
  country?: string;
  latitude?: number;
  longitude?: number;
  minOrderAmount?: number;
  deliveryRadius?: number;
  freeDeliveryAbove?: number;
  commissionRate?: number;
  gstNumber?: string;
  panNumber?: string;
}

export interface ShopUpdateRequest {
  name?: string;
  nameTamil?: string;
  description?: string;
  ownerName?: string;
  ownerEmail?: string;
  ownerPhone?: string;
  businessName?: string;
  businessType?: BusinessType;
  addressLine1?: string;
  city?: string;
  state?: string;
  postalCode?: string;
  country?: string;
  latitude?: number;
  longitude?: number;
  minOrderAmount?: number;
  deliveryRadius?: number;
  freeDeliveryAbove?: number;
  commissionRate?: number;
  gstNumber?: string;
  panNumber?: string;
  status?: ShopStatus;
  isActive?: boolean;
  isVerified?: boolean;
  isFeatured?: boolean;
}

export interface ShopPageResponse {
  content: Shop[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  first: boolean;
  last: boolean;
  hasNext: boolean;
  hasPrevious: boolean;
}

export interface ShopFilterParams {
  page?: number;
  size?: number;
  sortBy?: string;
  sortDir?: 'asc' | 'desc';
  name?: string;
  city?: string;
  state?: string;
  businessType?: BusinessType;
  status?: ShopStatus;
  isActive?: boolean;
  isVerified?: boolean;
  isFeatured?: boolean;
  minRating?: number;
  maxRating?: number;
  search?: string;
}

export enum BusinessType {
  GROCERY = 'GROCERY',
  PHARMACY = 'PHARMACY',
  RESTAURANT = 'RESTAURANT',
  GENERAL = 'GENERAL'
}

export enum ShopStatus {
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
  SUSPENDED = 'SUSPENDED'
}

export enum ImageType {
  LOGO = 'LOGO',
  BANNER = 'BANNER',
  GALLERY = 'GALLERY'
}

export interface ShopDocument {
  id: number;
  shopId: number;
  documentType: DocumentType;
  documentName: string;
  originalFilename: string;
  fileType: string;
  fileSize: number;
  verificationStatus: DocumentVerificationStatus;
  verificationNotes?: string;
  verifiedBy?: string;
  verifiedAt?: Date;
  isRequired: boolean;
  downloadUrl?: string;
  createdAt: Date;
  updatedAt: Date;
}

export enum DocumentType {
  BUSINESS_LICENSE = 'BUSINESS_LICENSE',
  GST_CERTIFICATE = 'GST_CERTIFICATE',
  PAN_CARD = 'PAN_CARD',
  AADHAR_CARD = 'AADHAR_CARD',
  BANK_STATEMENT = 'BANK_STATEMENT',
  ADDRESS_PROOF = 'ADDRESS_PROOF',
  OWNER_PHOTO = 'OWNER_PHOTO',
  SHOP_PHOTO = 'SHOP_PHOTO',
  FOOD_LICENSE = 'FOOD_LICENSE',
  FSSAI_CERTIFICATE = 'FSSAI_CERTIFICATE',
  DRUG_LICENSE = 'DRUG_LICENSE',
  TRADE_LICENSE = 'TRADE_LICENSE',
  OTHER = 'OTHER'
}

export enum DocumentVerificationStatus {
  PENDING = 'PENDING',
  VERIFIED = 'VERIFIED',
  REJECTED = 'REJECTED',
  EXPIRED = 'EXPIRED'
}

export interface DocumentUploadRequest {
  documentType: DocumentType;
  documentName: string;
  file: File;
}

export interface DocumentVerificationRequest {
  verificationStatus: DocumentVerificationStatus;
  verificationNotes?: string;
}