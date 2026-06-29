package com.shopmanagement.label.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.label.dto.LabelTemplateRequest;
import com.shopmanagement.label.dto.LabelTemplateResponse;
import com.shopmanagement.label.service.LabelTemplateService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/label-templates")
@RequiredArgsConstructor
@Slf4j
public class LabelTemplateController {

    private final LabelTemplateService labelTemplateService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<LabelTemplateResponse>>> getAll() {
        return ResponseEntity.ok(ApiResponse.success(labelTemplateService.getAll()));
    }

    /** The common/default template used by the product Print Label action. */
    @GetMapping("/default")
    public ResponseEntity<ApiResponse<LabelTemplateResponse>> getDefault() {
        return ResponseEntity.ok(ApiResponse.success(labelTemplateService.getDefault()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<LabelTemplateResponse>> getById(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(labelTemplateService.getById(id)));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'MANAGER', 'SHOP_OWNER')")
    public ResponseEntity<ApiResponse<LabelTemplateResponse>> create(
            @Valid @RequestBody LabelTemplateRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                labelTemplateService.create(request), "Label template created"));
    }

    /** Save (upsert) the single common template — backs the designer Save button. */
    @PostMapping("/default")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'MANAGER', 'SHOP_OWNER')")
    public ResponseEntity<ApiResponse<LabelTemplateResponse>> saveDefault(
            @Valid @RequestBody LabelTemplateRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                labelTemplateService.saveDefault(request), "Label template saved"));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'MANAGER', 'SHOP_OWNER')")
    public ResponseEntity<ApiResponse<LabelTemplateResponse>> update(
            @PathVariable Long id, @Valid @RequestBody LabelTemplateRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                labelTemplateService.update(id, request), "Label template updated"));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'MANAGER', 'SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Long id) {
        labelTemplateService.delete(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Label template deleted"));
    }
}
