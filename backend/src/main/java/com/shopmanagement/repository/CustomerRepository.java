package com.shopmanagement.repository;

import com.shopmanagement.entity.Customer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface CustomerRepository extends JpaRepository<Customer, Long> {
    
    // Basic Finders
    Optional<Customer> findByEmail(String email);
    
    Optional<Customer> findByMobileNumber(String mobileNumber);
    
    Optional<Customer> findByReferralCode(String referralCode);
    
    boolean existsByEmail(String email);
    
    boolean existsByMobileNumber(String mobileNumber);
    
    boolean existsByReferralCode(String referralCode);
    
    // Status-based queries
    List<Customer> findByStatus(Customer.CustomerStatus status);
    
    Page<Customer> findByStatus(Customer.CustomerStatus status, Pageable pageable);
    
    List<Customer> findByIsActive(Boolean isActive);
    
    Page<Customer> findByIsActive(Boolean isActive, Pageable pageable);
    
    List<Customer> findByIsVerified(Boolean isVerified);
    
    Page<Customer> findByIsVerified(Boolean isVerified, Pageable pageable);
    
    // Search queries
    @Query("SELECT c FROM Customer c WHERE " +
           "LOWER(c.firstName) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(c.lastName) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(c.email) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "c.mobileNumber LIKE CONCAT('%', :searchTerm, '%')")
    Page<Customer> searchCustomers(@Param("searchTerm") String searchTerm, Pageable pageable);
    
    @Query("SELECT c FROM Customer c WHERE " +
           "(LOWER(c.firstName) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(c.lastName) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(c.email) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "c.mobileNumber LIKE CONCAT('%', :searchTerm, '%')) AND " +
           "c.status = :status")
    Page<Customer> searchCustomersByStatus(@Param("searchTerm") String searchTerm, 
                                          @Param("status") Customer.CustomerStatus status, 
                                          Pageable pageable);
    
    // Location-based queries
    List<Customer> findByCity(String city);
    
    List<Customer> findByState(String state);
    
    List<Customer> findByCityAndState(String city, String state);
    
    // Date-based queries
    List<Customer> findByCreatedAtBetween(LocalDateTime startDate, LocalDateTime endDate);
    
    List<Customer> findByLastOrderDateBetween(LocalDateTime startDate, LocalDateTime endDate);
    
    List<Customer> findByLastLoginDateBetween(LocalDateTime startDate, LocalDateTime endDate);
    
    // Business queries
    @Query("SELECT c FROM Customer c WHERE c.totalOrders > :minOrders ORDER BY c.totalOrders DESC")
    List<Customer> findTopCustomersByOrders(@Param("minOrders") Integer minOrders);
    
    @Query("SELECT c FROM Customer c WHERE c.totalSpent > :minSpent ORDER BY c.totalSpent DESC")
    List<Customer> findTopCustomersBySpending(@Param("minSpent") Double minSpent);
    
    @Query("SELECT c FROM Customer c WHERE c.lastOrderDate < :date AND c.isActive = true")
    List<Customer> findInactiveCustomers(@Param("date") LocalDateTime date);
    
    @Query("SELECT c FROM Customer c WHERE c.createdAt >= :date")
    List<Customer> findNewCustomers(@Param("date") LocalDateTime date);
    
    // Notification preferences
    List<Customer> findByEmailNotifications(Boolean emailNotifications);
    
    List<Customer> findBySmsNotifications(Boolean smsNotifications);
    
    List<Customer> findByPromotionalEmails(Boolean promotionalEmails);
    
    @Query("SELECT c FROM Customer c WHERE c.emailNotifications = true AND c.isActive = true")
    List<Customer> findCustomersForEmailNotifications();
    
    @Query("SELECT c FROM Customer c WHERE c.smsNotifications = true AND c.isActive = true")
    List<Customer> findCustomersForSmsNotifications();
    
    @Query("SELECT c FROM Customer c WHERE c.promotionalEmails = true AND c.isActive = true")
    List<Customer> findCustomersForPromotionalEmails();
    
    // Verification status
    @Query("SELECT c FROM Customer c WHERE c.emailVerifiedAt IS NULL AND c.isActive = true")
    List<Customer> findCustomersWithUnverifiedEmail();
    
    @Query("SELECT c FROM Customer c WHERE c.mobileVerifiedAt IS NULL AND c.isActive = true")
    List<Customer> findCustomersWithUnverifiedMobile();
    
    @Query("SELECT c FROM Customer c WHERE (c.emailVerifiedAt IS NULL OR c.mobileVerifiedAt IS NULL) AND c.isActive = true")
    List<Customer> findPartiallyVerifiedCustomers();
    
    // Referral queries
    List<Customer> findByReferredBy(String referralCode);
    
    @Query("SELECT COUNT(c) FROM Customer c WHERE c.referredBy = :referralCode")
    Long countByReferredBy(@Param("referralCode") String referralCode);
    
    // Statistics queries
    @Query("SELECT COUNT(c) FROM Customer c WHERE c.status = :status")
    Long countByStatus(@Param("status") Customer.CustomerStatus status);
    
    @Query("SELECT COUNT(c) FROM Customer c WHERE c.createdAt >= :startDate AND c.createdAt <= :endDate")
    Long countCustomersInDateRange(@Param("startDate") LocalDateTime startDate, 
                                  @Param("endDate") LocalDateTime endDate);
                                  
    @Query("SELECT COUNT(c) FROM Customer c WHERE c.createdAt >= :startDate AND c.createdAt <= :endDate")
    Long countCustomersCreatedBetween(@Param("startDate") LocalDateTime startDate, 
                                     @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT SUM(c.totalSpent) FROM Customer c WHERE c.isActive = true")
    Double getTotalCustomerSpending();
    
    @Query("SELECT AVG(c.totalOrders) FROM Customer c WHERE c.isActive = true")
    Double getAverageOrdersPerCustomer();
    
    @Query("SELECT AVG(c.totalSpent) FROM Customer c WHERE c.isActive = true")
    Double getAverageSpendingPerCustomer();
    
    // Gender-based queries
    List<Customer> findByGender(Customer.Gender gender);
    
    @Query("SELECT COUNT(c) FROM Customer c WHERE c.gender = :gender")
    Long countByGender(@Param("gender") Customer.Gender gender);
    
    // Age-based queries (if needed)
    @Query("SELECT c FROM Customer c WHERE YEAR(CURRENT_DATE) - YEAR(c.dateOfBirth) BETWEEN :minAge AND :maxAge")
    List<Customer> findByAgeRange(@Param("minAge") Integer minAge, @Param("maxAge") Integer maxAge);
}