package com.shopmanagement.repository;

import com.shopmanagement.entity.PostPayment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PostPaymentRepository extends JpaRepository<PostPayment, Long> {

    Optional<PostPayment> findByRazorpayOrderId(String razorpayOrderId);

    List<PostPayment> findAllByRazorpayOrderId(String razorpayOrderId);

    List<PostPayment> findByUserIdAndStatusAndConsumedFalse(Long userId, PostPayment.PaymentStatus status);

    Page<PostPayment> findAllByOrderByCreatedAtDesc(Pageable pageable);

    long countByUserIdAndStatus(Long userId, PostPayment.PaymentStatus status);

    Page<PostPayment> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    long countByStatus(PostPayment.PaymentStatus status);

    @Query("SELECT COALESCE(SUM(p.amount), 0) FROM PostPayment p WHERE p.status = 'PAID'")
    long sumAmountByStatusPaid();

    @Query("SELECT COALESCE(SUM(p.amount), 0) FROM PostPayment p WHERE p.status = 'PAID' AND p.consumed = true")
    long sumAmountByStatusPaidAndConsumed();

    @Query("SELECT COALESCE(SUM(p.totalAmount), 0) FROM PostPayment p WHERE p.status = 'PAID'")
    long sumTotalAmountByStatusPaid();

    @Query("SELECT COALESCE(SUM(p.processingFee), 0) FROM PostPayment p WHERE p.status = 'PAID'")
    long sumProcessingFeeByStatusPaid();

    @Query("SELECT p.postType, COUNT(p), COALESCE(SUM(p.totalAmount), 0) FROM PostPayment p WHERE p.status = 'PAID' GROUP BY p.postType")
    List<Object[]> getStatsByPostType();
}
