package com.shopmanagement.config;

import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.context.annotation.Lazy;
import org.springframework.http.HttpMethod;

import java.util.Arrays;
import java.util.List;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
@EnableMethodSecurity
public class SecurityConfig {

    private final UserRepository userRepository;

    @Bean
    public UserDetailsService userDetailsService() {
        return username -> userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService());
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http, @Lazy JwtAuthenticationFilter jwtAuthenticationFilter) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .authorizeHttpRequests(authz -> authz
                        .requestMatchers(
                                "/api/auth/**",
                                "/api/public/**",
                                "/api/version",
                                "/api/app-version/**",  // Allow app version check without authentication
                                "/api/customer/**",  // ALLOW ALL CUSTOMER ENDPOINTS WITHOUT AUTH
                                "/api/mobile/**",  // ALLOW ALL MOBILE ENDPOINTS (OTP, customer registration, etc.)
                                "/api/webhooks/**",  // ALLOW WEBHOOKS (MSG91, payment gateways, etc.)
                                "/api/promotions/active",  // Public: Get active promo codes
                                "/api/promotions/validate",  // Public: Validate promo code for customers
                                "/api/mobile/delivery-partner/login",
                                "/api/mobile/delivery-partner/forgot-password",
                                "/api/mobile/delivery-partner/orders/**",
                                "/api/delivery/partners/*/documents/**",
                                "/api/delivery/partners/documents/*/view",
                                "/api/delivery-fees/**",
                                "/api/bus-timings",  // Public: View active bus timings
                                "/api/bus-timings/*",  // Public: View single bus timing by ID
                                "/api/marketplace",  // Public: View approved marketplace posts
                                "/api/marketplace/*",  // Public: View single marketplace post by ID
                                "/api/farmer-products",  // Public: View approved farmer products
                                "/api/farmer-products/*",  // Public: View single farmer product by ID
                                "/api/real-estate",  // Public: View approved real estate posts
                                "/api/real-estate/featured",  // Public: View featured properties
                                "/api/real-estate/*",  // Public: View single property by ID
                                "/api/labours",  // Public: View approved labour posts
                                "/api/labours/*",  // Public: View single labour post by ID
                                "/api/travels",  // Public: View approved travel posts
                                "/api/travels/*",  // Public: View single travel post by ID
                                "/api/parcels",  // Public: View approved parcel posts
                                "/api/parcels/*",  // Public: View single parcel post by ID
                                "/api/rentals",  // Public: View approved rental posts
                                "/api/rentals/*",  // Public: View single rental post by ID
                                "/api/delivery/confirmation/**",  // Allow OTP verification
                                "/api/customer/shops/**",
                                "/api/featured-posts",  // Public: Get featured posts for mobile banner
                                "/api/post-payments/config",  // Public: Get payment config for mobile
                                "/api/villages",  // Public: View active villages for mobile
                                "/api/feature-config/visible",  // Public: Get visible features for mobile
                                "/api/settings/public/**",  // Public: Get public settings (privacy policy, etc.)
                                "/api/service-area/**",  // Public: Service area check (no auth needed)
                                "/api/mobile/delivery-partner/track/**",  // Allow public order tracking for customers
                                "/uploads/**",
                                "/shops/**",
                                "/delivery-partners/**",
                                "/actuator/**",
                                "/swagger-ui/**",
                                "/v3/api-docs/**",
                                "/swagger-resources/**",
                                "/webjars/**"
                        ).permitAll()
                        .requestMatchers("/api/delivery/partners/*/documents/upload").hasAnyRole("SUPER_ADMIN", "ADMIN", "DELIVERY_PARTNER")
                        .requestMatchers("/api/products/**").permitAll() // TEMPORARY: Allow all product operations without auth for testing
                        .requestMatchers("/api/v1/products/**").permitAll() // Allow v1 product operations (voice search, etc.)
                        .requestMatchers("/api/shops/**").permitAll() // TEMPORARY: Allow all shop operations without auth for testing
                        .requestMatchers("/api/documents/**").permitAll() // TEMPORARY: Allow all document operations without auth for testing
                        .requestMatchers("/api/super-admin/**").hasRole("SUPER_ADMIN")
                        .requestMatchers("/api/admin/**").hasAnyRole("SUPER_ADMIN", "ADMIN")
                        .requestMatchers("/api/shops/approvals/**").hasAnyRole("SUPER_ADMIN", "ADMIN")
                        .requestMatchers("/api/shop-owner/**").hasAnyRole("SUPER_ADMIN", "ADMIN", "SHOP_OWNER")
                        .requestMatchers("/api/orders/**").permitAll() // TEMPORARY: Allow all for testing
                        .requestMatchers("/api/mobile/delivery-partner/**").hasAnyRole("SUPER_ADMIN", "ADMIN", "DELIVERY_PARTNER")
                        .requestMatchers("/api/delivery/partners/**").hasAnyRole("SUPER_ADMIN", "ADMIN", "DELIVERY_PARTNER")
                        .requestMatchers("/api/assignments/**").hasAnyRole("SUPER_ADMIN", "ADMIN", "SHOP_OWNER", "DELIVERY_PARTNER")
                        .anyRequest().authenticated()
                )
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authenticationProvider(authenticationProvider())
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();
    configuration.setAllowCredentials(true);
    configuration.setAllowedOriginPatterns(Arrays.asList(
        "https://*.nammaoorudelivary.in",
        "https://nammaoorudelivary.in",
        "http://localhost:*"
    ));
    configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
    configuration.setAllowedHeaders(Arrays.asList("*"));
    configuration.setExposedHeaders(Arrays.asList("Authorization", "Content-Type", "X-Total-Count"));
    configuration.setMaxAge(3600L);

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", configuration);
    return source;
}

}