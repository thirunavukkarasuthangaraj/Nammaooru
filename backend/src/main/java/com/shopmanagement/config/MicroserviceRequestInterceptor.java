package com.shopmanagement.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.http.HttpRequest;
import org.springframework.http.client.ClientHttpRequestExecution;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.stereotype.Component;

import java.io.IOException;

@Slf4j
@Component
@RequiredArgsConstructor
public class MicroserviceRequestInterceptor implements ClientHttpRequestInterceptor {

    private final MicroserviceProperties microserviceProperties;

    @Override
    public ClientHttpResponse intercept(HttpRequest request, byte[] body,
                                         ClientHttpRequestExecution execution) throws IOException {
        long startTime = System.currentTimeMillis();

        // Add API Key header
        String apiKey = microserviceProperties.getApiKey();
        if (apiKey != null && !apiKey.isEmpty()) {
            request.getHeaders().set("X-API-Key", apiKey);
        }

        // Add Correlation ID from MDC
        String correlationId = MDC.get("correlationId");
        if (correlationId != null) {
            request.getHeaders().set("X-Correlation-ID", correlationId);
        }

        // Add Service Name header
        request.getHeaders().set("X-Service-Name", "shop-management-monolith");

        log.info("[Interceptor] {} {} | headers: API-Key={}, Correlation-ID={}, Service=shop-management-monolith",
                request.getMethod(), request.getURI(),
                apiKey != null && !apiKey.isEmpty() ? "present" : "missing",
                correlationId != null ? correlationId : "none");

        ClientHttpResponse response = execution.execute(request, body);

        long duration = System.currentTimeMillis() - startTime;
        log.info("[Interceptor] {} {} → {} | {}ms",
                request.getMethod(), request.getURI(), response.getStatusCode(), duration);

        return response;
    }
}
