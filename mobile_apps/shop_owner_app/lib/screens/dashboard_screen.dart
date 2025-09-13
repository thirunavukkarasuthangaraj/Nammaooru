import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isShopOpen = true;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isShopOpen ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isShopOpen ? Icons.store : Icons.store_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 5),
                  Text(
                    isShopOpen ? 'OPEN' : 'CLOSED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            Switch(
              value: isShopOpen,
              onChanged: (value) {
                setState(() {
                  isShopOpen = value;
                });
              },
              activeColor: Colors.green,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '👋 Hello, Ramesh!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '🏪 Pizza Palace',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                  Text(
                    '📍 MG Road, Bangalore',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '⭐ 4.5 Rating (234 reviews)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('Orders', '12', Colors.blue),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard('Revenue', '₹2,400', Colors.green),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard('New Customers', '3', Colors.purple),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // New Orders
            Text(
              '🔔 NEW ORDERS (3)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 10),
            
            if (isShopOpen) ...[
              _buildOrderCard(
                orderNumber: 'ORD001',
                customerName: 'Suresh Kumar',
                customerPhone: '+91 98765 43210',
                items: '2x Margherita, 1x Coke',
                amount: '₹450',
                location: 'HSR Layout',
                timeAgo: '5 minutes ago',
                isNewOrder: true,
              ),
              SizedBox(height: 10),
              _buildOrderCard(
                orderNumber: 'ORD002',
                customerName: 'Priya Sharma',
                customerPhone: '+91 87654 32109',
                items: '1x Pepperoni, 2x Sprite',
                amount: '₹380',
                location: 'Koramangala',
                timeAgo: '8 minutes ago',
                isNewOrder: true,
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.store_mall_directory_outlined,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Shop is closed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Open shop to receive orders',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: 20),
            
            // Preparing Orders
            Text(
              '🍳 PREPARING ORDERS (2)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 10),
            
            _buildOrderCard(
              orderNumber: 'ORD003',
              customerName: 'Rajesh Kumar',
              customerPhone: '+91 90123 45678',
              items: '1x Chicken Burger, 1x Fries',
              amount: '₹320',
              location: 'BTM Layout',
              timeAgo: 'Prep Time: 15 mins',
              isPreparing: true,
            ),
            SizedBox(height: 10),
            _buildOrderCard(
              orderNumber: 'ORD004',
              customerName: 'Anita Singh',
              customerPhone: '+91 78901 23456',
              items: '2x Veg Pizza, 1x Juice',
              amount: '₹540',
              location: 'Jayanagar',
              timeAgo: 'Prep Time: 10 mins',
              isPreparing: true,
            ),
            
            SizedBox(height: 20),
            
            // Out for Delivery
            Text(
              '🚚 OUT FOR DELIVERY (1)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 10),
            
            _buildOrderCard(
              orderNumber: 'ORD005',
              customerName: 'Vikash Patel',
              customerPhone: '+91 67890 12345',
              items: '3x Margherita, 2x Coke',
              amount: '₹720',
              location: 'Indiranagar',
              timeAgo: 'Partner: Rajesh | ETA: 10 mins',
              isOutForDelivery: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
        onTap: (index) {
          if (index == 2) {
            Navigator.pushNamed(context, '/products');
          }
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard({
    required String orderNumber,
    required String customerName,
    required String customerPhone,
    required String items,
    required String amount,
    required String location,
    required String timeAgo,
    bool isNewOrder = false,
    bool isPreparing = false,
    bool isOutForDelivery = false,
  }) {
    Color borderColor = isNewOrder ? Colors.orange : 
                       isPreparing ? Colors.blue : 
                       isOutForDelivery ? Colors.green : Colors.grey[300]!;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🛍️ Order #$orderNumber',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  amount,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          
          Text(
            '👤 $customerName | 📞 $customerPhone',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            '🛍️ $items',
            style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.w500),
          ),
          Text(
            '🏠 $location',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            '⏰ $timeAgo',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 12),
          
          if (isNewOrder) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rejectOrder(orderNumber),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('REJECT'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptOrder(orderNumber),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('ACCEPT'),
                  ),
                ),
              ],
            ),
          ] else if (isPreparing) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _markReady(orderNumber),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('MARK READY'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.phone, size: 16),
                    label: Text('CALL'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isOutForDelivery) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.location_on, size: 16),
                    label: Text('TRACK'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.phone, size: 16),
                    label: Text('CALL'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _acceptOrder(String orderNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accept Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How long will it take to prepare?'),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimeButton('15 mins'),
                _buildTimeButton('30 mins'),
                _buildTimeButton('45 mins'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButton(String time) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order accepted! Prep time: $time'),
            backgroundColor: Colors.green,
          ),
        );
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
      child: Text(time, style: TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  void _rejectOrder(String orderNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order $orderNumber rejected!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _markReady(String orderNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order $orderNumber marked as ready! Delivery partner notified.'),
        backgroundColor: Colors.green,
      ),
    );
  }
}