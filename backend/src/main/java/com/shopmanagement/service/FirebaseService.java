package com.shopmanagement.service;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.*;
import com.shopmanagement.entity.UserFcmToken;
import com.shopmanagement.repository.UserFcmTokenRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class FirebaseService {

    private static final Logger logger = LoggerFactory.getLogger(FirebaseService.class);

    @Autowired
    private UserFcmTokenRepository fcmTokenRepository;

    /**
     * Send notification to a specific user (all their devices)
     */
    public void sendNotificationToUser(Long userId, String title, String body, Map<String, String> data, String notificationType) {
        try {
            List<UserFcmToken> userTokens = fcmTokenRepository.findActiveTokensByUserId(userId);

            if (userTokens.isEmpty()) {
                logger.info("No active FCM tokens found for user: {}", userId);
                return;
            }

            List<String> tokens = userTokens.stream()
                    .map(UserFcmToken::getFcmToken)
                    .collect(Collectors.toList());

            sendMulticastNotification(tokens, title, body, data, notificationType);

        } catch (Exception e) {
            logger.error("Error sending notification to user {}: {}", userId, e.getMessage());
        }
    }

    /**
     * Send notification to multiple users
     */
    public void sendNotificationToUsers(List<Long> userIds, String title, String body, Map<String, String> data, String notificationType) {
        try {
            List<UserFcmToken> userTokens = fcmTokenRepository.findActiveTokensByUserIds(userIds);

            if (userTokens.isEmpty()) {
                logger.info("No active FCM tokens found for users: {}", userIds);
                return;
            }

            List<String> tokens = userTokens.stream()
                    .map(UserFcmToken::getFcmToken)
                    .collect(Collectors.toList());

            sendMulticastNotification(tokens, title, body, data, notificationType);

        } catch (Exception e) {
            logger.error("Error sending notification to users {}: {}", userIds, e.getMessage());
        }
    }

    /**
     * Send notification to a topic (all subscribers)
     */
    public void sendNotificationToTopic(String topic, String title, String body, Map<String, String> data, String notificationType) {
        try {
            // Build the notification
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build();

            // Build Android config
            AndroidConfig androidConfig = AndroidConfig.builder()
                    .setNotification(AndroidNotification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .setIcon("ic_notification")
                            .setColor("#4CAF50")
                            .setSound("default")
                            .build())
                    .setPriority(AndroidConfig.Priority.HIGH)
                    .build();

            // Build APNs config
            ApnsConfig apnsConfig = ApnsConfig.builder()
                    .setAps(Aps.builder()
                            .setAlert(ApsAlert.builder()
                                    .setTitle(title)
                                    .setBody(body)
                                    .build())
                            .setSound("default")
                            .setBadge(1)
                            .build())
                    .build();

            // Add notification type to data
            if (data != null) {
                data.put("notification_type", notificationType);
            } else {
                data = Map.of("notification_type", notificationType);
            }

            // Build the message
            Message message = Message.builder()
                    .setTopic(topic)
                    .setNotification(notification)
                    .setAndroidConfig(androidConfig)
                    .setApnsConfig(apnsConfig)
                    .putAllData(data)
                    .build();

            // Send the message
            String response = FirebaseMessaging.getInstance().send(message);
            logger.info("Successfully sent message to topic {}: {}", topic, response);

        } catch (Exception e) {
            logger.error("Error sending notification to topic {}: {}", topic, e.getMessage());
        }
    }

    /**
     * Send notification to multiple tokens (multicast)
     */
    private void sendMulticastNotification(List<String> tokens, String title, String body, Map<String, String> data, String notificationType) {
        try {
            if (tokens.isEmpty()) {
                logger.warn("No tokens provided for multicast notification");
                return;
            }

            // Build the notification
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build();

            // Build Android config
            AndroidConfig androidConfig = AndroidConfig.builder()
                    .setNotification(AndroidNotification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .setIcon("ic_notification")
                            .setColor("#4CAF50")
                            .setSound("default")
                            .build())
                    .setPriority(AndroidConfig.Priority.HIGH)
                    .build();

            // Build APNs config
            ApnsConfig apnsConfig = ApnsConfig.builder()
                    .setAps(Aps.builder()
                            .setAlert(ApsAlert.builder()
                                    .setTitle(title)
                                    .setBody(body)
                                    .build())
                            .setSound("default")
                            .setBadge(1)
                            .build())
                    .build();

            // Add notification type to data
            if (data != null) {
                data.put("notification_type", notificationType);
            } else {
                data = Map.of("notification_type", notificationType);
            }

            // Build multicast message
            MulticastMessage message = MulticastMessage.builder()
                    .addAllTokens(tokens)
                    .setNotification(notification)
                    .setAndroidConfig(androidConfig)
                    .setApnsConfig(apnsConfig)
                    .putAllData(data)
                    .build();

            // Send the message
            BatchResponse response = FirebaseMessaging.getInstance().sendMulticast(message);

            logger.info("Successfully sent {} messages, {} failed",
                    response.getSuccessCount(), response.getFailureCount());

            // Handle failed tokens
            if (response.getFailureCount() > 0) {
                handleFailedTokens(tokens, response.getResponses());
            }

        } catch (Exception e) {
            logger.error("Error sending multicast notification: {}", e.getMessage());
        }
    }

    /**
     * Handle failed tokens (deactivate invalid ones)
     */
    @Transactional
    private void handleFailedTokens(List<String> tokens, List<SendResponse> responses) {
        for (int i = 0; i < responses.size(); i++) {
            SendResponse response = responses.get(i);
            if (!response.isSuccessful()) {
                String token = tokens.get(i);
                FirebaseMessagingException exception = response.getException();

                if (exception != null) {
                    String errorCode = exception.getErrorCode().toString();

                    // Deactivate invalid tokens
                    if ("UNREGISTERED".equals(errorCode) ||
                        "INVALID_REGISTRATION".equals(errorCode) ||
                        "NOT_FOUND".equals(errorCode)) {

                        fcmTokenRepository.deactivateToken(token);
                        logger.info("Deactivated invalid FCM token: {}", token);
                    }
                }
            }
        }
    }

    /**
     * Store or update FCM token for user
     */
    @Transactional
    public void storeFcmToken(Long userId, String fcmToken, String deviceType, String deviceId) {
        try {
            // Check if token already exists for this user and device type
            var existingToken = fcmTokenRepository.findByUserIdAndDeviceType(userId, deviceType);

            if (existingToken.isPresent()) {
                // Update existing token
                UserFcmToken token = existingToken.get();
                token.setFcmToken(fcmToken);
                token.setDeviceId(deviceId);
                token.setIsActive(true);
                fcmTokenRepository.save(token);

                logger.info("Updated FCM token for user {} on {}", userId, deviceType);
            } else {
                // Create new token
                UserFcmToken newToken = new UserFcmToken(userId, fcmToken, deviceType);
                newToken.setDeviceId(deviceId);
                fcmTokenRepository.save(newToken);

                logger.info("Stored new FCM token for user {} on {}", userId, deviceType);
            }

        } catch (Exception e) {
            logger.error("Error storing FCM token for user {}: {}", userId, e.getMessage());
        }
    }

    /**
     * Subscribe user to topics based on their role
     */
    public void subscribeUserToTopics(Long userId, String userRole) {
        try {
            List<UserFcmToken> userTokens = fcmTokenRepository.findActiveTokensByUserId(userId);

            if (userTokens.isEmpty()) {
                logger.info("No active FCM tokens found for user: {}", userId);
                return;
            }

            List<String> tokens = userTokens.stream()
                    .map(UserFcmToken::getFcmToken)
                    .collect(Collectors.toList());

            // Subscribe to user-specific topic
            subscribeToTopic(tokens, "user_" + userId);

            // Subscribe to role-based topics
            switch (userRole.toLowerCase()) {
                case "customer":
                    subscribeToTopic(tokens, "customers");
                    subscribeToTopic(tokens, "promotions");
                    break;
                case "shop_owner":
                    subscribeToTopic(tokens, "shop_owners");
                    subscribeToTopic(tokens, "shop_updates");
                    break;
                case "delivery_partner":
                    subscribeToTopic(tokens, "delivery_partners");
                    subscribeToTopic(tokens, "delivery_updates");
                    break;
            }

        } catch (Exception e) {
            logger.error("Error subscribing user {} to topics: {}", userId, e.getMessage());
        }
    }

    /**
     * Subscribe tokens to a topic
     */
    private void subscribeToTopic(List<String> tokens, String topic) {
        try {
            TopicManagementResponse response = FirebaseMessaging.getInstance()
                    .subscribeToTopic(tokens, topic);

            logger.info("Successfully subscribed {} tokens to topic {}, {} failed",
                    response.getSuccessCount(), topic, response.getFailureCount());

        } catch (Exception e) {
            logger.error("Error subscribing to topic {}: {}", topic, e.getMessage());
        }
    }
}