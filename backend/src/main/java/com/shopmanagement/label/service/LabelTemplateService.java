package com.shopmanagement.label.service;

import com.shopmanagement.label.dto.LabelTemplateRequest;
import com.shopmanagement.label.dto.LabelTemplateResponse;
import com.shopmanagement.label.entity.LabelTemplate;
import com.shopmanagement.label.repository.LabelTemplateRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class LabelTemplateService {

    private final LabelTemplateRepository labelTemplateRepository;

    @Transactional(readOnly = true)
    public List<LabelTemplateResponse> getAll() {
        return labelTemplateRepository.findAllByOrderByUpdatedAtDesc().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public LabelTemplateResponse getById(Long id) {
        LabelTemplate template = labelTemplateRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Label template not found: " + id));
        return toResponse(template);
    }

    /** Returns the common/default template, or null if none has been saved yet. */
    @Transactional(readOnly = true)
    public LabelTemplateResponse getDefault() {
        return labelTemplateRepository.findFirstByIsDefaultTrueOrderByUpdatedAtDesc()
                .map(this::toResponse)
                .orElse(null);
    }

    public LabelTemplateResponse create(LabelTemplateRequest request) {
        String user = currentUser();
        LabelTemplate template = LabelTemplate.builder()
                .name(request.getName())
                .shopId(request.getShopId())
                .labelWidthMm(request.getLabelWidthMm())
                .labelHeightMm(request.getLabelHeightMm())
                .isDefault(request.getIsDefault() != null ? request.getIsDefault() : Boolean.TRUE)
                .design(request.getDesign())
                .createdBy(user)
                .updatedBy(user)
                .build();
        template = labelTemplateRepository.save(template);
        log.info("Created label template id={} by {}", template.getId(), user);
        return toResponse(template);
    }

    public LabelTemplateResponse update(Long id, LabelTemplateRequest request) {
        LabelTemplate template = labelTemplateRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Label template not found: " + id));
        template.setName(request.getName());
        template.setShopId(request.getShopId());
        template.setLabelWidthMm(request.getLabelWidthMm());
        template.setLabelHeightMm(request.getLabelHeightMm());
        if (request.getIsDefault() != null) {
            template.setIsDefault(request.getIsDefault());
        }
        template.setDesign(request.getDesign());
        template.setUpdatedBy(currentUser());
        template = labelTemplateRepository.save(template);
        log.info("Updated label template id={}", id);
        return toResponse(template);
    }

    /**
     * Upsert for the single "common" template: updates the existing default if one
     * exists, otherwise creates it. This backs the designer's single Save button.
     */
    public LabelTemplateResponse saveDefault(LabelTemplateRequest request) {
        request.setIsDefault(Boolean.TRUE);
        return labelTemplateRepository.findFirstByIsDefaultTrueOrderByUpdatedAtDesc()
                .map(existing -> update(existing.getId(), request))
                .orElseGet(() -> create(request));
    }

    public void delete(Long id) {
        if (!labelTemplateRepository.existsById(id)) {
            throw new IllegalArgumentException("Label template not found: " + id);
        }
        labelTemplateRepository.deleteById(id);
        log.info("Deleted label template id={}", id);
    }

    private String currentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth != null ? auth.getName() : "system";
    }

    private LabelTemplateResponse toResponse(LabelTemplate t) {
        return LabelTemplateResponse.builder()
                .id(t.getId())
                .name(t.getName())
                .shopId(t.getShopId())
                .labelWidthMm(t.getLabelWidthMm())
                .labelHeightMm(t.getLabelHeightMm())
                .isDefault(t.getIsDefault())
                .design(t.getDesign())
                .createdBy(t.getCreatedBy())
                .updatedBy(t.getUpdatedBy())
                .createdAt(t.getCreatedAt())
                .updatedAt(t.getUpdatedAt())
                .build();
    }
}
