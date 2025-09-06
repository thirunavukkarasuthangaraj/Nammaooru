package com.shopmanagement.config;

import com.shopmanagement.entity.User;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.product.entity.ProductCategory;
import com.shopmanagement.product.entity.MasterProduct;
import com.shopmanagement.product.entity.MasterProductImage;
import com.shopmanagement.product.repository.ProductCategoryRepository;
import com.shopmanagement.product.repository.MasterProductRepository;
import com.shopmanagement.product.repository.MasterProductImageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.math.BigDecimal;

@Configuration
@RequiredArgsConstructor
@Slf4j
public class DataInitializer {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final ProductCategoryRepository categoryRepository;
    private final MasterProductRepository masterProductRepository;
    private final MasterProductImageRepository masterProductImageRepository;

    @Bean
    CommandLineRunner initDatabase() {
        return args -> {
            // Create admin user if it doesn't exist (check both email and username)
            if (!userRepository.existsByEmail("admin@example.com") && !userRepository.existsByUsername("admin")) {
                User admin = User.builder()
                        .username("admin")
                        .email("admin@example.com")
                        .password(passwordEncoder.encode("admin123"))
                        .role(User.UserRole.ADMIN)
                        .isActive(true)
                        .passwordChangeRequired(false)
                        .isTemporaryPassword(false)
                        .build();
                
                userRepository.save(admin);
                log.info("Admin user created with email: admin@example.com and password: admin123");
            } else {
                log.info("Admin user already exists");
            }

            // Create a test shop owner if needed
            if (!userRepository.existsByEmail("shopowner@example.com") && !userRepository.existsByUsername("shopowner")) {
                User shopOwner = User.builder()
                        .username("shopowner")
                        .email("shopowner@example.com")
                        .password(passwordEncoder.encode("shop123"))
                        .role(User.UserRole.SHOP_OWNER)
                        .isActive(true)
                        .passwordChangeRequired(false)
                        .isTemporaryPassword(false)
                        .build();
                
                userRepository.save(shopOwner);
                log.info("Shop owner user created with email: shopowner@example.com and password: shop123");
            }

            // Create a test customer if needed
            if (!userRepository.existsByEmail("customer@example.com") && !userRepository.existsByUsername("customer")) {
                User customer = User.builder()
                        .username("customer")
                        .email("customer@example.com")
                        .password(passwordEncoder.encode("customer123"))
                        .role(User.UserRole.USER) // USER is the customer role
                        .isActive(true)
                        .passwordChangeRequired(false)
                        .isTemporaryPassword(false)
                        .build();
                
                userRepository.save(customer);
                log.info("Customer user created with email: customer@example.com and password: customer123");
            }

            // Create a delivery partner if needed
            if (!userRepository.existsByEmail("delivery@example.com") && !userRepository.existsByUsername("delivery")) {
                User delivery = User.builder()
                        .username("delivery")
                        .email("delivery@example.com")
                        .password(passwordEncoder.encode("delivery123"))
                        .role(User.UserRole.DELIVERY_PARTNER)
                        .isActive(true)
                        .passwordChangeRequired(false)
                        .isTemporaryPassword(false)
                        .build();
                
                userRepository.save(delivery);
                log.info("Delivery partner created with email: delivery@example.com and password: delivery123");
            }

            // Create superadmin user if it doesn't exist
            if (!userRepository.existsByEmail("superadmin@shopmanagement.com") && !userRepository.existsByUsername("superadmin")) {
                User superadmin = User.builder()
                        .username("superadmin")
                        .email("superadmin@shopmanagement.com")
                        .password(passwordEncoder.encode("password"))
                        .role(User.UserRole.SUPER_ADMIN)
                        .isActive(true)
                        .passwordChangeRequired(false)
                        .isTemporaryPassword(false)
                        .build();
                
                userRepository.save(superadmin);
                log.info("Superadmin user created with email: superadmin@shopmanagement.com and password: password");
            }

            // Create test user with your email
            if (!userRepository.existsByEmail("thiruna2394@gmail.com") && !userRepository.existsByUsername("thiruna")) {
                User testUser = User.builder()
                        .username("thiruna")
                        .email("thiruna2394@gmail.com")
                        .password(passwordEncoder.encode("test123"))
                        .role(User.UserRole.USER)
                        .isActive(true)
                        .passwordChangeRequired(false)
                        .isTemporaryPassword(false)
                        .build();
                
                userRepository.save(testUser);
                log.info("Test user created with email: thiruna2394@gmail.com and password: test123");
            }

            // Create test product categories and products
            initializeTestProductsAndCategories();
        };
    }

