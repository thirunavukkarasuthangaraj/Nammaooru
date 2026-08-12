package com.shopmanagement.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.shopmanagement.service.ShopPaymentCollectService;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.service.ShopService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.lang.NonNull;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Pay-and-use hard lock: once a SHOP_OWNER's shop payment is due, every API call except
 * auth, the payment-collect endpoints, and menu permissions is rejected with 402 so the
 * Angular app has no way to route around the "Pay & Use" screen.
 */
@Component
@RequiredArgsConstructor
public class ShopPaymentGateFilter extends OncePerRequestFilter {

    private final ShopPaymentCollectService shopPaymentCollectService;
    private final ShopService shopService;
    private final ObjectMapper objectMapper;

    private static final List<String> ALLOWED_PREFIXES = List.of(
            "/api/auth/",
            "/api/shop-owner-payments/",
            "/api/menu-permissions/",
            "/api/shops/" // already permitAll in SecurityConfig; blocking it here is noise, not security
    );

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain) throws ServletException, IOException {

        if (HttpMethod.OPTIONS.matches(request.getMethod()) || isAllowed(request.getRequestURI())) {
            filterChain.doFilter(request, response);
            return;
        }

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        boolean isShopOwner = auth != null && auth.isAuthenticated() && auth.getAuthorities().stream()
                .anyMatch(a -> "ROLE_SHOP_OWNER".equals(a.getAuthority()));

        if (!isShopOwner) {
            filterChain.doFilter(request, response);
            return;
        }

        Shop shop = shopService.getShopByOwner(auth.getName());
        if (shop == null || shopPaymentCollectService.isCurrentlyPaid(shop.getId())) {
            filterChain.doFilter(request, response);
            return;
        }

        response.setStatus(HttpStatus.PAYMENT_REQUIRED.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        Map<String, Object> body = new HashMap<>();
        body.put("success", false);
        body.put("statusCode", "PAYMENT_REQUIRED");
        body.put("message", "Payment required to continue using the app");
        response.getWriter().write(objectMapper.writeValueAsString(body));
    }

    private boolean isAllowed(String path) {
        return ALLOWED_PREFIXES.stream().anyMatch(path::startsWith);
    }
}
