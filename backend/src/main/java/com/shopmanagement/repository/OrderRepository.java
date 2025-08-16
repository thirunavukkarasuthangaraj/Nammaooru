package com.shopmanagement.repository;

import com.shopmanagement.entity.Order;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    
    // Find order by order number
    Optional<Order> findByOrderNumber(String orderNumber);
    
    // Find orders by customer
    Page<Order> findByCustomerId(Long customerId, Pageable pageable);
    
    // Find orders by shop
    Page<Order> findByShopId(Long shopId, Pageable pageable);
    
    // Find orders by status
    Page<Order> findByStatus(Order.OrderStatus status, Pageable pageable);
    
    // Find orders by payment status
    Page<Order> findByPaymentStatus(Order.PaymentStatus paymentStatus, Pageable pageable);
    
    // Find orders by shop and status
    Page<Order> findByShopIdAndStatus(Long shopId, Order.OrderStatus status, Pageable pageable);
    
    // Find orders by customer and status
    Page<Order> findByCustomerIdAndStatus(Long customerId, Order.OrderStatus status, Pageable pageable);
    
    // Find orders within date range
    @Query("SELECT o FROM Order o WHERE o.createdAt BETWEEN :startDate AND :endDate")
    Page<Order> findByDateRange(@Param("startDate") LocalDateTime startDate, 
                               @Param("endDate") LocalDateTime endDate, 
                               Pageable pageable);
    
    // Find orders by shop within date range
    @Query("SELECT o FROM Order o WHERE o.shop.id = :shopId AND o.createdAt BETWEEN :startDate AND :endDate")
    Page<Order> findByShopIdAndDateRange(@Param("shopId") Long shopId,
                                        @Param("startDate") LocalDateTime startDate,
                                        @Param("endDate") LocalDateTime endDate,
                                        Pageable pageable);
    
    // Search orders
    @Query("SELECT o FROM Order o WHERE " +
           "LOWER(o.orderNumber) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(o.customer.firstName) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(o.customer.lastName) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(o.shop.name) LIKE LOWER(CONCAT('%', :searchTerm, '%'))")
    Page<Order> searchOrders(@Param("searchTerm") String searchTerm, Pageable pageable);
    
    // Analytics queries
    @Query("SELECT COUNT(o) FROM Order o WHERE o.shop.id = :shopId")
    Long countOrdersByShop(@Param("shopId") Long shopId);
    
    @Query("SELECT COUNT(o) FROM Order o WHERE o.shop.id = :shopId AND o.status = :status")
    Long countOrdersByShopAndStatus(@Param("shopId") Long shopId, @Param("status") Order.OrderStatus status);
    
    @Query("SELECT SUM(o.totalAmount) FROM Order o WHERE o.shop.id = :shopId AND o.paymentStatus = 'PAID'")
    BigDecimal getTotalRevenueByShop(@Param("shopId") Long shopId);
    
    @Query("SELECT SUM(o.totalAmount) FROM Order o WHERE o.shop.id = :shopId AND o.paymentStatus = 'PAID' AND o.createdAt BETWEEN :startDate AND :endDate")
    BigDecimal getRevenueByShopAndDateRange(@Param("shopId") Long shopId,
                                           @Param("startDate") LocalDateTime startDate,
                                           @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT AVG(o.totalAmount) FROM Order o WHERE o.shop.id = :shopId AND o.paymentStatus = 'PAID'")
    BigDecimal getAverageOrderValueByShop(@Param("shopId") Long shopId);
    
    // Find pending orders for delivery
    @Query("SELECT o FROM Order o WHERE o.status IN ('CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP') AND o.estimatedDeliveryTime < :currentTime")
    List<Order> findOverdueOrders(@Param("currentTime") LocalDateTime currentTime);
    
    // Recent orders
    @Query("SELECT o FROM Order o WHERE o.shop.id = :shopId ORDER BY o.createdAt DESC")
    List<Order> findRecentOrdersByShop(@Param("shopId") Long shopId, Pageable pageable);
    
    // Monthly revenue
    @Query("SELECT MONTH(o.createdAt) as month, SUM(o.totalAmount) as revenue " +
           "FROM Order o WHERE o.shop.id = :shopId AND o.paymentStatus = 'PAID' AND YEAR(o.createdAt) = :year " +
           "GROUP BY MONTH(o.createdAt) ORDER BY MONTH(o.createdAt)")
    List<Object[]> getMonthlyRevenue(@Param("shopId") Long shopId, @Param("year") int year);
    
    // Order status distribution
    @Query("SELECT o.status, COUNT(o) FROM Order o WHERE o.shop.id = :shopId GROUP BY o.status")
    List<Object[]> getOrderStatusDistribution(@Param("shopId") Long shopId);
    
    // Analytics methods
    @Query("SELECT COUNT(o) FROM Order o WHERE o.createdAt >= :startDate AND o.createdAt <= :endDate")
    Long countAnalyticsByPeriod(@Param("startDate") LocalDateTime startDate, 
                               @Param("endDate") LocalDateTime endDate);
}