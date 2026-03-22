package com.shopmanagement.userservice.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.shopmanagement.userservice.service.JwtService;
import com.shopmanagement.userservice.service.TokenBlacklistService;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.SignatureException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserDetailsService userDetailsService;
    private final TokenBlacklistService tokenBlacklistService;

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {
        String path = request.getServletPath();
        log.debug("JWT Filter - Processing path: {}", path);

        // Skip JWT filter for public endpoints
        if (path.startsWith("/api/auth/login") || path.startsWith("/api/auth/register") ||
            path.startsWith("/api/auth/forgot-password") || path.startsWith("/api/auth/reset-password") ||
            path.startsWith("/internal/")) {
            filterChain.doFilter(request, response);
            return;
        }

        final String authHeader = request.getHeader("Authorization");
        final String jwt;
        final String username;

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        jwt = authHeader.substring(7);

        // Check if token is blacklisted
        if (tokenBlacklistService.isTokenBlacklisted(jwt)) {
            log.warn("JWT Filter - Token is blacklisted");
            sendErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "TOKEN_INVALIDATED",
                    "Session has been logged out. Please login again.", path);
            return;
        }

        try {
            username = jwtService.extractUsername(jwt);
        } catch (ExpiredJwtException e) {
            log.debug("JWT Filter - TOKEN EXPIRED");
            sendErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "TOKEN_EXPIRED",
                    "Your session has expired. Please login again.", path);
            return;
        } catch (MalformedJwtException e) {
            log.debug("JWT Filter - MALFORMED TOKEN");
            sendErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "TOKEN_MALFORMED",
                    "Invalid token format. Please login again.", path);
            return;
        } catch (SignatureException e) {
            log.debug("JWT Filter - INVALID SIGNATURE");
            sendErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "TOKEN_INVALID_SIGNATURE",
                    "Token signature is invalid. Please login again.", path);
            return;
        } catch (Exception e) {
            log.debug("JWT Filter - Failed to extract username: {}", e.getMessage());
            sendErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "TOKEN_INVALID",
                    "Invalid token. Please login again.", path);
            return;
        }

        if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            try {
                UserDetails userDetails = this.userDetailsService.loadUserByUsername(username);

                if (jwtService.isTokenValid(jwt, userDetails)) {
                    UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                            userDetails,
                            null,
                            userDetails.getAuthorities()
                    );
                    authToken.setDetails(
                            new WebAuthenticationDetailsSource().buildDetails(request)
                    );
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                }
            } catch (Exception e) {
                log.error("JWT Filter - Error loading user: {}", e.getMessage());
            }
        }
        filterChain.doFilter(request, response);
    }

    private void sendErrorResponse(HttpServletResponse response, int status, String errorCode,
                                   String message, String path) throws IOException {
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);

        Map<String, Object> errorBody = new HashMap<>();
        errorBody.put("statusCode", errorCode);
        errorBody.put("message", message);
        errorBody.put("path", path);
        errorBody.put("timestamp", LocalDateTime.now().toString());

        ObjectMapper mapper = new ObjectMapper();
        response.getWriter().write(mapper.writeValueAsString(errorBody));
    }
}
