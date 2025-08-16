package com.shopmanagement.controller;

import com.shopmanagement.entity.BusinessHours;
import com.shopmanagement.repository.BusinessHoursRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.DayOfWeek;
import java.util.Map;

@RestController
@RequestMapping("/api/business-hours")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(originPatterns = {"*"})
public class BusinessHoursController {
    
    private final BusinessHoursRepository businessHoursRepository;
    
    @GetMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Page<BusinessHours>> getAllBusinessHours(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "dayOfWeek") String sortBy,
            @RequestParam(defaultValue = "asc") String sortDirection) {
        Sort.Direction direction = sortDirection.equalsIgnoreCase("desc") ? Sort.Direction.DESC : Sort.Direction.ASC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        Page<BusinessHours> businessHours = businessHoursRepository.findAll(pageable);
        return ResponseEntity.ok(businessHours);
    }
    
    @GetMapping("/enums")
    public ResponseEntity<Map<String, Object>> getBusinessHoursEnums() {
        return ResponseEntity.ok(Map.of(
                "daysOfWeek", DayOfWeek.values()
        ));
    }
}