    private void initializeTestProductsAndCategories() {
        // Create categories if they don't exist
        ProductCategory groceryCategory = categoryRepository.findBySlug("grocery")
                .orElseGet(() -> {
                    ProductCategory category = ProductCategory.builder()
                            .name("Grocery")
                            .description("Daily grocery items")
                            .slug("grocery")
                            .isActive(true)
                            .sortOrder(1)
                            .iconUrl("🥬")
                            .createdBy("system")
                            .build();
                    return categoryRepository.save(category);
                });

        ProductCategory medicineCategory = categoryRepository.findBySlug("medicine")
                .orElseGet(() -> {
                    ProductCategory category = ProductCategory.builder()
                            .name("Medicine")
                            .description("Medical and healthcare products")
                            .slug("medicine")
                            .isActive(true)
                            .sortOrder(2)
                            .iconUrl("💊")
                            .createdBy("system")
                            .build();
                    return categoryRepository.save(category);
                });

        ProductCategory snacksCategory = categoryRepository.findBySlug("snacks")
                .orElseGet(() -> {
                    ProductCategory category = ProductCategory.builder()
                            .name("Snacks")
                            .description("Snacks and beverages")
                            .slug("snacks")
                            .isActive(true)
                            .sortOrder(3)
                            .iconUrl("🍿")
                            .createdBy("system")
                            .build();
                    return categoryRepository.save(category);
                });

        // Create test products if they don't exist
        createTestProductIfNotExists("RICE001", "Basmati Rice", "Premium quality basmati rice (1kg)", 
                groceryCategory, "Rice", "kg", new BigDecimal("1.000"), "https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400&h=300&fit=crop");

        createTestProductIfNotExists("WHEAT001", "Wheat Flour", "Fresh wheat flour for daily use (1kg)", 
                groceryCategory, "Aashirvaad", "kg", new BigDecimal("1.000"), "https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400&h=300&fit=crop");

        createTestProductIfNotExists("OIL001", "Sunflower Oil", "Refined sunflower cooking oil (1L)", 
                groceryCategory, "Fortune", "liter", new BigDecimal("1.000"), "https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400&h=300&fit=crop");

        createTestProductIfNotExists("MILK001", "Fresh Milk", "Pure cow milk (500ml)", 
                groceryCategory, "Nandini", "ml", new BigDecimal("500.000"), "https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400&h=300&fit=crop");

        createTestProductIfNotExists("SUGAR001", "Sugar", "Pure white sugar (1kg)", 
                groceryCategory, "Madhur", "kg", new BigDecimal("1.000"), "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400&h=300&fit=crop");

        createTestProductIfNotExists("TEA001", "Tea Powder", "Premium tea powder (250g)", 
                groceryCategory, "Tata Tea", "gm", new BigDecimal("250.000"), "https://images.unsplash.com/photo-1597318433840-c4b9c5d1eca0?w=400&h=300&fit=crop");

        createTestProductIfNotExists("MED001", "Paracetamol", "Fever and pain relief tablets (10 tablets)", 
                medicineCategory, "Crocin", "piece", new BigDecimal("10.000"), "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&h=300&fit=crop");

        createTestProductIfNotExists("MED002", "Cough Syrup", "Relief from cough and cold (100ml)", 
                medicineCategory, "Benadryl", "ml", new BigDecimal("100.000"), "https://images.unsplash.com/photo-1550572017-edd951b55104?w=400&h=300&fit=crop");

        createTestProductIfNotExists("SNK001", "Potato Chips", "Crispy potato chips (50g)", 
                snacksCategory, "Lays", "gm", new BigDecimal("50.000"), "https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400&h=300&fit=crop");

        createTestProductIfNotExists("SNK002", "Biscuits", "Delicious cream biscuits (100g)", 
                snacksCategory, "Parle-G", "gm", new BigDecimal("100.000"), "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400&h=300&fit=crop");

        log.info("Test products and categories initialized successfully!");
    }

    private void createTestProductIfNotExists(String sku, String name, String description, 
                                            ProductCategory category, String brand, String baseUnit, 
                                            BigDecimal baseWeight, String imageUrl) {
        if (!masterProductRepository.existsBySku(sku)) {
            MasterProduct product = MasterProduct.builder()
                    .name(name)
                    .description(description)
                    .sku(sku)
                    .category(category)
                    .brand(brand)
                    .baseUnit(baseUnit)
                    .baseWeight(baseWeight)
                    .status(MasterProduct.ProductStatus.ACTIVE)
                    .isFeatured(true)
                    .isGlobal(true)
                    .createdBy("system")
                    .build();

            MasterProduct savedProduct = masterProductRepository.save(product);

            // Add product image
            MasterProductImage productImage = MasterProductImage.builder()
                    .masterProduct(savedProduct)
                    .imageUrl(imageUrl)
                    .isPrimary(true)
                    .altText(name + " image")
                    .sortOrder(1)
                    .build();

            masterProductImageRepository.save(productImage);
            log.info("Created test product: {} with SKU: {}", name, sku);
        }
    }
}