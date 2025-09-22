package com.shopmanagement.repository;

import com.shopmanagement.entity.CustomerAddress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CustomerAddressRepository extends JpaRepository<CustomerAddress, Long> {
    
    // Find addresses by customer
    List<CustomerAddress> findByCustomerId(Long customerId);

    List<CustomerAddress> findByCustomerIdAndIsActive(Long customerId, Boolean isActive);

    // Find address by ID and customer ID for security
    Optional<CustomerAddress> findByIdAndCustomerId(Long id, Long customerId);
    
    // Find default address
    Optional<CustomerAddress> findByCustomerIdAndIsDefault(Long customerId, Boolean isDefault);
    
    @Query("SELECT ca FROM CustomerAddress ca WHERE ca.customer.id = :customerId AND ca.isDefault = true AND ca.isActive = true")
    Optional<CustomerAddress> findDefaultActiveAddressByCustomerId(@Param("customerId") Long customerId);
    
    // Find by address type
    List<CustomerAddress> findByCustomerIdAndAddressType(Long customerId, String addressType);
    
    Optional<CustomerAddress> findByCustomerIdAndAddressTypeAndIsActive(Long customerId, String addressType, Boolean isActive);
    
    // Find by location
    List<CustomerAddress> findByCity(String city);
    
    List<CustomerAddress> findByState(String state);
    
    List<CustomerAddress> findByCityAndState(String city, String state);
    
    List<CustomerAddress> findByPostalCode(String postalCode);
    
    // Count addresses per customer
    @Query("SELECT COUNT(ca) FROM CustomerAddress ca WHERE ca.customer.id = :customerId AND ca.isActive = true")
    Long countActiveAddressesByCustomerId(@Param("customerId") Long customerId);
    
    // Search addresses by text
    @Query("SELECT ca FROM CustomerAddress ca WHERE ca.customer.id = :customerId AND " +
           "(LOWER(ca.addressLine1) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(ca.addressLine2) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(ca.landmark) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(ca.city) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(ca.addressLabel) LIKE LOWER(CONCAT('%', :searchTerm, '%')))")
    List<CustomerAddress> searchCustomerAddresses(@Param("customerId") Long customerId, 
                                                 @Param("searchTerm") String searchTerm);
    
    // Location-based queries for delivery optimization
    @Query("SELECT ca FROM CustomerAddress ca WHERE " +
           "ca.latitude BETWEEN :minLat AND :maxLat AND " +
           "ca.longitude BETWEEN :minLng AND :maxLng AND " +
           "ca.isActive = true")
    List<CustomerAddress> findAddressesInBounds(@Param("minLat") Double minLatitude,
                                               @Param("maxLat") Double maxLatitude,
                                               @Param("minLng") Double minLongitude,
                                               @Param("maxLng") Double maxLongitude);
    
    // Statistics
    @Query("SELECT ca.city, COUNT(ca) FROM CustomerAddress ca WHERE ca.isActive = true GROUP BY ca.city ORDER BY COUNT(ca) DESC")
    List<Object[]> getCustomerCountByCity();
    
    @Query("SELECT ca.state, COUNT(ca) FROM CustomerAddress ca WHERE ca.isActive = true GROUP BY ca.state ORDER BY COUNT(ca) DESC")
    List<Object[]> getCustomerCountByState();
    
    @Query("SELECT ca.postalCode, COUNT(ca) FROM CustomerAddress ca WHERE ca.isActive = true GROUP BY ca.postalCode ORDER BY COUNT(ca) DESC")
    List<Object[]> getCustomerCountByPostalCode();
}