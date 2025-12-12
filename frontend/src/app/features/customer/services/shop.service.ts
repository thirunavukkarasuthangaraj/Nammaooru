import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, switchMap } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';

export interface Shop {
  id: number;
  name: string;
  description: string;
  image?: string;
  isOpen: boolean;
  rating?: number;
  distance?: string;
  deliveryTime?: string;
  deliveryFee?: number;
  categories: string[];
  address?: string;
  phone?: string;
  openingHours?: string;
}

export interface Product {
  id: number;
  name: string;
  description: string;
  price: number;
  image?: string;
  unit: string;
  category: string;
  inStock: boolean;
  quantity?: number;
  discount?: number;
  shopId: number;
}

@Injectable({
  providedIn: 'root'
})
export class ShopService {
  private apiUrl = `${environment.apiUrl}`;

  constructor(private http: HttpClient) {}

  getShops(searchTerm: string = '', category: string = ''): Observable<Shop[]> {
    let params = new HttpParams();
    if (searchTerm) params = params.set('search', searchTerm);
    if (category) params = params.set('category', category);
    
    // Get only active and approved shops
    return this.http.get<any>(`${this.apiUrl}/customer/shops`, { params })
      .pipe(
        switchMap(response => {
          // Handle paginated response
          if (response.data && response.data.content) {
            // Transform backend shop data to frontend format
            const shops = response.data.content.map((shop: any) => {
              // Find logo from images array (imageType === 'LOGO' or isPrimary === true)
              let logoUrl = '/assets/images/shop-placeholder.jpg';
              if (shop.images && shop.images.length > 0) {
                const logoImage = shop.images.find((img: any) =>
                  img.imageType === 'LOGO' || img.isPrimary === true
                );
                if (logoImage && logoImage.imageUrl) {
                  logoUrl = logoImage.imageUrl;
                }
              }

              return {
                id: shop.id,
                name: shop.name,
                description: shop.description || shop.businessName || '',
                image: logoUrl,
                isOpen: shop.isActive || true,
                rating: shop.rating || 4.5,
                distance: '2.5',
                deliveryTime: '30-45',
                deliveryFee: shop.deliveryFee || 40,
                categories: [shop.businessType || 'General'],
                address: `${shop.city}, ${shop.state}`,
                phone: shop.ownerPhone || ''
              };
            });
            return of(shops);
          }
          return of([]);
        }),
        catchError(() => {
          const mockShops: Shop[] = [
            {
              id: 1,
              name: 'Annamalai Stores',
              description: 'Fresh vegetables and groceries',
              image: '/assets/images/shops/annamalai-stores.jpg',
              isOpen: true,
              rating: 4.5,
              distance: '1.2',
              deliveryTime: '25-30',
              deliveryFee: 40,
              categories: ['grocery', 'vegetables'],
              address: 'T. Nagar, Chennai',
              phone: '+91 98765 43210'
            },
            {
              id: 2,
              name: 'Saravana Medical',
              description: 'Medicines and healthcare products',
              image: '/assets/images/shops/saravana-medical.jpg',
              isOpen: true,
              rating: 4.8,
              distance: '0.8',
              deliveryTime: '15-20',
              deliveryFee: 40,
              categories: ['pharmacy', 'healthcare'],
              address: 'Adyar, Chennai',
              phone: '+91 98765 43211'
            },
            {
              id: 3,
              name: 'Murugan Idli Shop',
              description: 'Authentic South Indian cuisine',
              image: '/assets/images/shops/murugan-idli.jpg',
              isOpen: true,
              rating: 4.3,
              distance: '2.1',
              deliveryTime: '35-45',
              deliveryFee: 40,
              categories: ['restaurant', 'south-indian'],
              address: 'Mylapore, Chennai',
              phone: '+91 98765 43212'
            },
            {
              id: 4,
              name: 'Vijay Electronics',
              description: 'Mobile phones and accessories',
              image: '/assets/images/shops/vijay-electronics.jpg',
              isOpen: false,
              rating: 4.1,
              distance: '3.5',
              deliveryTime: '45-60',
              deliveryFee: 60,
              categories: ['electronics', 'mobile'],
              address: 'Velachery, Chennai',
              phone: '+91 98765 43213'
            }
          ];

          let filteredShops = mockShops;

          if (searchTerm) {
            filteredShops = filteredShops.filter(shop =>
              shop.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
              shop.description.toLowerCase().includes(searchTerm.toLowerCase())
            );
          }

          if (category) {
            filteredShops = filteredShops.filter(shop =>
              shop.categories.includes(category)
            );
          }

          return of(filteredShops);
        })
      );
  }

