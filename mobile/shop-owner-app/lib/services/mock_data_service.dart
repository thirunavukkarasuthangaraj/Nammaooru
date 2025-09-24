import 'dart:math';
import '../models/models.dart';

class MockDataService {
  static final Random _random = Random();

  // Mock shop data
  static Shop get mockShop => Shop(
    id: 'shop_001',
    name: 'Ananya\'s General Store',
    description: 'Your neighborhood store for daily essentials and fresh groceries',
    address: '123 Main Street, Koramangala, Bengaluru, Karnataka 560034',
    phone: '+91 98765 43210',
    email: 'ananya.store@gmail.com',
    latitude: 12.9352,
    longitude: 77.6245,
    isActive: true,
    category: 'General Store',
    rating: 4.5,
    totalRatings: 142,
    imageUrl: 'https://example.com/shop-image.jpg',
    businessHours: {
      'monday': {'open': '08:00', 'close': '22:00', 'isOpen': true},
      'tuesday': {'open': '08:00', 'close': '22:00', 'isOpen': true},
      'wednesday': {'open': '08:00', 'close': '22:00', 'isOpen': true},
      'thursday': {'open': '08:00', 'close': '22:00', 'isOpen': true},
      'friday': {'open': '08:00', 'close': '22:00', 'isOpen': true},
      'saturday': {'open': '08:00', 'close': '23:00', 'isOpen': true},
      'sunday': {'open': '09:00', 'close': '21:00', 'isOpen': true},
    },
    createdAt: DateTime.now().subtract(const Duration(days: 365)),
    updatedAt: DateTime.now(),
  );

  // Mock user data
  static User get mockUser => User(
    id: 'user_001',
    email: 'ananya@gmail.com',
    name: 'Ananya Sharma',
    phone: '+91 98765 43210',
    role: UserRole.shopOwner,
    shopId: 'shop_001',
    isActive: true,
    profileImageUrl: 'https://example.com/profile.jpg',
    createdAt: DateTime.now().subtract(const Duration(days: 365)),
    lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
  );

