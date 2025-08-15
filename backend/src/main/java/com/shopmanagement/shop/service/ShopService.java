package com.shopmanagement.shop.service;

import com.shopmanagement.shop.dto.ShopCreateRequest;
import com.shopmanagement.shop.dto.ShopResponse;
import com.shopmanagement.shop.dto.ShopUpdateRequest;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.exception.ShopNotFoundException;
import com.shopmanagement.shop.mapper.ShopMapper;
import com.shopmanagement.shop.repository.ShopRepository;
import com.shopmanagement.shop.util.ShopSlugGenerator;
import com.shopmanagement.service.EmailService;
import com.shopmanagement.service.AuthService;
import com.shopmanagement.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ShopService {

    private final ShopRepository shopRepository;
    private final ShopMapper shopMapper;
    private final ShopSlugGenerator slugGenerator;
    private final EmailService emailService;
    private final AuthService authService;

    public ShopResponse createShop(ShopCreateRequest request) {
        log.info("Creating new shop: {}", request.getName());
        
        String shopId = generateShopId();
        String slug = generateUniqueSlug(request.getName(), request.getCity());
        
        Shop shop = shopMapper.toEntity(request);
        shop.setShopId(shopId);
        shop.setSlug(slug);
        shop.setCreatedBy(getCurrentUsername());
        shop.setStatus(Shop.ShopStatus.PENDING);
        
        if (request.getCountry() == null || request.getCountry().isEmpty()) {
            shop.setCountry("India");
        }
        
        Shop savedShop = shopRepository.save(shop);
        log.info("Shop created successfully with ID: {} - Status: {}", savedShop.getShopId(), savedShop.getStatus());
        
        return shopMapper.toResponse(savedShop);
    }

    @Transactional(readOnly = true)
    public Page<ShopResponse> getAllShops(Pageable pageable) {
        return shopRepository.findAll(pageable)
                .map(shopMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<ShopResponse> getActiveShops(Pageable pageable) {
        return shopRepository.findByIsActiveTrue(pageable)
                .map(shopMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<ShopResponse> getShopsByStatus(Shop.ShopStatus status, Pageable pageable) {
        return shopRepository.findByStatus(status, pageable)
                .map(shopMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<ShopResponse> getShopsByBusinessType(Shop.BusinessType businessType, Pageable pageable) {
        return shopRepository.findByBusinessType(businessType, pageable)
                .map(shopMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<ShopResponse> searchShops(String searchTerm, Pageable pageable) {
        return shopRepository.searchShops(searchTerm, pageable)
                .map(shopMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<ShopResponse> filterShops(Specification<Shop> spec, Pageable pageable) {
        Page<Shop> shopPage = shopRepository.findAll(spec, pageable);
        
        // Fetch complete shop data with images and documents separately to avoid MultipleBagFetchException
        List<Long> shopIds = shopPage.getContent().stream()
                .map(Shop::getId)
                .toList();
        
        if (shopIds.isEmpty()) {
            return shopPage.map(shopMapper::toResponse);
        }
        
        // Fetch shops with images and documents separately
        List<Shop> shopsWithImages = shopRepository.findAllWithImagesByIds(shopIds);
        List<Shop> shopsWithDocuments = shopRepository.findAllWithDocumentsByIds(shopIds);
        
        // Create maps for quick lookup
        Map<Long, Shop> imageMap = shopsWithImages.stream()
                .collect(Collectors.toMap(Shop::getId, shop -> shop));
        Map<Long, Shop> documentMap = shopsWithDocuments.stream()
                .collect(Collectors.toMap(Shop::getId, shop -> shop));
        
        // Map to responses maintaining the original order
        List<ShopResponse> responses = shopPage.getContent().stream()
                .map(shop -> {
                    // Enrich shop with images and documents
                    Shop shopWithImages = imageMap.get(shop.getId());
                    Shop shopWithDocuments = documentMap.get(shop.getId());
                    
                    if (shopWithImages != null && shopWithImages.getImages() != null) {
                        shop.setImages(shopWithImages.getImages());
                    }
                    if (shopWithDocuments != null && shopWithDocuments.getDocuments() != null) {
                        shop.setDocuments(shopWithDocuments.getDocuments());
                    }
                    
                    return shopMapper.toResponse(shop);
                })
                .toList();
        
        return new org.springframework.data.domain.PageImpl<>(
            responses, pageable, shopPage.getTotalElements());
    }

    @Transactional(readOnly = true)
    public ShopResponse getShopById(Long id) {
        Shop shop = shopRepository.findById(id)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with id: " + id));
        return shopMapper.toResponse(shop);
    }

    @Transactional(readOnly = true)
    public ShopResponse getShopByShopId(String shopId) {
        Shop shop = shopRepository.findByShopId(shopId)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with shop ID: " + shopId));
        return shopMapper.toResponse(shop);
    }

    @Transactional(readOnly = true)
    public ShopResponse getShopBySlug(String slug) {
        Shop shop = shopRepository.findBySlug(slug)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with slug: " + slug));
        return shopMapper.toResponse(shop);
    }

    public ShopResponse updateShop(Long id, ShopUpdateRequest request) {
        log.info("Updating shop with ID: {}", id);
        
        Shop shop = shopRepository.findById(id)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with id: " + id));

        shopMapper.updateEntityFromRequest(request, shop);
        shop.setUpdatedBy(getCurrentUsername());
        
        if (request.getName() != null && !request.getName().equals(shop.getName()) && request.getCity() != null) {
            String newSlug = generateUniqueSlug(request.getName(), request.getCity());
            shop.setSlug(newSlug);
        }

        Shop updatedShop = shopRepository.save(shop);
        log.info("Shop updated successfully: {}", updatedShop.getShopId());
        
        return shopMapper.toResponse(updatedShop);
    }

    public void deleteShop(Long id) {
        log.info("Deleting shop with ID: {}", id);
        
        Shop shop = shopRepository.findById(id)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with id: " + id));
        
        shopRepository.delete(shop);
        log.info("Shop deleted successfully: {}", shop.getShopId());
    }

    public ShopResponse approveShop(Long id) {
        return updateShopStatus(id, Shop.ShopStatus.APPROVED);
    }

    public ShopResponse rejectShop(Long id) {
        return updateShopStatus(id, Shop.ShopStatus.REJECTED);
    }

    public ShopResponse suspendShop(Long id) {
        return updateShopStatus(id, Shop.ShopStatus.SUSPENDED);
    }

    private ShopResponse updateShopStatus(Long id, Shop.ShopStatus status) {
        log.info("Updating shop status to {} for shop ID: {}", status, id);
        
        Shop shop = shopRepository.findById(id)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with id: " + id));
        
        shop.setStatus(status);
        shop.setUpdatedBy(getCurrentUsername());
        
        if (status == Shop.ShopStatus.APPROVED) {
            shop.setIsVerified(true);
            
            // Create shop owner user account and send welcome email
            try {
                String username = generateUsername(shop.getOwnerName());
                String temporaryPassword = generateTemporaryPassword();
                
                // Create user account
                User shopOwnerUser = authService.createShopOwnerUser(username, shop.getOwnerEmail(), temporaryPassword);
                log.info("Created shop owner user: {} for shop: {}", username, shop.getName());
                
                // Send welcome email with credentials
                emailService.sendShopOwnerWelcomeEmail(
                    shop.getOwnerEmail(),
                    shop.getOwnerName(),
                    username,
                    temporaryPassword,
                    shop.getName()
                );
                log.info("Welcome email sent to: {}", shop.getOwnerEmail());
                
            } catch (Exception e) {
                log.error("Failed to create user account or send email for shop: {}", shop.getName(), e);
                // Continue with shop approval even if user creation fails
                // This can be handled manually by admin later
            }
        }
        
        Shop updatedShop = shopRepository.save(shop);
        log.info("Shop status updated successfully: {}", updatedShop.getShopId());
        
        return shopMapper.toResponse(updatedShop);
    }
    
    private String generateUsername(String ownerName) {
        // Generate username from owner name
        String baseUsername = ownerName.toLowerCase()
                .replaceAll("[^a-z0-9]", "")
                .substring(0, Math.min(ownerName.length(), 10));
        
        // Add random numbers to ensure uniqueness
        String randomSuffix = String.valueOf((int)(Math.random() * 1000));
        return baseUsername + randomSuffix;
    }
    
    private String generateTemporaryPassword() {
        // Generate a secure temporary password
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        StringBuilder password = new StringBuilder();
        for (int i = 0; i < 12; i++) {
            password.append(chars.charAt((int) (Math.random() * chars.length())));
        }
        return password.toString();
    }

    @Transactional(readOnly = true)
    public List<ShopResponse> getNearbyShops(BigDecimal latitude, BigDecimal longitude, double radiusInMiles) {
        List<Shop> nearbyShops = shopRepository.findShopsWithinRadius(latitude, longitude, radiusInMiles);
        return nearbyShops.stream()
                .map(shopMapper::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ShopResponse> getFeaturedShops() {
        List<Shop> featuredShops = shopRepository.findFeaturedShops();
        return featuredShops.stream()
                .map(shopMapper::toResponse)
                .collect(Collectors.toList());
    }

    private String generateShopId() {
        String shopId;
        do {
            shopId = "SH" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        } while (shopRepository.existsByShopId(shopId));
        return shopId;
    }

    private String generateUniqueSlug(String name, String city) {
        String baseSlug = slugGenerator.generateUniqueSlug(name, city);
        String slug = baseSlug;
        int counter = 1;
        
        while (shopRepository.existsBySlug(slug)) {
            slug = baseSlug + "-" + counter;
            counter++;
        }
        
        return slug;
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null ? authentication.getName() : "system";
    }

    // Statistics methods
    public long getTotalShopsCount() {
        return shopRepository.count();
    }

    public long getActiveShopsCount() {
        return shopRepository.countByIsActiveTrue();
    }

    public long getPendingShopsCount() {
        return shopRepository.countByStatus(Shop.ShopStatus.PENDING);
    }

    public long getRejectedShopsCount() {
        return shopRepository.countByStatus(Shop.ShopStatus.REJECTED);
    }

    public long getSuspendedShopsCount() {
        return shopRepository.countByStatus(Shop.ShopStatus.SUSPENDED);
    }

    public ShopResponse getCurrentUserShop() {
        String currentUsername = getCurrentUsername();
        log.info("Getting shop for current user: {}", currentUsername);
        
        // For shop owners, find their shop by createdBy
        // For admin users, just return the first active shop as a demo
        if ("admin".equals(currentUsername)) {
            log.info("Admin user accessing shop demo - returning first active shop");
            Page<Shop> activeShopsPage = shopRepository.findByIsActiveTrue(PageRequest.of(0, 1));
            if (activeShopsPage.isEmpty()) {
                throw new ShopNotFoundException("No active shops available for demo");
            }
            return shopMapper.toResponse(activeShopsPage.getContent().get(0));
        }
        
        Shop shop = shopRepository.findByCreatedBy(currentUsername)
            .orElseThrow(() -> new ShopNotFoundException("No shop found for current user"));
        
        return shopMapper.toResponse(shop);
    }

}