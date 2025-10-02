package com.shopmanagement.repository;

import com.shopmanagement.entity.User;
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
public interface UserRepository extends JpaRepository<User, Long> {
    
    // Basic finders
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);
    Optional<User> findByMobileNumber(String mobileNumber);
    Optional<User> findByEmailOrMobileNumber(String email, String mobileNumber);
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);
    boolean existsByMobileNumber(String mobileNumber);
    
    // Find by role
    Page<User> findByRole(User.UserRole role, Pageable pageable);
    List<User> findByRole(User.UserRole role);
    
    // Find by status
    Page<User> findByStatus(User.UserStatus status, Pageable pageable);
    List<User> findByStatus(User.UserStatus status);
    
    // Find active users
    Page<User> findByIsActiveTrue(Pageable pageable);
    List<User> findByIsActiveTrue();
    
    // Find by department
    Page<User> findByDepartment(String department, Pageable pageable);
    List<User> findByDepartment(String department);
    
    // Find by designation
    Page<User> findByDesignation(String designation, Pageable pageable);
    
    // Find subordinates
    Page<User> findByReportsTo(Long reportsTo, Pageable pageable);
    List<User> findByReportsTo(Long reportsTo);
    
    // Search users
    @Query("SELECT u FROM User u WHERE " +
           "LOWER(u.username) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(u.email) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(u.firstName) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(u.lastName) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(u.department) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(u.designation) LIKE LOWER(CONCAT('%', :searchTerm, '%'))")
    Page<User> searchUsers(@Param("searchTerm") String searchTerm, Pageable pageable);
    
    // Find users with failed login attempts
    @Query("SELECT u FROM User u WHERE u.failedLoginAttempts >= :threshold")
    List<User> findUsersWithFailedLogins(@Param("threshold") int threshold);
    
    // Find locked users
    @Query("SELECT u FROM User u WHERE u.accountLockedUntil IS NOT NULL AND u.accountLockedUntil > :currentTime")
    List<User> findLockedUsers(@Param("currentTime") LocalDateTime currentTime);
    
    // Find users requiring password change
    List<User> findByPasswordChangeRequiredTrue();
    
    // Find users with temporary passwords
    List<User> findByIsTemporaryPasswordTrue();
    
    // Find users by email verification status
    Page<User> findByEmailVerified(Boolean emailVerified, Pageable pageable);
    
    // Find users by mobile verification status
    Page<User> findByMobileVerified(Boolean mobileVerified, Pageable pageable);
    
    // Find users with 2FA enabled
    Page<User> findByTwoFactorEnabled(Boolean twoFactorEnabled, Pageable pageable);
    
    // Analytics queries
    @Query("SELECT COUNT(u) FROM User u WHERE u.role = :role")
    Long countUsersByRole(@Param("role") User.UserRole role);
    
    @Query("SELECT COUNT(u) FROM User u WHERE u.status = :status")
    Long countUsersByStatus(@Param("status") User.UserStatus status);
    
    @Query("SELECT COUNT(u) FROM User u WHERE u.department = :department")
    Long countUsersByDepartment(@Param("department") String department);
    
    @Query("SELECT u.department, COUNT(u) FROM User u WHERE u.department IS NOT NULL GROUP BY u.department")
    List<Object[]> getUserCountByDepartment();
    
    @Query("SELECT u.role, COUNT(u) FROM User u GROUP BY u.role")
    List<Object[]> getUserCountByRole();
    
    @Query("SELECT u.status, COUNT(u) FROM User u GROUP BY u.status")
    List<Object[]> getUserCountByStatus();
    
    // Users created in date range
    @Query("SELECT u FROM User u WHERE u.createdAt BETWEEN :startDate AND :endDate")
    Page<User> findUsersCreatedBetween(@Param("startDate") LocalDateTime startDate,
                                      @Param("endDate") LocalDateTime endDate,
                                      Pageable pageable);
    
    // Users who haven't logged in for a period
    @Query("SELECT u FROM User u WHERE u.lastLogin IS NULL OR u.lastLogin < :cutoffDate")
    List<User> findInactiveUsers(@Param("cutoffDate") LocalDateTime cutoffDate);
    
    // Find managers (users who have direct reports)
    @Query("SELECT DISTINCT u FROM User u WHERE u.id IN (SELECT r.reportsTo FROM User r WHERE r.reportsTo IS NOT NULL)")
    List<User> findManagers();

    // Delivery Partner Status Tracking Methods
    List<User> findByRoleAndIsOnline(User.UserRole role, Boolean isOnline);
    List<User> findByRoleAndIsAvailable(User.UserRole role, Boolean isAvailable);
    List<User> findByRoleAndIsOnlineAndIsAvailable(User.UserRole role, Boolean isOnline, Boolean isAvailable);
    List<User> findByRoleAndIsActiveAndIsAvailableAndIsOnline(User.UserRole role, Boolean isActive, Boolean isAvailable, Boolean isOnline);
    List<User> findByRoleAndRideStatus(User.UserRole role, User.RideStatus rideStatus);

    @Query("SELECT u FROM User u WHERE u.role = :role AND u.isOnline = true AND u.currentLatitude IS NOT NULL AND u.currentLongitude IS NOT NULL")
    List<User> findOnlinePartnersWithLocation(@Param("role") User.UserRole role);

    @Query("SELECT u FROM User u WHERE u.role = :role AND u.lastActivity < :cutoffTime")
    List<User> findInactivePartners(@Param("role") User.UserRole role, @Param("cutoffTime") LocalDateTime cutoffTime);
}