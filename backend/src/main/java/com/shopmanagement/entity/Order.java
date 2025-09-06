package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import com.shopmanagement.shop.entity.Shop;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "orders")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Order {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(unique = true, nullable = false)
    private String orderNumber;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id", nullable = false)
    private Customer customer;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_id", nullable = false)
    private Shop shop;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OrderStatus status;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PaymentStatus paymentStatus;
    
    @Enumerated(EnumType.STRING)
    private PaymentMethod paymentMethod;
    
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal subtotal;
    
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal taxAmount;
    
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal deliveryFee;
    
    @Column(precision = 10, scale = 2)
    private BigDecimal discountAmount;
    
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal totalAmount;
    
    @Column(length = 500)
    private String notes;
    
    @Column(length = 500)
    private String cancellationReason;
    
    // Delivery Information
    @Column(length = 200)
    private String deliveryAddress;
    
    @Column(length = 100)
    private String deliveryCity;
    
    @Column(length = 100)
    private String deliveryState;
    
    @Column(length = 10)
    private String deliveryPostalCode;
    
    @Column(length = 15)
    private String deliveryPhone;
    
    @Column(length = 100)
    private String deliveryContactName;
    
    private LocalDateTime estimatedDeliveryTime;
    private LocalDateTime actualDeliveryTime;
    
    // Order Items
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<OrderItem> orderItems;
    
    // Audit fields
    @Column(nullable = false, length = 100)
    @Builder.Default
    private String createdBy = "system";
    
    @Column(nullable = false, length = 100)
    @Builder.Default
    private String updatedBy = "system";
    
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;
    
    // Enums
    public enum OrderStatus {
        PENDING, CONFIRMED, PREPARING, READY, READY_FOR_PICKUP, OUT_FOR_DELIVERY, DELIVERED, COMPLETED, CANCELLED, REFUNDED
    }
    
    public enum PaymentStatus {
        PENDING, PAID, FAILED, REFUNDED, PARTIALLY_REFUNDED
    }
    
    public enum PaymentMethod {
        CASH_ON_DELIVERY, ONLINE_PAYMENT, UPI, CARD, WALLET
    }
    
    // Helper methods
    @PrePersist
    private void generateOrderNumber() {
        if (orderNumber == null) {
            orderNumber = "ORD" + System.currentTimeMillis();
        }
    }
    
    public boolean canBeCancelled() {
        return status == OrderStatus.PENDING || status == OrderStatus.CONFIRMED;
    }
    
    public boolean isCompleted() {
        return status == OrderStatus.COMPLETED;
    }
    
    public boolean isDelivered() {
        return status == OrderStatus.DELIVERED;
    }
    
    public boolean isPaid() {
        return paymentStatus == PaymentStatus.PAID;
    }
}