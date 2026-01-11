package com.shopmanagement.entity;

import com.shopmanagement.product.entity.ShopProduct;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "order_items")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderItem {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_product_id", nullable = false)
    private ShopProduct shopProduct;
    
    @Column(nullable = false)
    private Integer quantity;
    
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal unitPrice;
    
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal totalPrice;
    
    @Column(length = 500)
    private String specialInstructions;
    
    // Product details at time of order (for historical purposes)
    @Column(nullable = false, length = 255)
    private String productName;
    
    @Column(length = 500)
    private String productDescription;
    
    @Column(length = 50)
    private String productSku;
    
    @Column(length = 2000)
    private String productImageUrl;

    // Track if item was added by shop owner (not in original customer order)
    @Column(nullable = false)
    @Builder.Default
    private Boolean addedByShopOwner = false;

    // Audit fields
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;
    
    // Helper methods
    @PrePersist
    @PreUpdate
    private void calculateTotalPrice() {
        if (quantity != null && unitPrice != null) {
            totalPrice = unitPrice.multiply(BigDecimal.valueOf(quantity));
        }
    }
}