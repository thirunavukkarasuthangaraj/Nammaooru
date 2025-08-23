package com.nammaooru.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;

import javax.mail.MessagingException;
import javax.mail.internet.MimeMessage;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;
    private final TemplateEngine templateEngine;
    
    @Value("${spring.mail.username}")
    private String fromEmail;
    
    @Value("${app.name:NammaOoru}")
    private String appName;

    // Send OTP email
    @Async
    public void sendOTPEmail(String to, String otp, String purpose) {
        try {
            String subject = getOTPSubject(purpose);
            String body = generateOTPEmailBody(otp, purpose);
            sendHtmlEmail(to, subject, body);
            log.info("OTP email sent to {} for {}", to, purpose);
        } catch (Exception e) {
            log.error("Failed to send OTP email to {}: ", to, e);
        }
    }

    // Send order confirmation email
    @Async
    public void sendOrderConfirmation(String to, String orderNumber, String customerName, String deliveryOTP) {
        try {
            String subject = String.format("Order Confirmed - #%s", orderNumber);
            Map<String, Object> variables = new HashMap<>();
            variables.put("orderNumber", orderNumber);
            variables.put("customerName", customerName);
            variables.put("deliveryOTP", deliveryOTP);
            variables.put("appName", appName);
            
            String body = generateOrderConfirmationEmail(variables);
            sendHtmlEmail(to, subject, body);
            log.info("Order confirmation sent to {} for order {}", to, orderNumber);
        } catch (Exception e) {
            log.error("Failed to send order confirmation to {}: ", to, e);
        }
    }

    // Send invoice email
    @Async
    public void sendInvoiceEmail(String to, InvoiceData invoice) {
        try {
            String subject = String.format("Invoice - Order #%s", invoice.getOrderNumber());
            String body = generateInvoiceHTML(invoice);
            sendHtmlEmail(to, subject, body);
            log.info("Invoice email sent to {} for order {}", to, invoice.getOrderNumber());
        } catch (Exception e) {
            log.error("Failed to send invoice to {}: ", to, e);
        }
    }

    // Send order status update
    @Async
    public void sendOrderStatusUpdate(String to, String orderNumber, String status, String message, String otp) {
        try {
            String subject = String.format("Order %s - %s", orderNumber, getStatusTitle(status));
            Map<String, Object> variables = new HashMap<>();
            variables.put("orderNumber", orderNumber);
            variables.put("status", status);
            variables.put("message", message);
            variables.put("otp", otp);
            
            String body = generateStatusUpdateEmail(variables);
            sendHtmlEmail(to, subject, body);
            log.info("Status update sent to {} for order {} - {}", to, orderNumber, status);
        } catch (Exception e) {
            log.error("Failed to send status update to {}: ", to, e);
        }
    }

    // Send daily summary to shop owner
    @Async
    public void sendDailySummary(String to, DailySummaryData summaryData) {
        try {
            String subject = String.format("Daily Summary - %s - %s", 
                summaryData.getShopName(), summaryData.getDate());
            String body = generateDailySummaryHTML(summaryData);
            sendHtmlEmail(to, subject, body);
            log.info("Daily summary sent to {} for shop {}", to, summaryData.getShopName());
        } catch (Exception e) {
            log.error("Failed to send daily summary to {}: ", to, e);
        }
    }

    // Send delivery notification
    @Async
    public void sendDeliveryNotification(String to, String orderNumber, String trackingUrl, String deliveryOTP) {
        try {
            String subject = String.format("Your order %s is out for delivery!", orderNumber);
            Map<String, Object> variables = new HashMap<>();
            variables.put("orderNumber", orderNumber);
            variables.put("trackingUrl", trackingUrl);
            variables.put("deliveryOTP", deliveryOTP);
            
            String body = generateDeliveryNotificationEmail(variables);
            sendHtmlEmail(to, subject, body);
            log.info("Delivery notification sent to {} for order {}", to, orderNumber);
        } catch (Exception e) {
            log.error("Failed to send delivery notification to {}: ", to, e);
        }
    }

    // Core email sending method
    private void sendHtmlEmail(String to, String subject, String htmlBody) throws MessagingException {
        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
        
        helper.setFrom(fromEmail);
        helper.setTo(to);
        helper.setSubject(subject);
        helper.setText(htmlBody, true);
        
        mailSender.send(message);
    }

    // Generate OTP email body
    private String generateOTPEmailBody(String otp, String purpose) {
        return String.format("""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: Arial, sans-serif; background: #f5f5f5; padding: 20px; }
                    .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 10px; padding: 30px; }
                    .otp-box { background: #f0f9ff; border: 2px solid #0ea5e9; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0; }
                    .otp-code { font-size: 32px; font-weight: bold; color: #0ea5e9; letter-spacing: 5px; }
                    .purpose { color: #64748b; margin-bottom: 20px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h2>%s - OTP Verification</h2>
                    <p class="purpose">%s</p>
                    <div class="otp-box">
                        <p>Your OTP code is:</p>
                        <div class="otp-code">%s</div>
                        <p style="color: #ef4444; margin-top: 15px;">This OTP is valid for 10 minutes</p>
                    </div>
                    <p style="color: #6b7280;">If you didn't request this, please ignore this email.</p>
                </div>
            </body>
            </html>
            """, appName, getPurposeMessage(purpose), otp);
    }

    // Generate order confirmation email
    private String generateOrderConfirmationEmail(Map<String, Object> variables) {
        String orderNumber = (String) variables.get("orderNumber");
        String customerName = (String) variables.get("customerName");
        String deliveryOTP = (String) variables.get("deliveryOTP");
        
        return String.format("""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: Arial, sans-serif; background: #f5f5f5; padding: 20px; }
                    .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 10px; overflow: hidden; }
                    .header { background: #10b981; color: white; padding: 30px; text-align: center; }
                    .content { padding: 30px; }
                    .otp-section { background: #f0fdf4; border-left: 4px solid #10b981; padding: 15px; margin: 20px 0; }
                    .otp-code { font-size: 24px; font-weight: bold; color: #10b981; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>Order Confirmed! ✅</h1>
                        <p>Order #%s</p>
                    </div>
                    <div class="content">
                        <p>Dear %s,</p>
                        <p>Your order has been confirmed and will be prepared soon.</p>
                        
                        <div class="otp-section">
                            <p><strong>Delivery OTP:</strong></p>
                            <div class="otp-code">%s</div>
                            <p style="color: #6b7280; font-size: 14px;">Share this OTP with delivery partner upon delivery</p>
                        </div>
                        
                        <p>You will receive updates as your order progresses.</p>
                        <p>Thank you for ordering with %s!</p>
                    </div>
                </div>
            </body>
            </html>
            """, orderNumber, customerName, deliveryOTP, appName);
    }

    // Generate invoice HTML
    private String generateInvoiceHTML(InvoiceData invoice) {
        StringBuilder itemsHtml = new StringBuilder();
        for (InvoiceItem item : invoice.getItems()) {
            itemsHtml.append(String.format("""
                <tr>
                    <td>%s</td>
                    <td>%d %s</td>
                    <td>₹%.2f</td>
                    <td>₹%.2f</td>
                </tr>
                """, item.getProductName(), item.getQuantity(), item.getUnit(), 
                item.getPrice(), item.getTotal()));
        }
        
        return String.format("""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: Arial, sans-serif; }
                    .invoice { max-width: 800px; margin: 0 auto; padding: 20px; }
                    .header { background: #2563eb; color: white; padding: 20px; text-align: center; }
                    table { width: 100%%; border-collapse: collapse; margin: 20px 0; }
                    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
                    th { background: #f8f9fa; }
                    .total { font-size: 20px; font-weight: bold; color: #10b981; }
                </style>
            </head>
            <body>
                <div class="invoice">
                    <div class="header">
                        <h1>%s - Invoice</h1>
                        <p>Order #%s</p>
                    </div>
                    <p><strong>Date:</strong> %s</p>
                    <p><strong>Customer:</strong> %s</p>
                    <p><strong>Delivery Address:</strong> %s</p>
                    
                    <table>
                        <thead>
                            <tr>
                                <th>Item</th>
                                <th>Quantity</th>
                                <th>Price</th>
                                <th>Total</th>
                            </tr>
                        </thead>
                        <tbody>%s</tbody>
                    </table>
                    
                    <div style="text-align: right;">
                        <p>Subtotal: ₹%.2f</p>
                        <p>Delivery Fee: ₹%.2f</p>
                        %s
                        <p class="total">Total: ₹%.2f</p>
                    </div>
                    
                    <p style="text-align: center; color: #6b7280; margin-top: 40px;">
                        Thank you for your order!
                    </p>
                </div>
            </body>
            </html>
            """, appName, invoice.getOrderNumber(), 
            invoice.getOrderDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")),
            invoice.getCustomerName(), invoice.getDeliveryAddress(),
            itemsHtml.toString(), invoice.getSubtotal(), invoice.getDeliveryFee(),
            invoice.getDiscount().compareTo(BigDecimal.ZERO) > 0 ? 
                String.format("<p style='color: #10b981;'>Discount: -₹%.2f</p>", invoice.getDiscount()) : "",
            invoice.getTotal());
    }

    // Generate daily summary HTML
    private String generateDailySummaryHTML(DailySummaryData data) {
        // Generate top items HTML
        StringBuilder topItemsHtml = new StringBuilder();
        for (TopSellingItem item : data.getTopSellingItems()) {
            topItemsHtml.append(String.format("""
                <tr>
                    <td>%s</td>
                    <td>%d</td>
                    <td>₹%.2f</td>
                </tr>
                """, item.getName(), item.getQuantity(), item.getRevenue()));
        }
        
        return String.format("""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: Arial, sans-serif; background: #f5f5f5; }
                    .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; }
                    .header { background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%); color: white; padding: 30px; text-align: center; }
                    .stats-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; margin: 20px 0; }
                    .stat-card { background: #f8fafc; padding: 20px; border-radius: 8px; }
                    .profit-section { background: #f0fdf4; padding: 20px; border-radius: 8px; border-left: 4px solid #10b981; }
                    .profit-value { font-size: 32px; font-weight: bold; color: #10b981; }
                    table { width: 100%%; border-collapse: collapse; margin: 20px 0; }
                    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #e5e7eb; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>Daily Business Summary</h1>
                        <h2>%s</h2>
                        <p>%s</p>
                    </div>
                    
                    <div class="stats-grid">
                        <div class="stat-card">
                            <h3>%d</h3>
                            <p>Total Orders</p>
                        </div>
                        <div class="stat-card">
                            <h3>₹%.2f</h3>
                            <p>Total Revenue</p>
                        </div>
                        <div class="stat-card">
                            <h3>%d</h3>
                            <p>Completed Orders</p>
                        </div>
                        <div class="stat-card">
                            <h3>₹%.2f</h3>
                            <p>Average Order Value</p>
                        </div>
                    </div>
                    
                    <div class="profit-section">
                        <h3>Today's Profit</h3>
                        <div class="profit-value">₹%.2f</div>
                        <p>Profit Margin: %.1f%%</p>
                    </div>
                    
                    <h3>Top Selling Items</h3>
                    <table>
                        <thead>
                            <tr>
                                <th>Item</th>
                                <th>Quantity</th>
                                <th>Revenue</th>
                            </tr>
                        </thead>
                        <tbody>%s</tbody>
                    </table>
                    
                    <p style="text-align: center; color: #6b7280; margin-top: 40px;">
                        This is an automated daily summary from %s
                    </p>
                </div>
            </body>
            </html>
            """, data.getShopName(), data.getDate(), data.getTotalOrders(),
            data.getTotalRevenue(), data.getCompletedOrders(), 
            data.getAverageOrderValue(), data.getTotalProfit(),
            data.getProfitMargin(), topItemsHtml.toString(), appName);
    }

    // Helper methods
    private String getOTPSubject(String purpose) {
        return switch (purpose) {
            case "LOGIN" -> "Login OTP";
            case "SIGNUP" -> "Sign Up OTP";
            case "RESET_PASSWORD" -> "Password Reset OTP";
            case "ORDER_PICKUP" -> "Order Pickup OTP";
            case "ORDER_DELIVERY" -> "Order Delivery OTP";
            default -> "Verification OTP";
        };
    }

    private String getPurposeMessage(String purpose) {
        return switch (purpose) {
            case "LOGIN" -> "Use this OTP to login to your account";
            case "SIGNUP" -> "Use this OTP to complete your registration";
            case "RESET_PASSWORD" -> "Use this OTP to reset your password";
            case "ORDER_PICKUP" -> "Share this OTP with delivery partner for order pickup";
            case "ORDER_DELIVERY" -> "Share this OTP with delivery partner upon delivery";
            default -> "Use this OTP for verification";
        };
    }

    private String getStatusTitle(String status) {
        return switch (status) {
            case "CONFIRMED" -> "Order Confirmed";
            case "PREPARING" -> "Order Being Prepared";
            case "READY_FOR_PICKUP" -> "Ready for Pickup";
            case "OUT_FOR_DELIVERY" -> "Out for Delivery";
            case "DELIVERED" -> "Delivered Successfully";
            case "CANCELLED" -> "Order Cancelled";
            default -> "Order Update";
        };
    }

    private String generateStatusUpdateEmail(Map<String, Object> variables) {
        // Implementation for status update email
        return ""; // Simplified for brevity
    }

    private String generateDeliveryNotificationEmail(Map<String, Object> variables) {
        // Implementation for delivery notification email
        return ""; // Simplified for brevity
    }
}

