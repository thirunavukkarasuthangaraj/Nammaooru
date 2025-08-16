package com.shopmanagement.service;

import com.shopmanagement.entity.User;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.repository.ShopRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

@Service
@RequiredArgsConstructor
public class ShopDashboardService {

    private final UserRepository userRepository;
    private final ShopRepository shopRepository;

    public Double getTodaysRevenue(String username) {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new RuntimeException("User not found"));
        
        // For now, return mock data since we don't have order/payment tables yet
        // TODO: Implement actual revenue calculation when order system is ready
        return Math.random() * 10000 + 5000; // Random revenue between 5000-15000
    }

    public Long getTodaysOrderCount(String username) {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new RuntimeException("User not found"));
        
        // For now, return mock data since we don't have order tables yet
        // TODO: Implement actual order count when order system is ready
        return (long) (Math.random() * 50 + 10); // Random orders between 10-60
    }

    public Long getProductCount(String username) {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new RuntimeException("User not found"));
        
        // For now, return mock data since we don't have product tables yet
        // TODO: Implement actual product count when product system is ready
        return (long) (Math.random() * 200 + 50); // Random products between 50-250
    }

    public Long getLowStockCount(String username) {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new RuntimeException("User not found"));
        
        // For now, return mock data since we don't have product/inventory tables yet
        // TODO: Implement actual low stock count when inventory system is ready
        return (long) (Math.random() * 20 + 2); // Random low stock between 2-22
    }

    public List<Map<String, Object>> getRecentOrders(String username, int limit) {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new RuntimeException("User not found"));
        
        // For now, return mock data since we don't have order tables yet
        // TODO: Implement actual recent orders when order system is ready
        return IntStream.range(1, Math.min(limit + 1, 6))
            .mapToObj(i -> {
                Map<String, Object> order = new HashMap<>();
                order.put("id", "ORD-" + String.format("%04d", 1000 + i));
                order.put("customerName", getRandomCustomerName());
                order.put("total", Math.random() * 2000 + 500);
                order.put("status", getRandomOrderStatus());
                order.put("createdAt", LocalDateTime.now().minusMinutes((long) (Math.random() * 120)));
                return order;
            })
            .collect(Collectors.toList());
    }

    public List<Map<String, Object>> getLowStockProducts(String username, int limit) {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new RuntimeException("User not found"));
        
        // For now, return mock data since we don't have product tables yet
        // TODO: Implement actual low stock products when product system is ready
        return IntStream.range(1, Math.min(limit + 1, 4))
            .mapToObj(i -> {
                Map<String, Object> product = new HashMap<>();
                product.put("id", i);
                product.put("name", getRandomProductName(i));
                product.put("category", getRandomCategory());
                product.put("stock", (int) (Math.random() * 5 + 1)); // 1-5 stock
                product.put("imageUrl", getPlaceholderImage());
                return product;
            })
            .collect(Collectors.toList());
    }

    public Long getCustomerCount(String username) {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new RuntimeException("User not found"));
        
        // For now, return mock data since we don't have customer tables yet
        // TODO: Implement actual customer count when customer system is ready
        return (long) (Math.random() * 1000 + 100); // Random customers between 100-1100
    }

    public Long getNewCustomerCount(String username) {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new RuntimeException("User not found"));
        
        // For now, return mock data since we don't have customer tables yet
        // TODO: Implement actual new customer count when customer system is ready
        return (long) (Math.random() * 20 + 5); // Random new customers between 5-25
    }

    // Helper methods for mock data
    private String getRandomCustomerName() {
        String[] names = {"Rajesh Kumar", "Priya Sharma", "Amit Singh", "Sunita Patel", "Ravi Gupta"};
        return names[(int) (Math.random() * names.length)];
    }

    private String getRandomOrderStatus() {
        String[] statuses = {"PENDING", "PROCESSING", "COMPLETED", "DELIVERED"};
        return statuses[(int) (Math.random() * statuses.length)];
    }

    private String getRandomProductName(int i) {
        String[] products = {"Organic Rice", "Fresh Tomatoes", "Milk Packets", "Wheat Flour", "Cooking Oil"};
        return products[i % products.length];
    }

    private String getRandomCategory() {
        String[] categories = {"Groceries", "Vegetables", "Dairy", "Bakery"};
        return categories[(int) (Math.random() * categories.length)];
    }

    private String getPlaceholderImage() {
        return "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHZpZXdCb3g9IjAgMCA0MCA0MCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHJlY3Qgd2lkdGg9IjQwIiBoZWlnaHQ9IjQwIiBmaWxsPSIjRjNGNEY2Ii8+Cjx0ZXh0IHg9IjIwIiB5PSIyMCIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZG9taW5hbnQtYmFzZWxpbmU9ImNlbnRyYWwiIGZpbGw9IiM5Q0EzQUYiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSI4Ij5QPC90ZXh0Pgo8L3N2Zz4=";
    }
}