  getShopById(id: number): Observable<Shop | null> {
    return this.http.get<{data: Shop}>(`${this.apiUrl}/customer/shops/${id}`)
      .pipe(
        switchMap(response => of(response.data || null)),
        catchError(() => {
          return new Observable<Shop | null>(observer => {
            this.getShops().subscribe(shops => {
              const shop = shops.find(s => s.id === id);
              observer.next(shop || null);
              observer.complete();
            });
          });
        })
      );
  }

  getProductsByShop(shopId: number, category: string = '', searchTerm: string = ''): Observable<Product[]> {
    let params = new HttpParams();
    if (category) params = params.set('category', category);
    if (searchTerm) params = params.set('search', searchTerm);
    
    return this.http.get<any>(`${this.apiUrl}/customer/shops/${shopId}/products`, { params })
      .pipe(
        switchMap(response => {
          // Handle paginated response from backend
          if (response.data && response.data.content) {
            const products = response.data.content.map((product: any) => ({
              id: product.id,
              name: product.customName || product.displayName || (product.masterProduct && product.masterProduct.name) || 'Product',
              description: product.customDescription || product.displayDescription || (product.masterProduct && product.masterProduct.description) || '',
              price: product.price || 0,
              image: product.primaryImageUrl || (product.masterProduct && product.masterProduct.primaryImageUrl) || '/assets/images/product-placeholder.jpg',
              unit: (product.masterProduct && product.masterProduct.baseUnit) || 'piece',
              category: (product.masterProduct && product.masterProduct.category && product.masterProduct.category.name) || 'General',
              inStock: product.inStock !== false && product.stockQuantity > 0,
              quantity: product.stockQuantity || 0,
              discount: product.discountPercentage || 0,
              shopId: shopId
            }));
            return of(products);
          }
          return of([]);
        }),
        catchError(() => {
          const mockProducts: Product[] = [
            { id: 1, name: 'Tomatoes', description: 'Fresh red tomatoes', price: 40, unit: 'kg', category: 'vegetables', inStock: true, shopId: 1, image: '/assets/images/products/tomatoes.jpg' },
            { id: 2, name: 'Onions', description: 'Fresh onions', price: 30, unit: 'kg', category: 'vegetables', inStock: true, shopId: 1, image: '/assets/images/products/onions.jpg' },
            { id: 3, name: 'Rice - Ponni', description: 'Premium quality ponni rice', price: 55, unit: 'kg', category: 'grains', inStock: true, shopId: 1, image: '/assets/images/products/rice.jpg' },
            { id: 4, name: 'Dal - Toor', description: 'Yellow toor dal', price: 120, unit: 'kg', category: 'pulses', inStock: true, shopId: 1, image: '/assets/images/products/dal.jpg' },
            { id: 5, name: 'Paracetamol', description: 'Fever and pain relief', price: 5, unit: 'strip', category: 'medicines', inStock: true, shopId: 2, image: '/assets/images/products/paracetamol.jpg' },
            { id: 6, name: 'Sanitizer', description: 'Hand sanitizer 500ml', price: 75, unit: 'bottle', category: 'hygiene', inStock: true, shopId: 2, image: '/assets/images/products/sanitizer.jpg' },
            { id: 7, name: 'Idli (4 pcs)', description: 'Soft steamed idli with chutney', price: 40, unit: 'plate', category: 'breakfast', inStock: true, shopId: 3, image: '/assets/images/products/idli.jpg' },
            { id: 8, name: 'Dosa', description: 'Crispy dosa with sambar and chutney', price: 60, unit: 'piece', category: 'breakfast', inStock: true, shopId: 3, image: '/assets/images/products/dosa.jpg' },
            { id: 9, name: 'Phone Cover', description: 'Protective phone cover', price: 299, unit: 'piece', category: 'accessories', inStock: true, shopId: 4, image: '/assets/images/products/phone-cover.jpg' },
            { id: 10, name: 'Earphones', description: 'Wired earphones', price: 599, unit: 'piece', category: 'accessories', inStock: true, shopId: 4, image: '/assets/images/products/earphones.jpg' }
          ];

          let filteredProducts = mockProducts.filter(product => product.shopId === shopId);

          if (category) {
            filteredProducts = filteredProducts.filter(product =>
              product.category.toLowerCase() === category.toLowerCase()
            );
          }

          if (searchTerm) {
            filteredProducts = filteredProducts.filter(product =>
              product.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
              product.description.toLowerCase().includes(searchTerm.toLowerCase())
            );
          }

          return of(filteredProducts);
        })
      );
  }

  getProductCategories(shopId: number): Observable<string[]> {
    return new Observable(observer => {
      this.getProductsByShop(shopId).subscribe(products => {
        const categories = [...new Set(products.map(product => product.category))];
        observer.next(categories);
        observer.complete();
      });
    });
  }
}