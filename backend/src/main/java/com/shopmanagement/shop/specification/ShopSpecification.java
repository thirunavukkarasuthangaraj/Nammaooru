package com.shopmanagement.shop.specification;

import com.shopmanagement.shop.entity.Shop;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

public class ShopSpecification {

    public static Specification<Shop> withFilters(
            String name,
            String city,
            String state,
            String businessType,
            String status,
            Boolean isActive,
            Boolean isVerified,
            Boolean isFeatured,
            BigDecimal minRating,
            BigDecimal maxRating,
            String searchTerm
    ) {
        return (root, query, criteriaBuilder) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (name != null && !name.isEmpty()) {
                predicates.add(criteriaBuilder.like(
                    criteriaBuilder.lower(root.get("name")), 
                    "%" + name.toLowerCase() + "%"
                ));
            }

            if (city != null && !city.isEmpty()) {
                predicates.add(criteriaBuilder.like(
                    criteriaBuilder.lower(root.get("city")), 
                    "%" + city.toLowerCase() + "%"
                ));
            }

            if (state != null && !state.isEmpty()) {
                predicates.add(criteriaBuilder.like(
                    criteriaBuilder.lower(root.get("state")), 
                    "%" + state.toLowerCase() + "%"
                ));
            }

            if (businessType != null && !businessType.isEmpty()) {
                predicates.add(criteriaBuilder.equal(
                    root.get("businessType"), 
                    Shop.BusinessType.valueOf(businessType)
                ));
            }

            if (status != null && !status.isEmpty()) {
                predicates.add(criteriaBuilder.equal(
                    root.get("status"), 
                    Shop.ShopStatus.valueOf(status)
                ));
            }

            if (isActive != null) {
                predicates.add(criteriaBuilder.equal(root.get("isActive"), isActive));
            }

            if (isVerified != null) {
                predicates.add(criteriaBuilder.equal(root.get("isVerified"), isVerified));
            }

            if (isFeatured != null) {
                predicates.add(criteriaBuilder.equal(root.get("isFeatured"), isFeatured));
            }

            if (minRating != null) {
                predicates.add(criteriaBuilder.greaterThanOrEqualTo(root.get("rating"), minRating));
            }

            if (maxRating != null) {
                predicates.add(criteriaBuilder.lessThanOrEqualTo(root.get("rating"), maxRating));
            }

            if (searchTerm != null && !searchTerm.isEmpty()) {
                String searchPattern = "%" + searchTerm.toLowerCase() + "%";
                Predicate searchPredicate = criteriaBuilder.or(
                    criteriaBuilder.like(criteriaBuilder.lower(root.get("name")), searchPattern),
                    criteriaBuilder.like(criteriaBuilder.lower(root.get("description")), searchPattern),
                    criteriaBuilder.like(criteriaBuilder.lower(root.get("ownerName")), searchPattern),
                    criteriaBuilder.like(criteriaBuilder.lower(root.get("businessName")), searchPattern),
                    criteriaBuilder.like(criteriaBuilder.lower(root.get("city")), searchPattern)
                );
                predicates.add(searchPredicate);
            }

            return criteriaBuilder.and(predicates.toArray(new Predicate[0]));
        };
    }

    public static Specification<Shop> isActive() {
        return (root, query, criteriaBuilder) -> 
            criteriaBuilder.equal(root.get("isActive"), true);
    }

    public static Specification<Shop> isApproved() {
        return (root, query, criteriaBuilder) -> 
            criteriaBuilder.equal(root.get("status"), Shop.ShopStatus.APPROVED);
    }

    public static Specification<Shop> isFeatured() {
        return (root, query, criteriaBuilder) -> 
            criteriaBuilder.equal(root.get("isFeatured"), true);
    }

    public static Specification<Shop> hasBusinessType(Shop.BusinessType businessType) {
        return (root, query, criteriaBuilder) -> 
            criteriaBuilder.equal(root.get("businessType"), businessType);
    }

    public static Specification<Shop> inCity(String city) {
        return (root, query, criteriaBuilder) -> 
            criteriaBuilder.like(criteriaBuilder.lower(root.get("city")), "%" + city.toLowerCase() + "%");
    }

    public static Specification<Shop> withMinimumRating(BigDecimal minRating) {
        return (root, query, criteriaBuilder) -> 
            criteriaBuilder.greaterThanOrEqualTo(root.get("rating"), minRating);
    }
}