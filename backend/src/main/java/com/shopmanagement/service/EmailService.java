package com.shopmanagement.service;

import com.shopmanagement.config.EmailProperties;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
            throw new RuntimeException("Failed to send email", e);
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
            throw new RuntimeException("Failed to send HTML email", e);
        } catch (Exception e) {
            log.error("Unexpected error sending email to: {}", to, e);
            throw new RuntimeException("Failed to send email", e);
        }
    }

    public void sendShopOwnerWelcomeEmail(String to, String shopOwnerName, String username, String temporaryPassword, String shopName) {
        try {
            Map<String, Object> variables = Map.of(
                "shopOwnerName", shopOwnerName,
                "username", username,
                "temporaryPassword", temporaryPassword,
                "shopName", shopName,
                "loginUrl", "http://localhost:4200/auth/login",
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
                "resetUrl", "http://localhost:4200/auth/reset-password?token=" + resetToken,
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
                "loginUrl", "http://localhost:4200/auth/login",
                "dashboardUrl", "http://localhost:4200/shop-owner",
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

    public void sendTestEmail(String to) {
        sendSimpleEmail(to, "NammaOoru - Test Email", 
            "This is a test email from NammaOoru Shop Management System. " +
            "If you received this email, the email configuration is working correctly!");
    }
}