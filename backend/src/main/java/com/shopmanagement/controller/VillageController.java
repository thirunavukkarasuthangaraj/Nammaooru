package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.Village;
import com.shopmanagement.service.VillageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/villages")
@RequiredArgsConstructor
@Slf4j
public class VillageController {

    private final VillageService villageService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Village>>> getActiveVillages() {
        try {
            List<Village> villages = villageService.getActiveVillages();
            return ResponseUtil.success(villages, "Active villages retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching active villages", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/admin/all")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<List<Village>>> getAllVillages() {
        try {
            List<Village> villages = villageService.getAllVillages();
            return ResponseUtil.success(villages, "All villages retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching all villages", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PostMapping("/admin")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Village>> createVillage(@RequestBody Village village) {
        try {
            Village created = villageService.create(village);
            return ResponseUtil.success(created, "Village created successfully");
        } catch (Exception e) {
            log.error("Error creating village", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/admin/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Village>> updateVillage(
            @PathVariable Long id,
            @RequestBody Village village) {
        try {
            Village updated = villageService.update(id, village);
            return ResponseUtil.success(updated, "Village updated successfully");
        } catch (Exception e) {
            log.error("Error updating village", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @DeleteMapping("/admin/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteVillage(@PathVariable Long id) {
        try {
            villageService.delete(id);
            return ResponseUtil.success(null, "Village deleted successfully");
        } catch (Exception e) {
            log.error("Error deleting village", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/admin/{id}/toggle")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Village>> toggleActive(@PathVariable Long id) {
        try {
            Village village = villageService.toggleActive(id);
            return ResponseUtil.success(village, "Village toggled successfully");
        } catch (Exception e) {
            log.error("Error toggling village", e);
            return ResponseUtil.error(e.getMessage());
        }
    }
}
