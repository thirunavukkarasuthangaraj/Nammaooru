import 'package:flutter/material.dart';

class SimpleProductsTest extends StatelessWidget {
  const SimpleProductsTest({super.key});

  @override
  Widget build(BuildContext context) {
    // Simple test products
    final products = [
      {
        'name': 'Coffee Powder',
        'price': 150.0,
        'unit': '500g',
        'image': 'https://images.unsplash.com/photo-1447933601403-0c6688de566e?w=300',
      },
      {
        'name': 'Basmati Rice',
        'price': 80.0,
        'unit': '1kg',
        'image': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=300',
      },
      {
        'name': 'Cooking Oil',
        'price': 120.0,
        'unit': '1L',
        'image': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=300',
      },
      {
        'name': 'Sugar',
        'price': 45.0,
        'unit': '1kg',
        'image': 'https://images.unsplash.com/photo-1559181567-c3190ca9959b?w=300',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Products Test'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Image.network(
                        product['image'] as String,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),

                  // Product Details
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Name
                          Text(
                            product['name'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: 4),

                          // Unit
                          Text(
                            product['unit'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),

                          SizedBox(height: 4),

                          // Price and Add Button
                          Row(
                            children: [
                              Text(
                                '₹${(product['price'] as double).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Spacer(),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added ${product['name']} to cart!'),
                                      duration: Duration(seconds: 1),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'ADD',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}