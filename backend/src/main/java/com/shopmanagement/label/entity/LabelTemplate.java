package com.shopmanagement.label.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

/**
 * A reusable barcode-label template design. Stores the physical label size and a
 * JSON description of which product fields are printed and how they are styled.
 * One template per shop (or a global template when {@code shopId} is null) is
 * flagged as the default / "common" template used by the product Print Label action.
 */
@Entity
@Table(name = "label_templates")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
public class LabelTemplate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @NotBlank
    @Size(max = 150)
    @Column(name = "name", nullable = false, length = 150)
    private String name;

    /** Owning shop; null means a global template shared across shops. */
    @Column(name = "shop_id")
    private Long shopId;

    @NotNull
    @Column(name = "label_width_mm", nullable = false)
    @Builder.Default
    private Double labelWidthMm = 50.0;

    @NotNull
    @Column(name = "label_height_mm", nullable = false)
    @Builder.Default
    private Double labelHeightMm = 20.0;

    /** Marks the single "common" template used by default for printing. */
    @Column(name = "is_default", nullable = false)
    @Builder.Default
    private Boolean isDefault = true;

    /**
     * JSON design payload (field toggles, font sizes, barcode type, etc.).
     * Kept opaque to the backend — the Angular designer owns its shape.
     */
    @Column(name = "design", columnDefinition = "TEXT")
    private String design;

    @Column(name = "created_by")
    private String createdBy;

    @Column(name = "updated_by")
    private String updatedBy;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
