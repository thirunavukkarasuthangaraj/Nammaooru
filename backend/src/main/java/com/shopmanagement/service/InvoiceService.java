package com.shopmanagement.service;

import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderItem;
import com.shopmanagement.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class InvoiceService {

    private final OrderRepository orderRepository;
    private final EmailService emailService;

    @Transactional(readOnly = true)
    public Map<String, Object> generateInvoiceData(Long orderId) {
        log.info("Generating invoice data for order: {}", orderId);

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        // Get delivery assignment for distance and partner info
        // OrderAssignment assignment = assignmentRepository.findByOrderId(orderId).stream().findFirst().orElse(null);
        // PartnerEarning earning = null; // assignment != null ? 
            // earningRepository.findByOrderAssignment(assignment).orElse(null) : null;

        Map<String, Object> invoiceData = new HashMap<>();

        // Invoice metadata
        invoiceData.put("invoiceNumber", generateInvoiceNumber(order));
        invoiceData.put("invoiceDate", LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));

        // Customer information
        invoiceData.put("customerName", order.getCustomer().getFullName());
        invoiceData.put("customerEmail", order.getCustomer().getEmail());
        invoiceData.put("customerPhone", order.getCustomer().getMobileNumber());
        invoiceData.put("deliveryAddress", order.getDeliveryAddress());
        invoiceData.put("deliveryCity", order.getDeliveryCity());
        invoiceData.put("deliveryState", order.getDeliveryState());
        invoiceData.put("deliveryPostalCode", order.getDeliveryPostalCode());

        // Shop information
        invoiceData.put("shopName", order.getShop().getName());
        invoiceData.put("shopEmail", order.getShop().getOwnerEmail());
        invoiceData.put("shopPhone", order.getShop().getOwnerPhone());
        invoiceData.put("shopAddress", order.getShop().getAddressLine1() + ", " + order.getShop().getCity());

        // Order information
        invoiceData.put("orderNumber", order.getOrderNumber());
        invoiceData.put("orderDate", order.getCreatedAt().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
        invoiceData.put("paymentMethod", order.getPaymentMethod().name());
        invoiceData.put("orderStatus", order.getStatus().name());
        invoiceData.put("paymentStatus", order.getPaymentStatus().name());

        // Delivery information - commented out due to delivery package removal
        // if (assignment != null) {
        //     invoiceData.put("distanceCovered", earning != null && earning.getDistanceCovered() != null ? 
        //         earning.getDistanceCovered() : calculateEstimatedDistance(order));
        //     invoiceData.put("deliveryTime", calculateDeliveryTime(assignment));
        //     invoiceData.put("deliveryPartnerName", assignment.getDeliveryPartner().getFullName());
        //     invoiceData.put("vehicleType", assignment.getDeliveryPartner().getVehicleType().name());
        //     invoiceData.put("vehicleNumber", assignment.getDeliveryPartner().getVehicleNumber());
        // } else {
            invoiceData.put("distanceCovered", BigDecimal.ZERO);
            invoiceData.put("deliveryTime", "N/A");
            invoiceData.put("deliveryPartnerName", "Not Assigned");
            invoiceData.put("vehicleType", "N/A");
            invoiceData.put("vehicleNumber", "N/A");
        // }

        // Order items
        List<Map<String, Object>> itemsList = order.getOrderItems().stream()
                .map(this::mapOrderItemToInvoiceItem)
                .collect(Collectors.toList());
        invoiceData.put("orderItems", itemsList);

        // Calculate platform fees
        Map<String, BigDecimal> fees = calculatePlatformFees(order);
        invoiceData.putAll(fees);

        // Financial totals
        invoiceData.put("subtotal", order.getSubtotal());
        invoiceData.put("deliveryFee", order.getDeliveryFee());
        invoiceData.put("taxAmount", order.getTaxAmount());
        invoiceData.put("discountAmount", order.getDiscountAmount());
        invoiceData.put("totalAmount", order.getTotalAmount());

        // Payment information
        invoiceData.put("paymentDate", order.getUpdatedAt().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
        invoiceData.put("transactionId", generateTransactionId(order));
        invoiceData.put("amountPaid", order.getTotalAmount());

        log.info("Invoice data generated successfully for order: {}", orderId);
        return invoiceData;
    }

    @Transactional
    public void sendInvoiceEmail(Long orderId) {
        log.info("Sending invoice email for order: {}", orderId);

        try {
            Map<String, Object> invoiceData = generateInvoiceData(orderId);
            Order order = orderRepository.findById(orderId)
                    .orElseThrow(() -> new RuntimeException("Order not found"));

            emailService.sendInvoiceEmail(
                order.getCustomer().getEmail(),
                order.getCustomer().getFullName(),
                order.getOrderNumber(),
                invoiceData
            );

            log.info("Invoice email sent successfully for order: {}", orderId);
        } catch (Exception e) {
            log.error("Failed to send invoice email for order: {}", orderId, e);
            throw new RuntimeException("Failed to send invoice email", e);
        }
    }

    private Map<String, Object> mapOrderItemToInvoiceItem(OrderItem item) {
        Map<String, Object> itemMap = new HashMap<>();
        itemMap.put("productName", item.getProductName());
        itemMap.put("productDescription", item.getProductDescription());
        itemMap.put("productSku", item.getProductSku());
        itemMap.put("quantity", item.getQuantity());
        itemMap.put("unitPrice", item.getUnitPrice());
        itemMap.put("totalPrice", item.getTotalPrice());
        return itemMap;
    }

    private Map<String, BigDecimal> calculatePlatformFees(Order order) {
        BigDecimal subtotal = order.getSubtotal();
        
        // Calculate various platform fees
        BigDecimal serviceFee = subtotal.multiply(BigDecimal.valueOf(0.02)); // 2% service fee
        BigDecimal platformCommission = subtotal.multiply(BigDecimal.valueOf(0.03)); // 3% platform commission
        BigDecimal paymentGatewayFee = order.getPaymentMethod().name().contains("ONLINE") ? 
            subtotal.multiply(BigDecimal.valueOf(0.015)) : BigDecimal.ZERO; // 1.5% for online payments
        BigDecimal deliveryPartnerFee = order.getDeliveryFee().multiply(BigDecimal.valueOf(0.8)); // 80% of delivery fee goes to partner

        BigDecimal totalPlatformFees = serviceFee.add(platformCommission).add(paymentGatewayFee);

        Map<String, BigDecimal> fees = new HashMap<>();
        fees.put("serviceFee", serviceFee.setScale(2, RoundingMode.HALF_UP));
        fees.put("platformCommission", platformCommission.setScale(2, RoundingMode.HALF_UP));
        fees.put("paymentGatewayFee", paymentGatewayFee.setScale(2, RoundingMode.HALF_UP));
        fees.put("deliveryPartnerFee", deliveryPartnerFee.setScale(2, RoundingMode.HALF_UP));
        fees.put("totalPlatformFees", totalPlatformFees.setScale(2, RoundingMode.HALF_UP));

        return fees;
    }

    private String generateInvoiceNumber(Order order) {
        return "INV-" + order.getOrderNumber().substring(3); // Remove ORD prefix and add INV
    }

    private String generateTransactionId(Order order) {
        return "TXN" + order.getId() + System.currentTimeMillis();
    }

    private BigDecimal calculateEstimatedDistance(Order order) {
        // Simplified distance calculation based on delivery fee
        // In real implementation, this would use GPS coordinates
        return order.getDeliveryFee().divide(BigDecimal.valueOf(4), 2, RoundingMode.HALF_UP); // Assume ₹4 per km
    }

    // private String calculateDeliveryTime(OrderAssignment assignment) {
    //     if (assignment.getPickupTime() != null && assignment.getDeliveryTime() != null) {
    //         long minutes = java.time.Duration.between(assignment.getPickupTime(), assignment.getDeliveryTime()).toMinutes();
    //         return minutes + " minutes";
    //     }
    //     return "N/A";
    // }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> generateMonthlyInvoiceReport(int year, int month) {
        log.info("Generating monthly invoice report for {}-{}", year, month);
        
        // This would generate a comprehensive report of all invoices for the month
        // Implementation would include aggregated data, platform earnings, partner payments, etc.
        
        return List.of(); // Placeholder for implementation
    }

    @Transactional(readOnly = true)
    public Map<String, Object> generatePlatformEarningsReport(int year, int month) {
        log.info("Generating platform earnings report for {}-{}", year, month);
        
        // This would calculate total platform earnings including all fees
        Map<String, Object> report = new HashMap<>();
        report.put("period", year + "-" + month);
        report.put("totalOrders", 0);
        report.put("totalRevenue", BigDecimal.ZERO);
        report.put("totalPlatformFees", BigDecimal.ZERO);
        report.put("totalPartnerPayments", BigDecimal.ZERO);
        report.put("netEarnings", BigDecimal.ZERO);
        
        return report;
    }
}