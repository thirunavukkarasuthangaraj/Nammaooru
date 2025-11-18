package com.shopmanagement.config;

import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.context.ApplicationContextInitializer;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

/**
 * Loads environment variables from .env file in the project root directory.
 * This allows Spring Boot to access environment variables defined in .env files.
 */
public class DotEnvConfig implements ApplicationContextInitializer<ConfigurableApplicationContext> {

    @Override
    public void initialize(ConfigurableApplicationContext applicationContext) {
        ConfigurableEnvironment environment = applicationContext.getEnvironment();

        try {
            // Look for .env file in parent directory (project root)
            File projectRoot = new File("../").getCanonicalFile();
            File envFile = new File(projectRoot, ".env");

            Dotenv dotenv;
            if (envFile.exists()) {
                // Load from project root
                dotenv = Dotenv.configure()
                        .directory(projectRoot.getAbsolutePath())
                        .ignoreIfMissing()
                        .load();
            } else {
                // Fallback: try current directory
                dotenv = Dotenv.configure()
                        .ignoreIfMissing()
                        .load();
            }

            // Add all dotenv entries to Spring environment
            Map<String, Object> dotenvProperties = new HashMap<>();
            dotenv.entries().forEach(entry -> {
                dotenvProperties.put(entry.getKey(), entry.getValue());
            });

            environment.getPropertySources()
                    .addFirst(new MapPropertySource("dotenvProperties", dotenvProperties));

            System.out.println("✅ Loaded .env file from: " + envFile.getAbsolutePath());

        } catch (Exception e) {
            System.err.println("⚠️  Warning: Could not load .env file: " + e.getMessage());
            System.err.println("   Application will use system environment variables or default values.");
        }
    }
}
