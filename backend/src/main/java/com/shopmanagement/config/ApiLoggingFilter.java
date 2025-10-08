package com.shopmanagement.config;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.util.ContentCachingRequestWrapper;
import org.springframework.web.util.ContentCachingResponseWrapper;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.Enumeration;

@Slf4j
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class ApiLoggingFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        // Wrap request and response for reading body content
        ContentCachingRequestWrapper requestWrapper = new ContentCachingRequestWrapper(httpRequest);
        ContentCachingResponseWrapper responseWrapper = new ContentCachingResponseWrapper(httpResponse);

        long startTime = System.currentTimeMillis();

        try {
            chain.doFilter(requestWrapper, responseWrapper);
        } finally {
            long duration = System.currentTimeMillis() - startTime;

            // Log request details
            logRequest(requestWrapper, duration);

            // Log response details
            logResponse(responseWrapper, duration);

            // IMPORTANT: Copy the response body back to the original response
            responseWrapper.copyBodyToResponse();
        }
    }

    private void logRequest(ContentCachingRequestWrapper request, long duration) {
        try {
            String method = request.getMethod();
            String uri = request.getRequestURI();
            String queryString = request.getQueryString();
            String fullUrl = queryString != null ? uri + "?" + queryString : uri;

            log.info("\n╔════════════════════════════════════════════════════════════════════════");
            log.info("║ 🚀 API REQUEST");
            log.info("╠════════════════════════════════════════════════════════════════════════");
            log.info("║ Method: {}", method);
            log.info("║ URL: {}", fullUrl);
            log.info("║ Remote Address: {}", request.getRemoteAddr());

            // Log headers
            log.info("║ Headers:");
            Enumeration<String> headerNames = request.getHeaderNames();
            while (headerNames.hasMoreElements()) {
                String headerName = headerNames.nextElement();
                String headerValue = request.getHeader(headerName);

                // Mask sensitive headers
                if (headerName.equalsIgnoreCase("authorization")) {
                    if (headerValue != null && headerValue.startsWith("Bearer ")) {
                        log.info("║   {}: Bearer {}...", headerName, headerValue.substring(7, Math.min(27, headerValue.length())));
                    } else {
                        log.info("║   {}: [MASKED]", headerName);
                    }
                } else {
                    log.info("║   {}: {}", headerName, headerValue);
                }
            }

            // Log request body
            String requestBody = getRequestBody(request);
            if (requestBody != null && !requestBody.isEmpty()) {
                log.info("║ Request Body:");
                // Mask sensitive data in request body
                String maskedBody = maskSensitiveData(requestBody);
                log.info("║ {}", maskedBody);
            }

            log.info("╚════════════════════════════════════════════════════════════════════════");

        } catch (Exception e) {
            log.error("Error logging request", e);
        }
    }

    private void logResponse(ContentCachingResponseWrapper response, long duration) {
        try {
            int status = response.getStatus();

            log.info("\n╔════════════════════════════════════════════════════════════════════════");
            if (status >= 200 && status < 300) {
                log.info("║ ✅ API RESPONSE ({}ms)", duration);
            } else if (status >= 400) {
                log.info("║ ❌ API ERROR ({}ms)", duration);
            } else {
                log.info("║ 📤 API RESPONSE ({}ms)", duration);
            }
            log.info("╠════════════════════════════════════════════════════════════════════════");
            log.info("║ Status Code: {}", status);

            // Log response headers
            log.info("║ Response Headers:");
            response.getHeaderNames().forEach(headerName -> {
                log.info("║   {}: {}", headerName, response.getHeader(headerName));
            });

            // Log response body
            String responseBody = getResponseBody(response);
            if (responseBody != null && !responseBody.isEmpty()) {
                log.info("║ Response Body:");
                log.info("║ {}", responseBody);
            }

            log.info("╚════════════════════════════════════════════════════════════════════════\n");

        } catch (Exception e) {
            log.error("Error logging response", e);
        }
    }

    private String getRequestBody(ContentCachingRequestWrapper request) {
        try {
            byte[] content = request.getContentAsByteArray();
            if (content.length > 0) {
                return new String(content, request.getCharacterEncoding());
            }
        } catch (UnsupportedEncodingException e) {
            log.error("Error reading request body", e);
        }
        return null;
    }

    private String getResponseBody(ContentCachingResponseWrapper response) {
        try {
            byte[] content = response.getContentAsByteArray();
            if (content.length > 0) {
                return new String(content, response.getCharacterEncoding());
            }
        } catch (UnsupportedEncodingException e) {
            log.error("Error reading response body", e);
        }
        return null;
    }

    private String maskSensitiveData(String data) {
        if (data == null) {
            return null;
        }

        // Mask password fields
        data = data.replaceAll("(\"password\"\\s*:\\s*\")([^\"]+)(\")", "$1***MASKED***$3");
        data = data.replaceAll("(\"oldPassword\"\\s*:\\s*\")([^\"]+)(\")", "$1***MASKED***$3");
        data = data.replaceAll("(\"newPassword\"\\s*:\\s*\")([^\"]+)(\")", "$1***MASKED***$3");

        // Mask token fields
        data = data.replaceAll("(\"token\"\\s*:\\s*\")([^\"]+)(\")", "$1***MASKED***$3");
        data = data.replaceAll("(\"refreshToken\"\\s*:\\s*\")([^\"]+)(\")", "$1***MASKED***$3");

        // Mask credit card
        data = data.replaceAll("(\"cardNumber\"\\s*:\\s*\")([^\"]+)(\")", "$1***MASKED***$3");
        data = data.replaceAll("(\"cvv\"\\s*:\\s*\")([^\"]+)(\")", "$1***MASKED***$3");

        return data;
    }
}
