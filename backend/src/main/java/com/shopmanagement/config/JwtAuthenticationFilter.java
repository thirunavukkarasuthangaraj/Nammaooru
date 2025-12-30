package com.shopmanagement.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.shopmanagement.service.JwtService;
import com.shopmanagement.service.TokenBlacklistService;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.SignatureException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
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
        // Skip JWT filter only for login, register, and other public auth endpoints
        String path = request.getServletPath();
        System.out.println("JWT Filter - Processing path: " + path);

        if (path.equals("/api/auth/login") || path.equals("/api/auth/register") ||
            path.equals("/api/auth/forgot-password") || path.equals("/api/auth/reset-password")) {
            filterChain.doFilter(request, response);
            return;
        }

        final String authHeader = request.getHeader("Authorization");
        final String jwt;
        final String username;

        System.out.println("JWT Filter - Auth header: " + (authHeader != null ? "Present" : "Missing"));

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            System.out.println("JWT Filter - No Bearer token, continuing without auth");
            filterChain.doFilter(request, response);
            return;
        }

        jwt = authHeader.substring(7);
        System.out.println("JWT Filter - Token extracted: " + jwt.substring(0, Math.min(20, jwt.length())) + "...");

        // Check if token is blacklisted
        if (tokenBlacklistService.isTokenBlacklisted(jwt)) {
            System.out.println("JWT Filter - Token is blacklisted!");
            sendErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "TOKEN_INVALIDATED",
                    "Session has been logged out. Please login again.", path);
            return;
        }

        try {
            username = jwtService.extractUsername(jwt);
            System.out.println("JWT Filter - Username extracted: " + username);
        } catch (ExpiredJwtException e) {
            System.out.println("JWT Filter - TOKEN EXPIRED: " + e.getMessage());
            sendErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "TOKEN_EXPIRED",
                    "Your session has expired. Please login again.", path);
            return;
        } catch (MalformedJwtException e) {
            System.out.println("JWT Filter - MALFORMED TOKEN: " + e.getMessage());
            sendErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "TOKEN_MALFORMED",
                    "Invalid token format. Please login again.", path);
            return;
        } catch (SignatureException e) {
            System.out.println("JWT Filter - INVALID SIGNATURE: " + e.getMessage());
            sendErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "TOKEN_INVALID_SIGNATURE",
                    "Token signature is invalid. Please login again.", path);
            return;
        } catch (Exception e) {
            System.out.println("JWT Filter - Failed to extract username: " + e.getMessage());
            sendErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "TOKEN_INVALID",
                    "Invalid token. Please login again.", path);
            return;
        }

        if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            try {
                UserDetails userDetails = this.userDetailsService.loadUserByUsername(username);
                System.out.println("JWT Filter - User found: " + userDetails.getUsername());

                if (jwtService.isTokenValid(jwt, userDetails)) {
                    System.out.println("JWT Filter - Token is valid, setting authentication");
                    UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                            userDetails,
                            null,
                            userDetails.getAuthorities()
                    );
                    authToken.setDetails(
                            new WebAuthenticationDetailsSource().buildDetails(request)
                    );
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                } else {
                    System.out.println("JWT Filter - Token validation failed!");
                }
            } catch (Exception e) {
                System.out.println("JWT Filter - Error loading user: " + e.getMessage());
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