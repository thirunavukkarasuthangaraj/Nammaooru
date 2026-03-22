package com.shopmanagement.userservice.repository;

import com.shopmanagement.userservice.entity.User;
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

    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);
    Optional<User> findByMobileNumber(String mobileNumber);
    Optional<User> findByEmailOrMobileNumber(String email, String mobileNumber);
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);
    boolean existsByMobileNumber(String mobileNumber);

    Page<User> findByRole(User.UserRole role, Pageable pageable);
    List<User> findByRole(User.UserRole role);

    Page<User> findByStatus(User.UserStatus status, Pageable pageable);

    Page<User> findByDepartment(String department, Pageable pageable);

    List<User> findByReportsTo(Long reportsTo);

    @Query("SELECT u FROM User u WHERE " +
           "LOWER(u.username) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(u.email) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(u.firstName) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(u.lastName) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(u.department) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(u.designation) LIKE LOWER(CONCAT('%', :searchTerm, '%'))")
    Page<User> searchUsers(@Param("searchTerm") String searchTerm, Pageable pageable);

    @Query("SELECT u.role, COUNT(u) FROM User u GROUP BY u.role")
    List<Object[]> getUserCountByRole();

    // Delivery Partner queries
    List<User> findByRoleAndIsOnline(User.UserRole role, Boolean isOnline);
    List<User> findByRoleAndIsAvailable(User.UserRole role, Boolean isAvailable);
    List<User> findByRoleAndRideStatus(User.UserRole role, User.RideStatus rideStatus);

    @Query("SELECT u FROM User u WHERE u.role = :role AND u.isOnline = true AND u.currentLatitude IS NOT NULL AND u.currentLongitude IS NOT NULL")
    List<User> findOnlinePartnersWithLocation(@Param("role") User.UserRole role);

    @Query("SELECT u FROM User u WHERE u.role = :role AND u.lastActivity < :cutoffTime")
    List<User> findInactivePartners(@Param("role") User.UserRole role, @Param("cutoffTime") LocalDateTime cutoffTime);

    @Query(value = "SELECT * FROM users u WHERE u.role = 'DELIVERY_PARTNER' " +
           "AND u.is_active = true AND u.is_available = true AND u.is_online = true " +
           "AND u.current_latitude IS NOT NULL AND u.current_longitude IS NOT NULL " +
           "AND (6371 * acos(cos(radians(:lat)) * cos(radians(u.current_latitude)) * cos(radians(u.current_longitude) - radians(:lng)) + sin(radians(:lat)) * sin(radians(u.current_latitude)))) < :radiusKm " +
           "ORDER BY (6371 * acos(cos(radians(:lat)) * cos(radians(u.current_latitude)) * cos(radians(u.current_longitude) - radians(:lng)) + sin(radians(:lat)) * sin(radians(u.current_latitude)))) ASC",
           nativeQuery = true)
    List<User> findNearbyAvailableDrivers(@Param("lat") double latitude, @Param("lng") double longitude, @Param("radiusKm") double radiusKm);

    List<User> findByRoleAndHealthTipNotificationsEnabledTrue(User.UserRole role);
}