  // Mock products data
  static List<Product> get mockProducts => [
    Product(
      id: 'prod_001',
      name: 'Basmati Rice Premium',
      description: 'Premium quality basmati rice, perfect for biryanis and pulao',
      price: 180.00,
      mrp: 200.00,
      category: 'Grains & Cereals',
      subCategory: 'Rice',
      unit: 'kg',
      stockQuantity: 25,
      minStockLevel: 5,
      images: ['https://example.com/rice1.jpg', 'https://example.com/rice2.jpg'],
      isActive: true,
      shopId: 'shop_001',
      barcode: '8901234567890',
      brand: 'India Gate',
      weight: 1.0,
      weightUnit: 'kg',
      tags: ['rice', 'basmati', 'premium', 'grains'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Product(
      id: 'prod_002',
      name: 'Amul Fresh Milk',
      description: 'Fresh full cream milk, rich in taste and nutrition',
      price: 32.00,
      mrp: 35.00,
      category: 'Dairy Products',
      subCategory: 'Milk',
      unit: 'liter',
      stockQuantity: 12,
      minStockLevel: 5,
      images: ['https://example.com/milk1.jpg'],
      isActive: true,
      shopId: 'shop_001',
      barcode: '8901234567891',
      brand: 'Amul',
      weight: 1.0,
      weightUnit: 'liter',
      tags: ['milk', 'dairy', 'fresh', 'amul'],
      expiryDate: DateTime.now().add(const Duration(days: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'prod_003',
      name: 'Britannia Good Day Cookies',
      description: 'Delicious butter cookies with cashew and almond bits',
      price: 25.00,
      mrp: 30.00,
      category: 'Snacks & Beverages',
      subCategory: 'Biscuits & Cookies',
      unit: 'pack',
      stockQuantity: 48,
      minStockLevel: 10,
      images: ['https://example.com/cookies1.jpg'],
      isActive: true,
      shopId: 'shop_001',
      barcode: '8901234567892',
      brand: 'Britannia',
      weight: 150.0,
      weightUnit: 'grams',
      tags: ['cookies', 'biscuits', 'snacks', 'britannia'],
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Product(
      id: 'prod_004',
      name: 'Maggi 2-Minute Noodles',
      description: 'Quick and tasty instant noodles with masala flavor',
      price: 12.00,
      mrp: 14.00,
      category: 'Instant Foods',
      subCategory: 'Noodles',
      unit: 'pack',
      stockQuantity: 0,
      minStockLevel: 20,
      images: ['https://example.com/maggi1.jpg'],
      isActive: false,
      shopId: 'shop_001',
      barcode: '8901234567893',
      brand: 'Maggi',
      weight: 70.0,
      weightUnit: 'grams',
      tags: ['noodles', 'instant', 'maggi', 'quick'],
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Product(
      id: 'prod_005',
      name: 'Tata Salt Crystal',
      description: 'Pure and crystal white iodized salt for healthy cooking',
      price: 20.00,
      mrp: 22.00,
      category: 'Condiments & Spices',
      subCategory: 'Salt',
      unit: 'kg',
      stockQuantity: 15,
      minStockLevel: 3,
      images: ['https://example.com/salt1.jpg'],
      isActive: true,
      shopId: 'shop_001',
      barcode: '8901234567894',
      brand: 'Tata',
      weight: 1.0,
      weightUnit: 'kg',
      tags: ['salt', 'iodized', 'tata', 'cooking'],
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  // Mock orders data
  static List<Order> get mockOrders => [
    Order(
      id: 'order_001',
      customerId: 'customer_001',
      customerName: 'Rajesh Kumar',
      customerPhone: '+91 98765 11111',
      address: '456 Green Avenue, Indiranagar, Bengaluru',
      items: [
        OrderItem(
          productId: 'prod_001',
          productName: 'Basmati Rice Premium',
          quantity: 2,
          price: 180.00,
          unitPrice: 180.00,
          total: 360.00,
        ),
        OrderItem(
          productId: 'prod_002',
          productName: 'Amul Fresh Milk',
          quantity: 1,
          price: 32.00,
          unitPrice: 32.00,
          total: 32.00,
        ),
      ],
      subtotal: 392.00,
      tax: 0.00,
      deliveryFee: 20.00,
      discount: 0.00,
      total: 412.00,
      totalAmount: 412.00,
      status: 'PENDING',
      paymentStatus: 'PENDING',
      paymentMethod: 'Cash on Delivery',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      orderDate: DateTime.now().subtract(const Duration(minutes: 15)),
      estimatedDelivery: DateTime.now().add(const Duration(minutes: 45)),
      notes: 'Please call before delivery',
    ),
    Order(
      id: 'order_002',
      customerId: 'customer_002',
      customerName: 'Priya Nair',
      customerPhone: '+91 98765 22222',
      address: '789 Rose Street, Koramangala, Bengaluru',
      items: [
        OrderItem(
          productId: 'prod_003',
          productName: 'Britannia Good Day Cookies',
          quantity: 3,
          price: 25.00,
          unitPrice: 25.00,
          total: 75.00,
        ),
        OrderItem(
          productId: 'prod_005',
          productName: 'Tata Salt Crystal',
          quantity: 1,
          price: 20.00,
          unitPrice: 20.00,
          total: 20.00,
        ),
      ],
      subtotal: 95.00,
      tax: 0.00,
      deliveryFee: 15.00,
      discount: 0.00,
      total: 110.00,
      totalAmount: 110.00,
      status: 'CONFIRMED',
      paymentStatus: 'PAID',
      paymentMethod: 'UPI',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      orderDate: DateTime.now().subtract(const Duration(hours: 2)),
      estimatedDelivery: DateTime.now().add(const Duration(minutes: 30)),
      acceptedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    ),
    Order(
      id: 'order_003',
      customerId: 'customer_003',
      customerName: 'Amit Singh',
      customerPhone: '+91 98765 33333',
      address: '321 Blue Lane, BTM Layout, Bengaluru',
      items: [
        OrderItem(
          productId: 'prod_001',
          productName: 'Basmati Rice Premium',
          quantity: 1,
          price: 180.00,
          unitPrice: 180.00,
          total: 180.00,
        ),
        OrderItem(
          productId: 'prod_002',
          productName: 'Amul Fresh Milk',
          quantity: 2,
          price: 32.00,
          unitPrice: 32.00,
          total: 64.00,
        ),
        OrderItem(
          productId: 'prod_003',
          productName: 'Britannia Good Day Cookies',
          quantity: 1,
          price: 25.00,
          unitPrice: 25.00,
          total: 25.00,
        ),
      ],
      subtotal: 269.00,
      tax: 0.00,
      deliveryFee: 20.00,
      discount: 0.00,
      total: 289.00,
      totalAmount: 289.00,
      status: 'OUT_FOR_DELIVERY',
      paymentStatus: 'PAID',
      paymentMethod: 'Card',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 20)),
      orderDate: DateTime.now().subtract(const Duration(hours: 4)),
      estimatedDelivery: DateTime.now().add(const Duration(minutes: 10)),
      acceptedAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 30)),
    ),
    Order(
      id: 'order_004',
      customerId: 'customer_004',
      customerName: 'Sneha Reddy',
      customerPhone: '+91 98765 55555',
      address: '654 Yellow Plaza, HSR Layout, Bengaluru',
      items: [
        OrderItem(
          productId: 'prod_005',
          productName: 'Tata Salt Crystal',
          quantity: 2,
          price: 20.00,
          unitPrice: 20.00,
          total: 40.00,
        ),
      ],
      subtotal: 40.00,
      tax: 0.00,
      deliveryFee: 15.00,
      discount: 0.00,
      total: 55.00,
      totalAmount: 55.00,
      status: 'DELIVERED',
      paymentStatus: 'PAID',
      paymentMethod: 'UPI',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)).add(const Duration(hours: 2, minutes: 45)),
      orderDate: DateTime.now().subtract(const Duration(days: 1)),
      acceptedAt: DateTime.now().subtract(const Duration(days: 1)).add(const Duration(minutes: 15)),
      deliveredAt: DateTime.now().subtract(const Duration(days: 1)).add(const Duration(hours: 2, minutes: 45)),
      notes: 'Quick delivery and fresh products!',
    ),
    Order(
      id: 'order_005',
      customerId: 'customer_005',
      customerName: 'Kiran Mehta',
      customerPhone: '+91 98765 77777',
      address: '987 Purple Street, Electronic City, Bengaluru',
      items: [
        OrderItem(
          productId: 'prod_004',
          productName: 'Maggi 2-Minute Noodles',
          quantity: 5,
          price: 12.00,
          unitPrice: 12.00,
          total: 60.00,
        ),
      ],
      subtotal: 60.00,
      tax: 0.00,
      deliveryFee: 25.00,
      discount: 0.00,
      total: 85.00,
      totalAmount: 85.00,
      status: 'CANCELLED',
      paymentStatus: 'PENDING',
      paymentMethod: 'Cash on Delivery',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      orderDate: DateTime.now().subtract(const Duration(hours: 6)),
      cancellationReason: 'Product out of stock',
    ),
  ];

  // Mock notifications data
  static List<NotificationModel> get mockNotifications => [
    NotificationModel(
      id: 'notif_001',
      title: 'New Order Received',
      message: 'Order #001 from Rajesh Kumar for ₹412',
      type: 'new_order',
      data: {'orderId': 'order_001', 'amount': '412.00'},
      isRead: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    NotificationModel(
      id: 'notif_002',
      title: 'Payment Received',
      message: 'Payment of ₹112 received for Order #002',
      type: 'payment_received',
      data: {'orderId': 'order_002', 'amount': '112.00'},
      isRead: false,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationModel(
      id: 'notif_003',
      title: 'Order Delivered',
      message: 'Order #004 successfully delivered to Sneha Reddy',
      type: 'order_delivered',
      data: {'orderId': 'order_004'},
      isRead: true,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationModel(
      id: 'notif_004',
      title: 'Low Stock Alert',
      message: 'Maggi 2-Minute Noodles is out of stock',
      type: 'low_stock',
      data: {'productId': 'prod_004', 'productName': 'Maggi 2-Minute Noodles'},
      isRead: true,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationModel(
      id: 'notif_005',
      title: 'Order Cancelled',
      message: 'Order #005 was cancelled due to out of stock',
      type: 'order_cancelled',
      data: {'orderId': 'order_005', 'reason': 'Product out of stock'},
      isRead: true,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  // Mock analytics data
  static Map<String, dynamic> get mockAnalytics => {
    'dashboard_stats': {
      'total_revenue': 15750.00,
      'todays_sales': 1250.00,
      'pending_orders': 3,
      'total_orders': 45,
      'total_customers': 28,
      'average_order_value': 350.00,
    },
    'revenue_chart': [
      {'date': '2024-01-01', 'amount': 850.00},
      {'date': '2024-01-02', 'amount': 1200.00},
      {'date': '2024-01-03', 'amount': 950.00},
      {'date': '2024-01-04', 'amount': 1450.00},
      {'date': '2024-01-05', 'amount': 1100.00},
      {'date': '2024-01-06', 'amount': 1650.00},
      {'date': '2024-01-07', 'amount': 1250.00},
    ],
    'top_selling_products': [
      {'productId': 'prod_001', 'name': 'Basmati Rice Premium', 'sales': 45},
      {'productId': 'prod_002', 'name': 'Amul Fresh Milk', 'sales': 38},
      {'productId': 'prod_003', 'name': 'Britannia Good Day Cookies', 'sales': 32},
      {'productId': 'prod_005', 'name': 'Tata Salt Crystal', 'sales': 28},
      {'productId': 'prod_004', 'name': 'Maggi 2-Minute Noodles', 'sales': 22},
    ],
    'order_status_distribution': {
      'pending': 3,
      'confirmed': 8,
      'out_for_delivery': 2,
      'delivered': 30,
      'cancelled': 2,
    },
  };

  // Mock product categories
  static List<ProductCategory> get mockCategories => [
    ProductCategory(
      id: 'cat_001',
      name: 'Grains & Cereals',
      description: 'Rice, wheat, and other cereal products',
      imageUrl: 'https://example.com/grains.jpg',
      isActive: true,
      sortOrder: 1,
      subCategories: ['Rice', 'Wheat', 'Oats', 'Quinoa'],
    ),
    ProductCategory(
      id: 'cat_002',
      name: 'Dairy Products',
      description: 'Milk, cheese, yogurt, and dairy items',
      imageUrl: 'https://example.com/dairy.jpg',
      isActive: true,
      sortOrder: 2,
      subCategories: ['Milk', 'Cheese', 'Yogurt', 'Butter'],
    ),
    ProductCategory(
      id: 'cat_003',
      name: 'Snacks & Beverages',
      description: 'Biscuits, chips, drinks, and snack items',
      imageUrl: 'https://example.com/snacks.jpg',
      isActive: true,
      sortOrder: 3,
      subCategories: ['Biscuits & Cookies', 'Chips', 'Beverages', 'Chocolates'],
    ),
    ProductCategory(
      id: 'cat_004',
      name: 'Instant Foods',
      description: 'Ready-to-cook and instant food products',
      imageUrl: 'https://example.com/instant.jpg',
      isActive: true,
      sortOrder: 4,
      subCategories: ['Noodles', 'Ready Meals', 'Instant Mixes'],
    ),
    ProductCategory(
      id: 'cat_005',
      name: 'Condiments & Spices',
      description: 'Salt, spices, sauces, and cooking essentials',
      imageUrl: 'https://example.com/spices.jpg',
      isActive: true,
      sortOrder: 5,
      subCategories: ['Salt', 'Spices', 'Sauces', 'Oil & Ghee'],
    ),
  ];

  // Helper methods to generate random data
  static String generateRandomOrderId() {
    return 'order_${_random.nextInt(9999).toString().padLeft(4, '0')}';
  }

  static String generateRandomProductId() {
    return 'prod_${_random.nextInt(9999).toString().padLeft(4, '0')}';
  }

  static String generateRandomCustomerName() {
    final firstNames = ['Rajesh', 'Priya', 'Amit', 'Sneha', 'Kiran', 'Anita', 'Suresh', 'Kavya', 'Ravi', 'Meera'];
    final lastNames = ['Kumar', 'Nair', 'Singh', 'Reddy', 'Mehta', 'Sharma', 'Babu', 'Iyer', 'Rao', 'Gupta'];
    return '${firstNames[_random.nextInt(firstNames.length)]} ${lastNames[_random.nextInt(lastNames.length)]}';
  }

  static String generateRandomPhone() {
    return '+91 ${_random.nextInt(90000) + 10000} ${_random.nextInt(90000) + 10000}';
  }

  static double generateRandomPrice({double min = 10.0, double max = 500.0}) {
    return (min + _random.nextDouble() * (max - min)).roundToDouble();
  }

  static int generateRandomQuantity({int min = 1, int max = 50}) {
    return min + _random.nextInt(max - min + 1);
  }

  static String getRandomOrderStatus() {
    final statuses = ['PENDING', 'CONFIRMED', 'PREPARING', 'READY', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED'];
    return statuses[_random.nextInt(statuses.length)];
  }

  // Method to generate additional random orders for testing
  static List<Order> generateRandomOrders(int count) {
    final orders = <Order>[];
    final products = mockProducts;

    for (int i = 0; i < count; i++) {
      final selectedProducts = <OrderItem>[];
      final productCount = _random.nextInt(3) + 1; // 1-3 products per order

      for (int j = 0; j < productCount; j++) {
        final product = products[_random.nextInt(products.length)];
        final quantity = generateRandomQuantity(min: 1, max: 5);
        selectedProducts.add(OrderItem(
          productId: product.id,
          productName: product.name,
          quantity: quantity,
          price: product.price,
          unitPrice: product.price,
          total: product.price * quantity,
        ));
      }

      final subtotal = selectedProducts.fold<double>(0, (sum, item) => sum + item.totalPrice);
      final deliveryFee = _random.nextDouble() * 25 + 10; // 10-35 delivery fee

      final orderDate = DateTime.now().subtract(Duration(
        hours: _random.nextInt(168), // Within last week
        minutes: _random.nextInt(60),
      ));

      orders.add(Order(
        id: generateRandomOrderId(),
        customerId: 'customer_${_random.nextInt(100).toString().padLeft(3, '0')}',
        customerName: generateRandomCustomerName(),
        customerPhone: generateRandomPhone(),
        address: 'Random Address ${i + 1}, Bengaluru',
        items: selectedProducts,
        subtotal: subtotal,
        tax: 0.00,
        deliveryFee: deliveryFee,
        discount: 0.00,
        total: subtotal + deliveryFee,
        totalAmount: subtotal + deliveryFee,
        status: getRandomOrderStatus(),
        paymentStatus: 'PAID',
        paymentMethod: ['Cash on Delivery', 'UPI', 'Card'][_random.nextInt(3)],
        createdAt: orderDate,
        updatedAt: orderDate,
        orderDate: orderDate,
      ));
    }

    return orders;
  }
}