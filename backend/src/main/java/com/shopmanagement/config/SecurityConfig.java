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
                                "/api/customer/**",  // ALLOW ALL CUSTOMER ENDPOINTS WITHOUT AUTH
                                "/api/mobile/delivery-partner/login",
                                "/api/mobile/delivery-partner/forgot-password",
                                "/api/mobile/delivery-partner/orders/**",
                                "/api/delivery/partners/*/documents/**",
                                "/api/delivery/partners/documents/*/view",
                                "/api/delivery-fees/**",
                                "/api/customer/shops/**",
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
                        .requestMatchers(HttpMethod.GET, "/api/products/**").permitAll() // Allow everyone to view products
                        .requestMatchers("/api/products/**").authenticated() // Allow all authenticated users for all product operations
                        .requestMatchers("/api/super-admin/**").hasRole("SUPER_ADMIN")
                        .requestMatchers("/api/admin/**").hasAnyRole("SUPER_ADMIN", "ADMIN")
                        .requestMatchers("/api/shops/approvals/**").hasAnyRole("SUPER_ADMIN", "ADMIN")
                        .requestMatchers("/api/shops/**").hasAnyRole("SUPER_ADMIN", "ADMIN", "SHOP_OWNER")
                        .requestMatchers("/api/shop-owner/**").hasAnyRole("SUPER_ADMIN", "ADMIN", "SHOP_OWNER")
                        .requestMatchers("/api/orders/**").hasAnyRole("SUPER_ADMIN", "ADMIN", "SHOP_OWNER", "DELIVERY_PARTNER")
                        .requestMatchers("/api/mobile/delivery-partner/**").hasAnyRole("SUPER_ADMIN", "ADMIN", "DELIVERY_PARTNER")
                        .requestMatchers("/api/delivery/partners/**").hasAnyRole("SUPER_ADMIN", "ADMIN", "DELIVERY_PARTNER")
                        .requestMatchers("/api/assignments/**").hasAnyRole("SUPER_ADMIN", "ADMIN", "SHOP_OWNER", "DELIVERY_PARTNER")
                        .requestMatchers("/api/documents/**").hasAnyRole("SUPER_ADMIN", "ADMIN", "SHOP_OWNER")
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