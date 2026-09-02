package com.shopmanagement.repository;

import com.shopmanagement.entity.OrderPayment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface OrderPaymentRepository extends JpaRepository<OrderPayment, Long> {

    Optional<OrderPayment> findByRazorpayOrderId(String razorpayOrderId);

    Optional<OrderPayment> findByOrder_Id(Long orderId);

    Page<OrderPayment> findAllByOrderByCreatedAtDesc(Pageable pageable);

    Page<OrderPayment> findByStatusOrderByCreatedAtDesc(OrderPayment.OrderPaymentStatus status, Pageable pageable);
}
