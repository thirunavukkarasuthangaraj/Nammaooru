package com.shopmanagement.controller;

import com.shopmanagement.entity.Promotion;
import com.shopmanagement.repository.PromotionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.Map;

@RestController
@RequestMapping("/api/promotions")
@RequiredArgsConstructor
@Slf4j
public class PromotionController {
    
    private final PromotionRepository promotionRepository;
    
    @GetMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Page<Promotion>> getAllPromotions(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDirection) {
        Sort.Direction direction = sortDirection.equalsIgnoreCase("desc") ? Sort.Direction.DESC : Sort.Direction.ASC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        Page<Promotion> promotions = promotionRepository.findAll(pageable);
        return ResponseEntity.ok(promotions);
    }
    
    @GetMapping("/enums")
    public ResponseEntity<Map<String, Object>> getPromotionEnums() {
        return ResponseEntity.ok(Map.of(
                "promotionTypes", Promotion.PromotionType.values(),
                "promotionStatuses", Promotion.PromotionStatus.values()
        ));
    }
}