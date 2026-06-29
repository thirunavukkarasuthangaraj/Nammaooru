package com.shopmanagement.label.repository;

import com.shopmanagement.label.entity.LabelTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface LabelTemplateRepository extends JpaRepository<LabelTemplate, Long> {

    /** Most-recently-updated default template (the "common" template). */
    Optional<LabelTemplate> findFirstByIsDefaultTrueOrderByUpdatedAtDesc();

    List<LabelTemplate> findAllByOrderByUpdatedAtDesc();
}
