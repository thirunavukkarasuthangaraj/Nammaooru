package com.shopmanagement.repository;

import com.shopmanagement.entity.ContactView;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ContactViewRepository extends JpaRepository<ContactView, Long> {
    Page<ContactView> findAllByOrderByViewedAtDesc(Pageable pageable);
    List<ContactView> findByPostTypeAndPostIdOrderByViewedAtDesc(String postType, Long postId);
    long countByViewerUserId(Long userId);
}
