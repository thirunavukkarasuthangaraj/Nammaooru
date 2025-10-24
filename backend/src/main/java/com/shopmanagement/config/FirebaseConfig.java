package com.shopmanagement.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import jakarta.annotation.PostConstruct;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;

@Configuration
public class FirebaseConfig {

    private static final Logger logger = LoggerFactory.getLogger(FirebaseConfig.class);

    static {
        System.out.println("🔥🔥🔥 FirebaseConfig CLASS LOADING - Static block executed!");
    }

    @Value("${firebase.service-account-path:}")
    private String firebaseServiceAccountPath;

    public FirebaseConfig() {
        System.out.println("🔥🔥🔥 FirebaseConfig CONSTRUCTOR called!");
        logger.info("🔥🔥🔥 FirebaseConfig bean being created!");
    }

    @PostConstruct
    public void initializeFirebase() {
        System.out.println("🔥🔥🔥 FirebaseConfig @PostConstruct method CALLED!");
        System.out.println("🔥 firebase.service-account-path value: " + firebaseServiceAccountPath);
        try {
            // Check if Firebase app is already initialized
            System.out.println("🔥 Checking if Firebase apps exist...");
            if (FirebaseApp.getApps().isEmpty()) {
                System.out.println("🔥 Firebase apps list is empty, initializing...");
                InputStream serviceAccount = getFirebaseServiceAccountStream();

                // Build Firebase options using the mobile app's project configuration
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .setProjectId("nammaooru-shop-management")  // Same as mobile app
                        .build();

                // Initialize Firebase
                FirebaseApp.initializeApp(options);

                System.out.println("✅ Firebase Admin SDK initialized successfully for project: nammaooru-shop-management");
                System.out.println("📱 Connected to same Firebase project as mobile app");
                logger.info("✅ Firebase Admin SDK initialized successfully for project: nammaooru-shop-management");

            } else {
                System.out.println("Firebase app already initialized");
                logger.info("Firebase app already initialized");
            }

        } catch (IOException e) {
            System.out.println("❌ Failed to initialize Firebase Admin SDK: " + e.getMessage());
            e.printStackTrace();
            logger.error("❌ Failed to initialize Firebase Admin SDK: {}", e.getMessage());
            logger.error("Troubleshooting:");
            logger.error("  1. For local development: Make sure firebase-service-account.json exists in src/main/resources/");
            logger.error("  2. For production: Make sure file exists at /opt/shop-management/firebase-config/firebase-service-account.json");
            logger.error("  3. Download from Firebase Console > Project Settings > Service Accounts");
        } catch (Exception e) {
            logger.error("❌ Unexpected error initializing Firebase: {}", e.getMessage());
        }
    }

    /**
     * Get Firebase service account input stream
     * Tries multiple locations in order:
     * 1. Environment variable path (production: /app/firebase-config/firebase-service-account.json)
     * 2. Classpath resource (local development: src/main/resources/firebase-service-account.json)
     */
    private InputStream getFirebaseServiceAccountStream() throws IOException {
        System.out.println("🔍 getFirebaseServiceAccountStream() called");
        System.out.println("🔍 firebaseServiceAccountPath = " + firebaseServiceAccountPath);

        // Option 1: Try environment variable path (production)
        if (firebaseServiceAccountPath != null && !firebaseServiceAccountPath.isEmpty()) {
            System.out.println("🔍 Checking if file exists at: " + firebaseServiceAccountPath);
            if (Files.exists(Paths.get(firebaseServiceAccountPath))) {
                System.out.println("📂 Loading Firebase credentials from: " + firebaseServiceAccountPath);
                logger.info("📂 Loading Firebase credentials from: {}", firebaseServiceAccountPath);
                return new FileInputStream(firebaseServiceAccountPath);
            } else {
                System.out.println("⚠️  FIREBASE_SERVICE_ACCOUNT path set but file not found: " + firebaseServiceAccountPath);
                logger.warn("⚠️  FIREBASE_SERVICE_ACCOUNT path set but file not found: {}", firebaseServiceAccountPath);
            }
        } else {
            System.out.println("⚠️  firebaseServiceAccountPath is null or empty!");
        }

        // Option 2: Try classpath resource (local development)
        System.out.println("🔍 Trying classpath resource...");
        try {
            ClassPathResource resource = new ClassPathResource("firebase-service-account.json");
            if (resource.exists()) {
                System.out.println("📂 Loading Firebase credentials from classpath (local development)");
                logger.info("📂 Loading Firebase credentials from classpath (local development)");
                return resource.getInputStream();
            } else {
                System.out.println("⚠️  Classpath resource not found");
            }
        } catch (IOException e) {
            System.out.println("⚠️  Error checking classpath: " + e.getMessage());
        }

        // No Firebase credentials found
        String errorMsg = "Firebase service account file not found. Checked:\n" +
                "  1. Environment variable path: " + (firebaseServiceAccountPath != null ? firebaseServiceAccountPath : "not set") + "\n" +
                "  2. Classpath: firebase-service-account.json";
        System.out.println("❌ " + errorMsg);
        throw new IOException(errorMsg);
    }
}