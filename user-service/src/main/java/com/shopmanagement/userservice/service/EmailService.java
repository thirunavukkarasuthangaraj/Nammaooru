package com.shopmanagement.userservice.service;

import com.shopmanagement.userservice.config.EmailProperties;
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

    @Value("${app.frontend.auth.login-url:http://localhost:3000/auth/login}")
    private String loginUrl;

    @Value("${app.frontend.auth.reset-password-url:http://localhost:3000/auth/reset-password}")
    private String resetPasswordUrl;

    @Value("${app.frontend.base-url:http://localhost:3000}")
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
        }
    }

    @Async
    public void sendHtmlEmail(String to, String subject, String templateName, Map<String, Object> variables) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, true, "UTF-8");

            helper.setFrom(emailProperties.getFrom(), emailProperties.getFromName());
            helper.setTo(to);
            helper.setSubject(subject);

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
        } catch (Exception e) {
            log.error("Unexpected error sending email to: {}", to, e);
        }
    }

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

    public void sendPasswordResetEmail(String to, String username, String resetToken) {
        try {
            Map<String, Object> variables = Map.of(
                "username", username,
                "resetToken", resetToken,
                "resetUrl", resetPasswordUrl + "?token=" + resetToken,
                "expirationMinutes", "30",
                "supportEmail", emailProperties.getFrom()
            );

            String subject = emailProperties.getSubject() != null ?
                    emailProperties.getSubject().getOrDefault("password-reset", "Password Reset - NammaOoru") :
                    "Password Reset - NammaOoru";
            String templateName = emailProperties.getTemplates() != null ?
                    emailProperties.getTemplates().getOrDefault("password-reset", "password-reset") :
                    "password-reset";

            sendHtmlEmail(to, subject, templateName, variables);
            log.info("Password reset email sent to: {}", to);
        } catch (Exception e) {
            log.error("Failed to send password reset email to: {}", to, e);
            throw new RuntimeException("Failed to send password reset email", e);
        }
    }

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
            log.info("OTP verification email sent to: {}", to);
        } catch (Exception e) {
            log.error("Failed to send OTP verification email to: {}", to, e);
            throw new RuntimeException("Failed to send OTP verification email", e);
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

            String subject = emailProperties.getSubject() != null ?
                    emailProperties.getSubject().getOrDefault("welcome", "Welcome to NammaOoru!") :
                    "Welcome to NammaOoru!";
            String templateName = emailProperties.getTemplates() != null ?
                    emailProperties.getTemplates().getOrDefault("welcome", "welcome") :
                    "welcome";

            sendHtmlEmail(to, subject, templateName, variables);
            log.info("Shop owner welcome email sent to: {} for shop: {}", to, shopName);
        } catch (Exception e) {
            log.error("Failed to send welcome email to shop owner: {}", to, e);
            throw new RuntimeException("Failed to send welcome email", e);
        }
    }

    public void sendTestEmail(String to) {
        sendSimpleEmail(to, "NammaOoru - Test Email",
            "This is a test email from NammaOoru User Service. " +
            "If you received this email, the email configuration is working correctly!");
    }
}
