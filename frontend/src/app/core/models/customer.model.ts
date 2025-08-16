export interface Customer {
  id: number;
  firstName: string;
  lastName: string;
  fullName: string;
  email: string;
  mobileNumber: string;
  alternateMobileNumber?: string;
  gender?: Gender;
  dateOfBirth?: string;
  notes?: string;
  
  // Address fields
  addressLine1?: string;
  addressLine2?: string;
  city?: string;
  state?: string;
  postalCode?: string;
  country?: string;
  latitude?: number;
  longitude?: number;
  
  // Preferences
  emailNotifications: boolean;
  smsNotifications: boolean;
  pushNotifications: boolean;
  promotionalEmails: boolean;
  promotionalSms: boolean;
  preferredLanguage?: string;
  
  // Status fields
  isActive: boolean;
  status: CustomerStatus;
  isVerified: boolean;
  emailVerified: boolean;
  mobileVerified: boolean;
  
  // Referral
  referralCode?: string;
  referredBy?: string;
  
  // Audit fields
  createdAt: string;
  updatedAt: string;
  createdBy: string;
  updatedBy: string;
  lastLoginDate?: string;
  
  // Metrics
  totalOrders: number;
  totalSpent: number;
  referralCount: number;
  loyaltyPoints: number;
  
  // Source
  registrationSource?: string;
  deviceId?: string;
  appVersion?: string;
}

export interface CustomerRequest {
  firstName: string;
  lastName: string;
  email: string;
  mobileNumber: string;
  alternateMobileNumber?: string;
  gender?: Gender;
  dateOfBirth?: string;
  notes?: string;
  
  // Address fields
  addressLine1?: string;
  addressLine2?: string;
  city?: string;
  state?: string;
  postalCode?: string;
  country?: string;
  latitude?: number;
  longitude?: number;
  
  // Preferences
  emailNotifications?: boolean;
  smsNotifications?: boolean;
  pushNotifications?: boolean;
  promotionalEmails?: boolean;
  promotionalSms?: boolean;
  preferredLanguage?: string;
  
  // Status
  isActive?: boolean;
  status?: CustomerStatus;
  
  // Referral
  referredBy?: string;
}

export interface CustomerResponse {
  id: number;
  firstName: string;
  lastName: string;
  fullName: string;
  email: string;
  mobileNumber: string;
  alternateMobileNumber?: string;
  gender?: Gender;
  dateOfBirth?: string;
  notes?: string;
  
  // Address
  addressLine1?: string;
  addressLine2?: string;
  city?: string;
  state?: string;
  postalCode?: string;
  country?: string;
  
  // Status
  isActive: boolean;
  status: CustomerStatus;
  statusLabel: string;
  isVerified: boolean;
  emailVerified: boolean;
  mobileVerified: boolean;
  
  // Preferences
  emailNotifications: boolean;
  smsNotifications: boolean;
  pushNotifications: boolean;
  promotionalEmails: boolean;
  promotionalSms: boolean;
  
  // Metrics
  totalOrders: number;
  totalSpent: number;
  referralCount: number;
  loyaltyPoints: number;
  
  // Dates
  createdAt: string;
  updatedAt: string;
  lastLoginDate?: string;
  memberSince: string;
  
  // Additional info
  registrationSource?: string;
  hasAddress: boolean;
  shortAddress?: string;
}

export interface CustomerSearchParams {
  page?: number;
  size?: number;
  search?: string;
  status?: CustomerStatus;
  city?: string;
  state?: string;
  emailVerified?: boolean;
  mobileVerified?: boolean;
  sortBy?: string;
  sortDir?: 'asc' | 'desc';
}

export interface CustomerStatsResponse {
  totalCustomers: number;
  activeCustomers: number;
  newCustomersThisMonth: number;
  verifiedCustomers: number;
  customersWithOrders: number;
  averageOrderValue: number;
  topCities: Array<{city: string; count: number}>;
  registrationSources: Array<{source: string; count: number}>;
}

export enum Gender {
  MALE = 'MALE',
  FEMALE = 'FEMALE',
  OTHER = 'OTHER',
  PREFER_NOT_TO_SAY = 'PREFER_NOT_TO_SAY'
}

export enum CustomerStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  BLOCKED = 'BLOCKED',
  PENDING_VERIFICATION = 'PENDING_VERIFICATION'
}