// Data classes
@lombok.Data
@lombok.Builder
class InvoiceData {
    private String orderNumber;
    private String customerName;
    private String customerEmail;
    private String shopName;
    private List<InvoiceItem> items;
    private BigDecimal subtotal;
    private BigDecimal deliveryFee;
    private BigDecimal discount;
    private BigDecimal total;
    private String deliveryAddress;
    private LocalDateTime orderDate;
    private LocalDateTime deliveryDate;
}

@lombok.Data
class InvoiceItem {
    private String productName;
    private Integer quantity;
    private BigDecimal price;
    private String unit;
    private BigDecimal total;
}

@lombok.Data
@lombok.Builder
class DailySummaryData {
    private Long shopId;
    private String shopName;
    private String shopOwnerEmail;
    private String date;
    private Integer totalOrders;
    private Integer completedOrders;
    private Integer cancelledOrders;
    private Integer pendingOrders;
    private BigDecimal totalRevenue;
    private BigDecimal totalCost;
    private BigDecimal totalProfit;
    private BigDecimal profitMargin;
    private List<TopSellingItem> topSellingItems;
    private List<OrderDetail> orderDetails;
    private BigDecimal averageOrderValue;
    private String peakHours;
}

@lombok.Data
class TopSellingItem {
    private String name;
    private Integer quantity;
    private BigDecimal revenue;
}

@lombok.Data
class OrderDetail {
    private String orderNumber;
    private String customerName;
    private String items;
    private BigDecimal total;
    private String status;
    private String time;
}