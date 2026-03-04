package com.shopmanagement.userservice.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Slf4j
@Component
@Order(1)
public class ApiKeyFilter extends OncePerRequestFilter {

    private static final String API_KEY_HEADER = "X-API-Key";

    @Value("${internal.api.key:}")
    private String internalApiKey;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                     FilterChain filterChain) throws ServletException, IOException {
        String path = request.getRequestURI();

        // Only protect /internal/** endpoints
        if (path.startsWith("/internal")) {
            // If no API key is configured, skip validation (development mode)
            if (internalApiKey == null || internalApiKey.isEmpty()) {
                log.warn("[ApiKeyFilter] No internal API key configured - skipping validation for {}", path);
                filterChain.doFilter(request, response);
                return;
            }

            String providedKey = request.getHeader(API_KEY_HEADER);
            if (providedKey == null || !providedKey.equals(internalApiKey)) {
                log.warn("[ApiKeyFilter] Invalid or missing API key for {} from {}",
                        path, request.getRemoteAddr());
                response.setStatus(HttpStatus.UNAUTHORIZED.value());
                response.setContentType("application/json");
                response.getWriter().write("{\"error\":\"Unauthorized\",\"message\":\"Invalid or missing API key\"}");
                return;
            }

            log.debug("[ApiKeyFilter] Valid API key for {} from {}", path, request.getRemoteAddr());
        }

        filterChain.doFilter(request, response);
    }
}
