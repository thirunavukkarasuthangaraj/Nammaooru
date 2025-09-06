export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  email: string;
  password: string;
  role: UserRole;
}

export interface AuthResponse {
  accessToken: string;
  tokenType: string;
  username: string;
  email: string;
  role: string;
  passwordChangeRequired: boolean;
  isTemporaryPassword: boolean;
}

export interface User {
  id: number;
  username: string;
  email: string;
  role: UserRole;
  isActive: boolean;
  shopId?: number;
  createdAt: Date;
  updatedAt: Date;
}

export enum UserRole {
  SUPER_ADMIN = 'SUPER_ADMIN',
  ADMIN = 'ADMIN',
  MANAGER = 'MANAGER',
  SHOP_OWNER = 'SHOP_OWNER',
  DELIVERY_PARTNER = 'DELIVERY_PARTNER',
  USER = 'USER',
  CUSTOMER = 'CUSTOMER'
}