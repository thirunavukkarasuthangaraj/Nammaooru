package com.shopmanagement.config;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.util.ContentCachingRequestWrapper;
import org.springframework.web.util.ContentCachingResponseWrapper;

import java.io.IOException;
import java.io.UnsupportedEncodingException;

@Slf4j
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class ApiLoggingFilter implements Filter {

    @Value("${logging.api.enabled:false}")
    private boolean loggingEnabled;

    @Value("${logging.api.log-body:false}")
    private boolean logBody;

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        // Skip logging entirely if disabled
        if (!loggingEnabled) {
            chain.doFilter(request, response);
            return;
        }

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        // Wrap request and response for reading body content (only if logging body)
        if (logBody) {
            ContentCachingRequestWrapper requestWrapper = new ContentCachingRequestWrapper(httpRequest);
            ContentCachingResponseWrapper responseWrapper = new ContentCachingResponseWrapper(httpResponse);

            long startTime = System.currentTimeMillis();

            try {
                chain.doFilter(requestWrapper, responseWrapper);
            } finally {
                long duration = System.currentTimeMillis() - startTime;
                logRequestCompact(requestWrapper, responseWrapper.getStatus(), duration);
                responseWrapper.copyBodyToResponse();
            }
        } else {
            // Simple logging without body caching
            long startTime = System.currentTimeMillis();
            try {
                chain.doFilter(request, response);
            } finally {
                long duration = System.currentTimeMillis() - startTime;
                logRequestCompact(httpRequest, httpResponse.getStatus(), duration);
            }
        }
    }

    private void logRequestCompact(HttpServletRequest request, int status, long duration) {
        String method = request.getMethod();
        String uri = request.getRequestURI();
        String queryString = request.getQueryString();
        String fullUrl = queryString != null ? uri + "?" + queryString : uri;

        // Skip health check endpoints to reduce noise
        if (uri.contains("/actuator/health") || uri.contains("/favicon.ico")) {
            return;
        }

        String statusIcon = status >= 200 && status < 300 ? "✓" : (status >= 400 ? "✗" : "→");
        log.info("{} {} {} [{}ms] {}", statusIcon, method, status, duration, fullUrl);
    }
}
