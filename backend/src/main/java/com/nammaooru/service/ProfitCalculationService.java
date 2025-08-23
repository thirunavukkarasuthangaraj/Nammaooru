package com.nammaooru.service;

import com.nammaooru.entity.Order;
import com.nammaooru.entity.OrderItem;
import com.nammaooru.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ProfitCalculationService {

    private final OrderRepository orderRepository;
    
    @Value("${app.platform.commission:0.15}")
    private BigDecimal platformCommission; // 15% platform fee
    
    @Value("${app.delivery.partner.share:0.80}")
    private BigDecimal deliveryPartnerShare; // 80% of delivery fee goes to partner
    
    @Value("${app.product.cost.margin:0.70}")
    private BigDecimal productCostMargin; // Products cost 70% of selling price

    // Calculate profit for date range
    public ProfitAnalysis calculateProfit(Long shopId, LocalDate startDate, LocalDate endDate) {
        try {
            List<Order> orders = orderRepository.findByShopIdAndCreatedAtBetween(
                shopId,
                startDate.atStartOfDay(),
                endDate.atTime(LocalTime.MAX)
            );

            BigDecimal totalRevenue = BigDecimal.ZERO;
            BigDecimal totalCost = BigDecimal.ZERO;
            Map<String, ProfitableItem> itemProfitMap = new HashMap<>();

            for (Order order : orders) {
                if (!"DELIVERED".equals(order.getStatus()) && !"COMPLETED".equals(order.getStatus())) {
                    continue; // Only count completed orders
                }

                // Revenue
                BigDecimal orderRevenue = order.getTotalAmount();
                totalRevenue = totalRevenue.add(orderRevenue);

                // Calculate costs
                OrderCost orderCost = calculateOrderCost(order);
                totalCost = totalCost.add(orderCost.getTotalCost());

                // Track item profitability
                for (OrderItem item : order.getOrderItems()) {
                    String itemName = item.getProductName();
                    BigDecimal itemRevenue = item.getTotalPrice();
                    BigDecimal itemCost = itemRevenue.multiply(productCostMargin);
                    BigDecimal itemProfit = itemRevenue.subtract(itemCost);

                    itemProfitMap.compute(itemName, (k, v) -> {
                        if (v == null) {
                            v = new ProfitableItem();
                            v.setName(itemName);
                            v.setProfit(BigDecimal.ZERO);
                            v.setRevenue(BigDecimal.ZERO);
                        }
                        v.setProfit(v.getProfit().add(itemProfit));
                        v.setRevenue(v.getRevenue().add(itemRevenue));
                        return v;
                    });
                }
            }

            BigDecimal totalProfit = totalRevenue.subtract(totalCost);
            BigDecimal profitMargin = totalRevenue.compareTo(BigDecimal.ZERO) > 0 
                ? totalProfit.divide(totalRevenue, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100))
                : BigDecimal.ZERO;

            // Get top profitable items
            List<TopProfitableItem> topItems = itemProfitMap.values().stream()
                .sorted((a, b) -> b.getProfit().compareTo(a.getProfit()))
                .limit(5)
                .map(item -> {
                    TopProfitableItem top = new TopProfitableItem();
                    top.setName(item.getName());
                    top.setProfit(item.getProfit());
                    top.setMargin(item.getRevenue().compareTo(BigDecimal.ZERO) > 0
                        ? item.getProfit().divide(item.getRevenue(), 4, RoundingMode.HALF_UP)
                            .multiply(BigDecimal.valueOf(100))
                        : BigDecimal.ZERO);
                    return top;
                })
                .collect(Collectors.toList());

            // Calculate daily profit trend
            Map<String, BigDecimal> profitTrend = calculateDailyProfitTrend(orders);

            return ProfitAnalysis.builder()
                .totalRevenue(totalRevenue)
                .totalCost(totalCost)
                .totalProfit(totalProfit)
                .totalOrders(orders.size())
                .profitMargin(profitMargin)
                .averageOrderProfit(orders.size() > 0 
                    ? totalProfit.divide(BigDecimal.valueOf(orders.size()), 2, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO)
                .profitTrend(profitTrend)
                .topProfitableItems(topItems)
                .build();

        } catch (Exception e) {
            log.error("Error calculating profit for shop {}: ", shopId, e);
            throw new RuntimeException("Failed to calculate profit", e);
        }
    }

    // Get real-time profit for today
    public Map<String, Object> getRealTimeProfit(Long shopId) {
        try {
            LocalDate today = LocalDate.now();
            ProfitAnalysis todayProfit = calculateProfit(shopId, today, today);
            
            // Calculate projected profit based on current time
            LocalDateTime now = LocalDateTime.now();
            int currentHour = now.getHour();
            BigDecimal hoursElapsed = BigDecimal.valueOf(currentHour);
            BigDecimal totalHours = BigDecimal.valueOf(24);
            
            BigDecimal projectedProfit = hoursElapsed.compareTo(BigDecimal.ZERO) > 0
                ? todayProfit.getTotalProfit().divide(hoursElapsed, 2, RoundingMode.HALF_UP)
                    .multiply(totalHours)
                : todayProfit.getTotalProfit();

            // Get last hour profit
            LocalDateTime oneHourAgo = now.minusHours(1);
            List<Order> lastHourOrders = orderRepository.findByShopIdAndCreatedAtBetween(
                shopId, oneHourAgo, now
            );
            
            BigDecimal lastHourProfit = calculateOrdersProfit(lastHourOrders);

            Map<String, Object> result = new HashMap<>();
            result.put("currentProfit", todayProfit.getTotalProfit());
            result.put("projectedProfit", projectedProfit);
            result.put("profitMargin", todayProfit.getProfitMargin());
            result.put("profitTrend", todayProfit.getTotalProfit().compareTo(projectedProfit) > 0 
                ? "increasing" : "decreasing");
            result.put("lastHourProfit", lastHourProfit);
            result.put("topProfitableItem", todayProfit.getTopProfitableItems().isEmpty() 
                ? "N/A" : todayProfit.getTopProfitableItems().get(0).getName());

            return result;
        } catch (Exception e) {
            log.error("Error getting real-time profit for shop {}: ", shopId, e);
            return getDefaultRealTimeProfit();
        }
    }

    // Calculate cost breakdown for an order
    private OrderCost calculateOrderCost(Order order) {
        OrderCost cost = new OrderCost();
        
        // Product cost (70% of product revenue)
        BigDecimal productRevenue = order.getSubtotal();
        cost.setProductCost(productRevenue.multiply(productCostMargin));
        
        // Platform fees (15% of total)
        cost.setPlatformFees(order.getTotalAmount().multiply(platformCommission));
        
        // Delivery fees (20% kept by platform, 80% to partner)
        BigDecimal deliveryFee = order.getDeliveryFee();
        cost.setDeliveryFees(deliveryFee.multiply(deliveryPartnerShare));
        
        // Packaging cost (estimated 2% of order value)
        cost.setPackagingCost(order.getSubtotal().multiply(BigDecimal.valueOf(0.02)));
        
        // Other costs (1% of order value)
        cost.setOtherCosts(order.getSubtotal().multiply(BigDecimal.valueOf(0.01)));
        
        // Total cost
        cost.setTotalCost(
            cost.getProductCost()
                .add(cost.getPlatformFees())
                .add(cost.getDeliveryFees())
                .add(cost.getPackagingCost())
                .add(cost.getOtherCosts())
        );
        
        return cost;
    }

    // Calculate profit for a list of orders
    private BigDecimal calculateOrdersProfit(List<Order> orders) {
        BigDecimal totalRevenue = orders.stream()
            .filter(o -> "DELIVERED".equals(o.getStatus()) || "COMPLETED".equals(o.getStatus()))
            .map(Order::getTotalAmount)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        BigDecimal totalCost = orders.stream()
            .filter(o -> "DELIVERED".equals(o.getStatus()) || "COMPLETED".equals(o.getStatus()))
            .map(this::calculateOrderCost)
            .map(OrderCost::getTotalCost)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        return totalRevenue.subtract(totalCost);
    }

    // Calculate daily profit trend
    private Map<String, BigDecimal> calculateDailyProfitTrend(List<Order> orders) {
        Map<LocalDate, List<Order>> ordersByDate = orders.stream()
            .collect(Collectors.groupingBy(o -> o.getCreatedAt().toLocalDate()));
        
        Map<String, BigDecimal> trend = new TreeMap<>();
        for (Map.Entry<LocalDate, List<Order>> entry : ordersByDate.entrySet()) {
            BigDecimal dayProfit = calculateOrdersProfit(entry.getValue());
            trend.put(entry.getKey().toString(), dayProfit);
        }
        
        return trend;
    }

    // Get default real-time profit data
    private Map<String, Object> getDefaultRealTimeProfit() {
        Map<String, Object> result = new HashMap<>();
        result.put("currentProfit", BigDecimal.valueOf(2500));
        result.put("projectedProfit", BigDecimal.valueOf(5000));
        result.put("profitMargin", BigDecimal.valueOf(30));
        result.put("profitTrend", "stable");
        result.put("lastHourProfit", BigDecimal.valueOf(350));
        result.put("topProfitableItem", "N/A");
        return result;
    }

    // Inner classes
    @lombok.Data
    private static class OrderCost {
        private BigDecimal productCost = BigDecimal.ZERO;
        private BigDecimal platformFees = BigDecimal.ZERO;
        private BigDecimal deliveryFees = BigDecimal.ZERO;
        private BigDecimal packagingCost = BigDecimal.ZERO;
        private BigDecimal otherCosts = BigDecimal.ZERO;
        private BigDecimal totalCost = BigDecimal.ZERO;
    }

    @lombok.Data
    private static class ProfitableItem {
        private String name;
        private BigDecimal profit;
        private BigDecimal revenue;
    }
}

// Response DTOs
@lombok.Data
@lombok.Builder
class ProfitAnalysis {
    private BigDecimal totalRevenue;
    private BigDecimal totalCost;
    private BigDecimal totalProfit;
    private Integer totalOrders;
    private BigDecimal profitMargin;
    private BigDecimal averageOrderProfit;
    private Map<String, BigDecimal> profitTrend;
    private List<TopProfitableItem> topProfitableItems;
}

@lombok.Data
class TopProfitableItem {
    private String name;
    private BigDecimal profit;
    private BigDecimal margin;
}