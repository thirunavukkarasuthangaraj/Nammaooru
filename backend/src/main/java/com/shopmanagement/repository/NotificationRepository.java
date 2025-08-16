package com.shopmanagement.repository;

import com.shopmanagement.entity.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {
    
    // Find by recipient
    Page<Notification> findByRecipientIdAndIsActiveTrue(Long recipientId, Pageable pageable);
    List<Notification> findByRecipientIdAndIsActiveTrue(Long recipientId);
    
    // Find by recipient type
    Page<Notification> findByRecipientTypeAndIsActiveTrue(Notification.RecipientType recipientType, Pageable pageable);
    
    // Find by status
    Page<Notification> findByRecipientIdAndStatusAndIsActiveTrue(Long recipientId, Notification.NotificationStatus status, Pageable pageable);
    List<Notification> findByRecipientIdAndStatusAndIsActiveTrue(Long recipientId, Notification.NotificationStatus status);
    
    // Find unread notifications  
    List<Notification> findByRecipientIdAndStatus(Long recipientId, Notification.NotificationStatus status);
    
    // Find by type
    Page<Notification> findByRecipientIdAndTypeAndIsActiveTrue(Long recipientId, Notification.NotificationType type, Pageable pageable);
    
    // Find by priority
    Page<Notification> findByRecipientIdAndPriorityAndIsActiveTrue(Long recipientId, Notification.NotificationPriority priority, Pageable pageable);
    
    // Find by category
    Page<Notification> findByRecipientIdAndCategoryAndIsActiveTrue(Long recipientId, String category, Pageable pageable);
    
    // Find by date range
    @Query("SELECT n FROM Notification n WHERE n.recipientId = :recipientId AND n.isActive = true AND n.createdAt BETWEEN :startDate AND :endDate")
    Page<Notification> findByRecipientIdAndDateRange(@Param("recipientId") Long recipientId,
                                                    @Param("startDate") LocalDateTime startDate,
                                                    @Param("endDate") LocalDateTime endDate,
                                                    Pageable pageable);
    
    // Search notifications
    @Query("SELECT n FROM Notification n WHERE n.recipientId = :recipientId AND n.isActive = true AND " +
           "(LOWER(n.title) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(n.message) LIKE LOWER(CONCAT('%', :searchTerm, '%')))")
    Page<Notification> searchNotifications(@Param("recipientId") Long recipientId,
                                          @Param("searchTerm") String searchTerm,
                                          Pageable pageable);
    
    // Count unread notifications
    @Query("SELECT COUNT(n) FROM Notification n WHERE n.recipientId = :recipientId AND n.status = 'UNREAD' AND n.isActive = true")
    Long countUnreadNotifications(@Param("recipientId") Long recipientId);
    
    // Count notifications by type
    @Query("SELECT COUNT(n) FROM Notification n WHERE n.recipientId = :recipientId AND n.type = :type AND n.isActive = true")
    Long countNotificationsByType(@Param("recipientId") Long recipientId, @Param("type") Notification.NotificationType type);
    
    // Count notifications by priority
    @Query("SELECT COUNT(n) FROM Notification n WHERE n.recipientId = :recipientId AND n.priority = :priority AND n.isActive = true")
    Long countNotificationsByPriority(@Param("recipientId") Long recipientId, @Param("priority") Notification.NotificationPriority priority);
    
    // Find scheduled notifications
    @Query("SELECT n FROM Notification n WHERE n.scheduledAt IS NOT NULL AND n.scheduledAt <= :currentTime AND n.sentAt IS NULL")
    List<Notification> findScheduledNotifications(@Param("currentTime") LocalDateTime currentTime);
    
    // Find expired notifications
    @Query("SELECT n FROM Notification n WHERE n.expiresAt IS NOT NULL AND n.expiresAt < :currentTime")
    List<Notification> findExpiredNotifications(@Param("currentTime") LocalDateTime currentTime);
    
    // Find notifications to be deleted
    @Query("SELECT n FROM Notification n WHERE n.isPersistent = false OR (n.expiresAt IS NOT NULL AND n.expiresAt < :cutoffDate)")
    List<Notification> findNotificationsToDelete(@Param("cutoffDate") LocalDateTime cutoffDate);
    
    // Admin queries - find all notifications
    @Query("SELECT n FROM Notification n WHERE n.isActive = true")
    Page<Notification> findAllActiveNotifications(Pageable pageable);
    
    // Find notifications by sender
    Page<Notification> findBySenderIdAndIsActiveTrue(Long senderId, Pageable pageable);
    
    // Find broadcast notifications
    @Query("SELECT n FROM Notification n WHERE n.recipientType IN ('ALL_USERS', 'ALL_CUSTOMERS', 'ALL_SHOP_OWNERS') AND n.isActive = true")
    Page<Notification> findBroadcastNotifications(Pageable pageable);
    
    // Find notifications by reference
    List<Notification> findByReferenceIdAndReferenceType(Long referenceId, String referenceType);
    
    // Mark notifications as read
    @Modifying
    @Query("UPDATE Notification n SET n.status = 'READ', n.readAt = :readAt WHERE n.recipientId = :recipientId AND n.status = 'UNREAD'")
    void markAllAsRead(@Param("recipientId") Long recipientId, @Param("readAt") LocalDateTime readAt);
    
    @Modifying
    @Query("UPDATE Notification n SET n.status = 'READ', n.readAt = :readAt WHERE n.id IN :notificationIds")
    void markAsRead(@Param("notificationIds") List<Long> notificationIds, @Param("readAt") LocalDateTime readAt);
    
    // Archive notifications
    @Modifying
    @Query("UPDATE Notification n SET n.status = 'ARCHIVED' WHERE n.recipientId = :recipientId AND n.status = 'READ'")
    void archiveReadNotifications(@Param("recipientId") Long recipientId);
    
    // Soft delete notifications
    @Modifying
    @Query("UPDATE Notification n SET n.isActive = false WHERE n.id IN :notificationIds")
    void softDeleteNotifications(@Param("notificationIds") List<Long> notificationIds);
    
    // Hard delete old notifications
    @Modifying
    @Query("DELETE FROM Notification n WHERE n.createdAt < :cutoffDate AND n.isPersistent = false")
    void deleteOldNotifications(@Param("cutoffDate") LocalDateTime cutoffDate);
    
    // Analytics queries
    @Query("SELECT n.type, COUNT(n) FROM Notification n WHERE n.createdAt BETWEEN :startDate AND :endDate GROUP BY n.type")
    List<Object[]> getNotificationCountByType(@Param("startDate") LocalDateTime startDate, @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT n.priority, COUNT(n) FROM Notification n WHERE n.createdAt BETWEEN :startDate AND :endDate GROUP BY n.priority")
    List<Object[]> getNotificationCountByPriority(@Param("startDate") LocalDateTime startDate, @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT n.recipientType, COUNT(n) FROM Notification n WHERE n.createdAt BETWEEN :startDate AND :endDate GROUP BY n.recipientType")
    List<Object[]> getNotificationCountByRecipientType(@Param("startDate") LocalDateTime startDate, @Param("endDate") LocalDateTime endDate);
    
    // Recent notifications
    @Query("SELECT n FROM Notification n WHERE n.recipientId = :recipientId AND n.isActive = true ORDER BY n.createdAt DESC")
    List<Notification> findRecentNotifications(@Param("recipientId") Long recipientId, Pageable pageable);
    
    // High priority unread notifications
    @Query("SELECT n FROM Notification n WHERE n.recipientId = :recipientId AND n.status = 'UNREAD' AND n.priority IN ('HIGH', 'URGENT') AND n.isActive = true ORDER BY n.priority DESC, n.createdAt DESC")
    List<Notification> findHighPriorityUnreadNotifications(@Param("recipientId") Long recipientId);
    
    // Find distinct categories
    @Query("SELECT DISTINCT n.category FROM Notification n WHERE n.category IS NOT NULL ORDER BY n.category")
    List<String> findDistinctCategories();
    
    // Find distinct tags
    @Query("SELECT DISTINCT n.tags FROM Notification n WHERE n.tags IS NOT NULL")
    List<String> findDistinctTags();
}