package com.shopmanagement.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    private static final Logger logger = LoggerFactory.getLogger(FirebaseConfig.class);

    @PostConstruct
    public void initializeFirebase() {
        try {
            // Check if Firebase app is already initialized
            if (FirebaseApp.getApps().isEmpty()) {
                // Load service account key from resources
                ClassPathResource resource = new ClassPathResource("firebase-service-account.json");
                InputStream serviceAccount = resource.getInputStream();

                // Build Firebase options using the mobile app's project configuration
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .setProjectId("grocery-5ecc5")  // Same as mobile app
                        .build();

                // Initialize Firebase
                FirebaseApp.initializeApp(options);

                logger.info("✅ Firebase Admin SDK initialized successfully for project: grocery-5ecc5");
                logger.info("📱 Connected to same Firebase project as mobile app");

            } else {
                logger.info("Firebase app already initialized");
            }

        } catch (IOException e) {
            logger.error("❌ Failed to initialize Firebase Admin SDK: {}", e.getMessage());
            logger.error("Make sure firebase-service-account.json exists in src/main/resources/");
            logger.error("Download it from Firebase Console > Project Settings > Service Accounts");
        } catch (Exception e) {
            logger.error("❌ Unexpected error initializing Firebase: {}", e.getMessage());
        }
    }
}