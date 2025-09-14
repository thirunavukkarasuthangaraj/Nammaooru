package com.shopmanagement.service;

import com.shopmanagement.config.EmailProperties;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;

import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;
    private final EmailProperties emailProperties;
    private final TemplateEngine templateEngine;
    
    @Value("${app.frontend.auth.login-url}")
    private String loginUrl;
    
    @Value("${app.frontend.auth.reset-password-url}")
    private String resetPasswordUrl;
    
    @Value("${app.frontend.shop-owner.dashboard-url}")
    private String dashboardUrl;
    
    @Value("${app.frontend.urls.shops}")
    private String shopsUrl;
    
    @Value("${app.frontend.urls.contact}")
    private String contactUrl;
    
    @Value("${app.frontend.urls.unsubscribe}")
    private String unsubscribeUrl;
    
    @Value("${app.frontend.base-url}")
    private String frontendBaseUrl;

    @Async
    public void sendPasswordResetOtpEmail(String to, String username, String otp) {
        try {
            Map<String, Object> variables = Map.of(
                "userName", username != null ? username : "User",
                "otpCode", otp,
                "expirationMinutes", "10",
                "resetUrl", frontendBaseUrl + "/auth/forgot-password",
                "supportEmail", emailProperties.getFrom(),
                "companyName", "NammaOoru"
            );
            
            String subject = "Password Reset OTP - NammaOoru";
            sendHtmlEmail(to, subject, "forgot-password-otp", variables);
            log.info("Password reset OTP email sent to: {}", to);
            
        } catch (Exception e) {
            log.error("Failed to send password reset OTP email to: {}", to, e);
            throw new RuntimeException("Failed to send OTP email", e);
        }
    }

    @Async
    public void sendSimpleEmail(String to, String subject, String text) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(emailProperties.getFrom());
            message.setTo(to);
            message.setSubject(subject);
            message.setText(text);
            
            mailSender.send(message);
            log.info("Simple email sent successfully to: {}", to);
        } catch (Exception e) {
            log.error("Failed to send simple email to: {}", to, e);
            // Don't throw exception - just log the error
        }
    }

    @Async
    public void sendHtmlEmail(String to, String subject, String templateName, Map<String, Object> variables) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, true, "UTF-8");
            
            // Set email properties
            helper.setFrom(emailProperties.getFrom(), emailProperties.getFromName());
            helper.setTo(to);
            helper.setSubject(subject);
            
            // Process template
            Context context = new Context();
            if (variables != null) {
                variables.forEach(context::setVariable);
            }
            
            String htmlContent = templateEngine.process(templateName, context);
            helper.setText(htmlContent, true);
            
            mailSender.send(mimeMessage);
            log.info("HTML email sent successfully to: {} using template: {}", to, templateName);
        } catch (MessagingException e) {
            log.error("Failed to send HTML email to: {} using template: {}", to, templateName, e);
            // Don't throw exception - just log the error
        } catch (Exception e) {
            log.error("Unexpected error sending email to: {}", to, e);
            // Don't throw exception - just log the error
        }
    }

    public void sendShopOwnerWelcomeEmail(String to, String shopOwnerName, String username, String temporaryPassword, String shopName) {
        try {
            Map<String, Object> variables = Map.of(
                "shopOwnerName", shopOwnerName,
                "username", username,
                "temporaryPassword", temporaryPassword,
                "shopName", shopName,
                "loginUrl", loginUrl,
                "supportEmail", emailProperties.getFrom()
            );
            
            String subject = emailProperties.getSubject().get("welcome");
            String templateName = emailProperties.getTemplates().get("welcome");
            
            sendHtmlEmail(to, subject, templateName, variables);
            log.info("Shop owner welcome email sent to: {} for shop: {}", to, shopName);
        } catch (Exception e) {
            log.error("Failed to send welcome email to shop owner: {}", to, e);
            throw new RuntimeException("Failed to send welcome email", e);
        }
    }

    public void sendPasswordResetEmail(String to, String username, String resetToken) {
        try {
            Map<String, Object> variables = Map.of(
                "username", username,
                "resetToken", resetToken,
                "resetUrl", resetPasswordUrl + "?token=" + resetToken,
                "expirationMinutes", "30",
                "supportEmail", emailProperties.getFrom()
            );
            
            String subject = emailProperties.getSubject().get("password-reset");
            String templateName = emailProperties.getTemplates().get("password-reset");
            
            sendHtmlEmail(to, subject, templateName, variables);
            log.info("Password reset email sent to: {}", to);
        } catch (Exception e) {
            log.error("Failed to send password reset email to: {}", to, e);
            throw new RuntimeException("Failed to send password reset email", e);
        }
    }

    public void sendShopApprovalEmail(String to, String shopOwnerName, String shopName, String status) {
        try {
            Map<String, Object> variables = Map.of(
                "shopOwnerName", shopOwnerName,
                "shopName", shopName,
                "status", status,
                "loginUrl", loginUrl,
                "dashboardUrl", dashboardUrl,
                "supportEmail", emailProperties.getFrom()
            );
            
            String subject = emailProperties.getSubject().get("shop-approval");
            String templateName = emailProperties.getTemplates().get("shop-approval");
            
            sendHtmlEmail(to, subject, templateName, variables);
            log.info("Shop approval email sent to: {} for shop: {} with status: {}", to, shopName, status);
        } catch (Exception e) {
            log.error("Failed to send shop approval email to: {}", to, e);
            throw new RuntimeException("Failed to send shop approval email", e);
        }
    }

    public void sendShopRegistrationConfirmationEmail(String to, String shopOwnerName, String shopName, String shopId) {
        try {
            Map<String, Object> variables = Map.of(
                "shopOwnerName", shopOwnerName,
                "shopName", shopName,
                "shopId", shopId,
                "dashboardUrl", dashboardUrl,
                "supportEmail", emailProperties.getFrom(),
                "companyName", "NammaOoru"
            );
            
            String subject = "Shop Registration Received - " + shopName;
            sendHtmlEmail(to, subject, "shop-registration-confirmation", variables);
            log.info("Shop registration confirmation email sent to: {} for shop: {}", to, shopName);
        } catch (Exception e) {
            log.error("Failed to send shop registration confirmation email to: {} for shop: {}", to, shopName, e);
            throw new RuntimeException("Failed to send shop registration confirmation email", e);
        }
    }

    public void sendTestEmail(String to) {
        sendSimpleEmail(to, "NammaOoru - Test Email", 
            "This is a test email from NammaOoru Shop Management System. " +
            "If you received this email, the email configuration is working correctly!");
    }

    // Customer-specific email methods
    public void sendCustomerWelcomeEmail(String to, String customerName, String referralCode) {
        try {
            Map<String, Object> variables = Map.of(
                "customerName", customerName,
                "referralCode", referralCode,
                "loginUrl", loginUrl,
                "shopUrl", shopsUrl,
                "supportEmail", emailProperties.getFrom(),
                "companyName", "NammaOoru"
            );
            
            String subject = "Welcome to NammaOoru - Your Account is Ready!";
            sendHtmlEmail(to, subject, "customer-welcome", variables);
            log.info("Customer welcome email sent to: {}", to);
        } catch (Exception e) {
            log.error("Failed to send customer welcome email to: {}", to, e);
            throw new RuntimeException("Failed to send customer welcome email", e);
        }
    }

    public void sendEmailVerificationEmail(String to, String customerName, String verificationToken) {
        try {
            Map<String, Object> variables = Map.of(
                "customerName", customerName,
                "verificationToken", verificationToken,
                "verificationUrl", frontendBaseUrl + "/verify-email?token=" + verificationToken,
                "expirationHours", "24",
                "supportEmail", emailProperties.getFrom(),
                "companyName", "NammaOoru"
            );
            
            String subject = "Please verify your email address - NammaOoru";
            sendHtmlEmail(to, subject, "email-verification", variables);
            log.info("Email verification email sent to: {}", to);
        } catch (Exception e) {
            log.error("Failed to send email verification email to: {}", to, e);
            throw new RuntimeException("Failed to send email verification email", e);
        }
    }

    public void sendOrderConfirmationEmail(String to, String customerName, String orderId, Double orderAmount, String orderDate) {
        try {
            Map<String, Object> variables = Map.of(
                "customerName", customerName,
                "orderId", orderId,
                "orderAmount", String.format("₹%.2f", orderAmount),
                "orderDate", orderDate,
                "trackingUrl", frontendBaseUrl + "/orders/" + orderId,
                "supportEmail", emailProperties.getFrom(),
                "companyName", "NammaOoru"
            );
            
            String subject = "Order Confirmed #" + orderId + " - NammaOoru";
            sendHtmlEmail(to, subject, "order-confirmation", variables);
            log.info("Order confirmation email sent to: {} for order: {}", to, orderId);
        } catch (Exception e) {
            log.error("Failed to send order confirmation email to: {} for order: {}", to, orderId, e);
            throw new RuntimeException("Failed to send order confirmation email", e);
        }
    }

    public void sendOrderStatusUpdateEmail(String to, String customerName, String orderId, String oldStatus, String newStatus) {
        try {
            Map<String, Object> variables = Map.of(
                "customerName", customerName,
                "orderId", orderId,
                "oldStatus", oldStatus,
                "newStatus", newStatus,
                "trackingUrl", frontendBaseUrl + "/orders/" + orderId,
                "supportEmail", emailProperties.getFrom(),
                "companyName", "NammaOoru"
            );
            
            String subject = "Order Update #" + orderId + " - " + newStatus + " - NammaOoru";
            sendHtmlEmail(to, subject, "order-status-update", variables);
            log.info("Order status update email sent to: {} for order: {} (status: {})", to, orderId, newStatus);
        } catch (Exception e) {
            log.error("Failed to send order status update email to: {} for order: {}", to, orderId, e);
            throw new RuntimeException("Failed to send order status update email", e);
        }
    }

    public void sendPromotionalEmail(String to, String customerName, String promoTitle, String promoDescription, String promoCode, String validUntil) {
        try {
            Map<String, Object> variables = Map.of(
                "customerName", customerName,
                "promoTitle", promoTitle,
                "promoDescription", promoDescription,
                "promoCode", promoCode,
                "validUntil", validUntil,
                "shopUrl", shopsUrl,
                "unsubscribeUrl", unsubscribeUrl,
                "supportEmail", emailProperties.getFrom(),
                "companyName", "NammaOoru"
            );
            
            String subject = promoTitle + " - Special Offer from NammaOoru";
            sendHtmlEmail(to, subject, "promotional-offer", variables);
            log.info("Promotional email sent to: {} with promo: {}", to, promoTitle);
        } catch (Exception e) {
            log.error("Failed to send promotional email to: {}", to, e);
            throw new RuntimeException("Failed to send promotional email", e);
        }
    }

    public void sendAccountStatusUpdateEmail(String to, String customerName, String oldStatus, String newStatus, String reason) {
        try {
            Map<String, Object> variables = Map.of(
                "customerName", customerName,
                "oldStatus", oldStatus,
                "newStatus", newStatus,
                "reason", reason != null ? reason : "Administrative action",
                "contactUrl", contactUrl,
                "supportEmail", emailProperties.getFrom(),
                "companyName", "NammaOoru"
            );
            
            String subject = "Account Status Update - NammaOoru";
            sendHtmlEmail(to, subject, "account-status-update", variables);
            log.info("Account status update email sent to: {} (status: {})", to, newStatus);
        } catch (Exception e) {
            log.error("Failed to send account status update email to: {}", to, e);
            throw new RuntimeException("Failed to send account status update email", e);
        }
    }

    public void sendPasswordResetCustomerEmail(String to, String customerName, String resetToken) {
        try {
            Map<String, Object> variables = Map.of(
                "customerName", customerName,
                "resetToken", resetToken,
                "resetUrl", resetPasswordUrl + "?token=" + resetToken,
                "expirationMinutes", "30",
                "supportEmail", emailProperties.getFrom(),
                "companyName", "NammaOoru"
            );
            
            String subject = "Reset Your Password - NammaOoru";
            sendHtmlEmail(to, subject, "customer-password-reset", variables);
            log.info("Customer password reset email sent to: {}", to);
        } catch (Exception e) {
            log.error("Failed to send customer password reset email to: {}", to, e);
            throw new RuntimeException("Failed to send customer password reset email", e);
        }
    }

    public void sendBulkCustomerNotification(java.util.List<String> emailList, String subject, String message, String notificationType) {
        log.info("Sending bulk notification to {} customers", emailList.size());
        
        for (String email : emailList) {
            try {
                if ("HTML".equalsIgnoreCase(notificationType)) {
                    Map<String, Object> variables = Map.of(
                        "message", message,
                        "subject", subject,
                        "supportEmail", emailProperties.getFrom(),
                        "companyName", "NammaOoru"
                    );
                    sendHtmlEmail(email, subject, "bulk-notification", variables);
                } else {
                    sendSimpleEmail(email, subject, message);
                }
                
                // Add small delay to avoid overwhelming the email server
                Thread.sleep(100);
            } catch (Exception e) {
                log.error("Failed to send bulk notification to: {}", email, e);
                // Continue with other emails even if one fails
            }
        }
        
        log.info("Bulk notification completed for {} customers", emailList.size());
    }

    public void sendNewsletterEmail(String to, String customerName, String newsletterTitle, String newsletterContent) {
        try {
            Map<String, Object> variables = Map.of(
                "customerName", customerName,
                "newsletterTitle", newsletterTitle,
                "newsletterContent", newsletterContent,
                "websiteUrl", frontendBaseUrl,
                "unsubscribeUrl", unsubscribeUrl,
                "supportEmail", emailProperties.getFrom(),
                "companyName", "NammaOoru"
            );
            
            String subject = newsletterTitle + " - NammaOoru Newsletter";
            sendHtmlEmail(to, subject, "newsletter", variables);
            log.info("Newsletter email sent to: {}", to);
        } catch (Exception e) {
            log.error("Failed to send newsletter email to: {}", to, e);
            throw new RuntimeException("Failed to send newsletter email", e);
        }
    }

    public void sendCustomerSurveyEmail(String to, String customerName, String surveyTitle, String surveyUrl) {
        try {
            Map<String, Object> variables = Map.of(
                "customerName", customerName,
                "surveyTitle", surveyTitle,
                "surveyUrl", surveyUrl,
                "incentiveText", "Complete the survey and get 10% off your next order!",
                "supportEmail", emailProperties.getFrom(),
                "companyName", "NammaOoru"
            );
            
            String subject = "We'd love your feedback - " + surveyTitle;
            sendHtmlEmail(to, subject, "customer-survey", variables);
            log.info("Customer survey email sent to: {}", to);
        } catch (Exception e) {
            log.error("Failed to send customer survey email to: {}", to, e);
            throw new RuntimeException("Failed to send customer survey email", e);
        }
    }

    // User management email methods
    public void sendWelcomeEmail(String to, String fullName, String username, String password) {
        try {
            Map<String, Object> variables = Map.of(
                "fullName", fullName,
                "username", username,
                "email", to,
                "password", password,
                "loginUrl", loginUrl,
                "supportEmail", emailProperties.getFrom(),
                "companyName", "NammaOoru"
            );
            
            String subject = "Welcome to NammaOoru - Your Account is Ready!";
            sendHtmlEmail(to, subject, "user-welcome", variables);
            log.info("Welcome email sent to user: {}", username);
        } catch (Exception e) {
            log.error("Failed to send welcome email to user: {}", username, e);
            throw new RuntimeException("Failed to send welcome email", e);
        }
    }

    // Order notification methods
    public void sendOrderPlacedNotificationToShop(String shopOwnerEmail, String shopOwnerName, String orderNumber, 
                                                   String customerName, String totalAmount, String items) {
        try {
            Map<String, Object> variables = Map.of(
                "shopOwnerName", shopOwnerName,
                "orderNumber", orderNumber,
                "customerName", customerName,
                "totalAmount", totalAmount,
                "items", items,
                "dashboardUrl", dashboardUrl,
                "supportEmail", emailProperties.getFrom()
            );
            
            String subject = "New Order Received - Order #" + orderNumber;
            sendHtmlEmail(shopOwnerEmail, subject, "order-notification-shop", variables);
            log.info("Order notification sent to shop owner: {} for order: {}", shopOwnerEmail, orderNumber);
        } catch (Exception e) {
            log.error("Failed to send order notification to shop owner: {} for order: {}", shopOwnerEmail, orderNumber, e);
        }
    }

    public void sendOrderConfirmationToCustomer(String customerEmail, String customerName, String orderNumber, 
                                                 String totalAmount, String items, String estimatedDelivery) {
        try {
            Map<String, Object> variables = Map.of(
                "customerName", customerName,
                "orderNumber", orderNumber,
                "totalAmount", totalAmount,
                "items", items,
                "estimatedDelivery", estimatedDelivery,
                "supportEmail", emailProperties.getFrom()
            );
            
            String subject = "Order Confirmation - Order #" + orderNumber;
            sendHtmlEmail(customerEmail, subject, "order-confirmation-customer", variables);
            log.info("Order confirmation sent to customer: {} for order: {}", customerEmail, orderNumber);
        } catch (Exception e) {
            log.error("Failed to send order confirmation to customer: {} for order: {}", customerEmail, orderNumber, e);
        }
    }

    public void sendOrderStatusUpdateToCustomer(String customerEmail, String customerName, String orderNumber, 
                                                 String oldStatus, String newStatus, String trackingUrl) {
        try {
            Map<String, Object> variables = Map.of(
                "customerName", customerName,
                "orderNumber", orderNumber,
                "oldStatus", oldStatus,
                "newStatus", newStatus,
                "trackingUrl", trackingUrl,
                "supportEmail", emailProperties.getFrom()
            );
            
            String subject = "Order Update - Order #" + orderNumber + " is " + newStatus;
            sendHtmlEmail(customerEmail, subject, "order-status-update", variables);
            log.info("Order status update sent to customer: {} for order: {} - {}", customerEmail, orderNumber, newStatus);
        } catch (Exception e) {
            log.error("Failed to send order status update to customer: {} for order: {}", customerEmail, orderNumber, e);
        }
    }

    public void sendOrderAcceptedNotification(String customerEmail, String customerName, String orderNumber,
                                              String shopName, String paymentMethod, Double totalAmount,
                                              String estimatedDeliveryTime, String shopNotes,
                                              java.util.List<java.util.Map<String, Object>> orderItems,
                                              java.util.Map<String, Object> deliveryAddress,
                                              String deliveryInstructions, Double subtotal,
                                              Double taxAmount, Double deliveryFee, Double discountAmount) {
        try {
            java.util.Map<String, Object> variables = new java.util.HashMap<>();
            variables.put("customerName", customerName);
            variables.put("orderNumber", orderNumber);
            variables.put("shopName", shopName);
            variables.put("paymentMethod", paymentMethod);
            variables.put("totalAmount", totalAmount);
            variables.put("subtotal", subtotal != null ? subtotal : totalAmount);
            variables.put("taxAmount", taxAmount != null ? taxAmount : 0.0);
            variables.put("deliveryFee", deliveryFee != null ? deliveryFee : 0.0);
            variables.put("discountAmount", discountAmount != null ? discountAmount : 0.0);
            variables.put("orderItems", orderItems);
            variables.put("deliveryAddress", deliveryAddress);
            variables.put("deliveryInstructions", deliveryInstructions);
            variables.put("shopNotes", shopNotes);
            variables.put("supportEmail", emailProperties.getFrom());
            variables.put("trackingUrl", "#"); // Will be updated with actual tracking URL later
            
            // Parse estimated delivery time if provided
            if (estimatedDeliveryTime != null && !estimatedDeliveryTime.trim().isEmpty()) {
                try {
                    int minutes = Integer.parseInt(estimatedDeliveryTime.trim());
                    java.time.LocalDateTime estimatedTime = java.time.LocalDateTime.now().plusMinutes(minutes);
                    variables.put("estimatedDeliveryTime", estimatedTime);
                } catch (NumberFormatException e) {
                    log.warn("Invalid estimated delivery time format: {}", estimatedDeliveryTime);
                }
            }
            
            String subject = "🎉 Order Accepted - Order #" + orderNumber + " from " + shopName;
            sendHtmlEmail(customerEmail, subject, "order-accepted", variables);
            log.info("Order acceptance notification sent to customer: {} for order: {}", customerEmail, orderNumber);
        } catch (Exception e) {
            log.error("Failed to send order acceptance notification to customer: {} for order: {}", customerEmail, orderNumber, e);
        }
    }

    public void sendDeliveryAssignmentNotification(String partnerEmail, String partnerName, String orderNumber, 
                                                    String shopName, String customerAddress, String customerPhone) {
        try {
            Map<String, Object> variables = Map.of(
                "partnerName", partnerName,
                "orderNumber", orderNumber,
                "shopName", shopName,
                "customerAddress", customerAddress,
                "customerPhone", customerPhone,
                "supportEmail", emailProperties.getFrom()
            );
            
            String subject = "New Delivery Assignment - Order #" + orderNumber;
            sendHtmlEmail(partnerEmail, subject, "delivery-assignment", variables);
            log.info("Delivery assignment notification sent to partner: {} for order: {}", partnerEmail, orderNumber);
        } catch (Exception e) {
            log.error("Failed to send delivery assignment notification to partner: {} for order: {}", partnerEmail, orderNumber, e);
        }
    }

    public void sendInvoiceEmail(String to, String customerName, String orderNumber, Map<String, Object> invoiceData) {
        try {
            // Add common email variables
            invoiceData.put("customerName", customerName);
            invoiceData.put("orderNumber", orderNumber);
            invoiceData.put("supportEmail", emailProperties.getFrom());
            invoiceData.put("companyName", "NammaOoru");
            
            String subject = "Order Invoice #" + orderNumber + " - NammaOoru";
            sendHtmlEmail(to, subject, "order-invoice", invoiceData);
            log.info("Invoice email sent to: {} for order: {}", to, orderNumber);
        } catch (Exception e) {
            log.error("Failed to send invoice email to: {} for order: {}", to, orderNumber, e);
            throw new RuntimeException("Failed to send invoice email", e);
        }
    }

    // OTP Verification Email
    public void sendOtpVerificationEmail(String to, String userName, String otpCode) {
        try {
            Map<String, Object> variables = Map.of(
                "userName", userName != null ? userName : "User",
                "otpCode", otpCode,
                "expirationMinutes", "5",
                "supportEmail", emailProperties.getFrom(),
                "companyName", "NammaOoru"
            );
            
            String subject = "NammaOoru - Verify Your Account";
            sendHtmlEmail(to, subject, "otp-verification", variables);
            log.info("OTP verification email sent to: {} with code: {}", to, otpCode);
        } catch (Exception e) {
            log.error("Failed to send OTP verification email to: {}", to, e);
            throw new RuntimeException("Failed to send OTP verification email", e);
        }
    }

}