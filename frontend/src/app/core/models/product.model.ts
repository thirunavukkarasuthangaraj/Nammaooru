export interface MasterProduct {
  id: number;
  name: string;
  nameTamil?: string;
  description: string;
  sku: string;
  barcode?: string;
  categoryId: number;
  category?: ProductCategory;
  brand?: string;
  baseUnit?: string;
  baseWeight?: number;
  specifications?: string;
  status: ProductStatus;
  isFeatured: boolean;
  isGlobal: boolean;
  createdBy: string;
  updatedBy: string;
  createdAt: string;
  updatedAt: string;
  
  // Calculated fields
  primaryImageUrl?: string;
  shopCount?: number;
  minPrice?: number;
  maxPrice?: number;
  imageUrls?: string[];
}

export interface ShopProduct {
  id: number;
  shopId: number;
  shopName: string;
  masterProduct: MasterProduct;
  price: number;
  originalPrice?: number;
  costPrice?: number;
  stockQuantity: number;
  minStockLevel?: number;
  maxStockLevel?: number;
  trackInventory: boolean;
  status: ShopProductStatus;
  isAvailable: boolean;
  isFeatured: boolean;
  customName?: string;
  customDescription?: string;
  customAttributes?: string;
  displayOrder?: number;
  tags?: string;
  createdBy: string;
  updatedBy: string;
  createdAt: string;
  updatedAt: string;
  
  // Calculated fields
  displayName: string;
  displayDescription: string;
  primaryImageUrl?: string;
  inStock: boolean;
  lowStock: boolean;
  discountAmount?: number;
  discountPercentage?: number;
  profitMargin?: number;
  shopImageUrls?: string[];
}

export interface ProductCategory {
  id: number;
  name: string;
  nameTamil?: string;
  description?: string;
  slug: string;
  parentId?: number;
  parentName?: string;
  fullPath: string;
  isActive: boolean;
  sortOrder?: number;
  iconUrl?: string;
  createdBy: string;
  createdAt: string;
  updatedAt: string;

  // Hierarchy info
  subcategories?: ProductCategory[];
  hasSubcategories: boolean;
  isRootCategory: boolean;

  // Statistics
  productCount: number;
  subcategoryCount: number;
}

export interface ProductImage {
  id: number;
  imageUrl: string;
  altText?: string;
  isPrimary: boolean;
  sortOrder: number;
  createdBy: string;
  createdAt: string;
  imageType: 'MASTER' | 'SHOP';
  productId: number;
}

export enum ProductStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  DISCONTINUED = 'DISCONTINUED'
}

export enum ShopProductStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  OUT_OF_STOCK = 'OUT_OF_STOCK',
  DISCONTINUED = 'DISCONTINUED'
}

// Request DTOs
export interface MasterProductRequest {
  name: string;
  nameTamil?: string;
  description?: string;
  sku: string;
  barcode?: string;
  categoryId: number;
  brand?: string;
  baseUnit?: string;
  baseWeight?: number;
  specifications?: string;
  status?: ProductStatus;
  isFeatured?: boolean;
  isGlobal?: boolean;
  imageUrls?: string[];
}

export interface ShopProductRequest {
  masterProductId: number;
  price: number;
  originalPrice?: number;
  costPrice?: number;
  stockQuantity?: number;
  minStockLevel?: number;
  maxStockLevel?: number;
  trackInventory?: boolean;
  status?: ShopProductStatus;
  isAvailable?: boolean;
  isFeatured?: boolean;
  customName?: string;
  customDescription?: string;
  customAttributes?: string;
  displayOrder?: number;
  tags?: string;
  shopImageUrls?: string[];
}

export interface ProductCategoryRequest {
  name: string;
  nameTamil?: string;
  description?: string;
  slug?: string;
  parentId?: number;
  isActive?: boolean;
  sortOrder?: number;
  iconUrl?: string;
}

// Filter interfaces
export interface ProductFilters {
  search?: string;
  categoryId?: number;
  brand?: string;
  status?: ProductStatus;
  isFeatured?: boolean;
  page?: number;
  size?: number;
  sortBy?: string;
  sortDirection?: 'ASC' | 'DESC';
}

export interface ShopProductFilters extends Omit<ProductFilters, 'status'> {
  isAvailable?: boolean;
  inStock?: boolean;
  minPrice?: number;
  maxPrice?: number;
  status?: ShopProductStatus;
}

// Statistics
export interface ShopProductStats {
  totalProducts: number;
  activeProducts: number;
  outOfStock: number;
  averagePrice: number;
  minPrice: number;
  maxPrice: number;
}

// Pagination
export interface ProductPage<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
  first: boolean;
  last: boolean;
}

// Inventory operations
export interface InventoryOperation {
  productId: number;
  quantity: number;
  operation: 'ADD' | 'SUBTRACT' | 'SET';
}