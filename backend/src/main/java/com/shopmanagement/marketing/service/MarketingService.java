package com.shopmanagement.marketing.service;

import com.shopmanagement.entity.Customer;
import com.shopmanagement.marketing.dto.MarketingMessageRequest;
import com.shopmanagement.marketing.dto.MarketingMessageResponse;
import com.shopmanagement.marketing.dto.TemplateInfo;
import com.shopmanagement.repository.CustomerRepository;
import com.shopmanagement.service.WhatsAppNotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Service for managing marketing messages via WhatsApp
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class MarketingService {

    private final CustomerRepository customerRepository;
    private final WhatsAppNotificationService whatsAppNotificationService;

    /**
     * Send bulk marketing messages to customers
     */
    public MarketingMessageResponse sendBulkMarketingMessage(MarketingMessageRequest request) {
        log.info("Starting bulk marketing message send: template={}, audience={}",
                 request.getTemplateName(), request.getTargetAudience());

        try {
            // Get target customers
            List<Customer> targetCustomers = getTargetCustomers(request.getTargetAudience());

            if (targetCustomers.isEmpty()) {
                return MarketingMessageResponse.builder()
                        .success(false)
                        .message("No customers found for the selected audience")
                        .totalCustomers(0)
                        .successCount(0)
                        .failureCount(0)
                        .templateUsed(request.getTemplateName())
                        .messageParam(request.getMessageParam())
                        .build();
            }

            // Send messages to each customer
            int successCount = 0;
            int failureCount = 0;

            for (Customer customer : targetCustomers) {
                try {
                    // Check if customer has a valid mobile number
                    if (customer.getMobileNumber() == null || customer.getMobileNumber().trim().isEmpty()) {
                        log.warn("Customer {} has no mobile number, skipping", customer.getId());
                        failureCount++;
                        continue;
                    }

                    // Prepare template data
                    Map<String, Object> templateData = new HashMap<>();

                    // For marketingmsg template, we need image header + 2 text parameters
                    if ("marketingmsg".equals(request.getTemplateName())) {
                        // Add image header from request
                        if (request.getImageUrl() != null && !request.getImageUrl().trim().isEmpty()) {
                            templateData.put("header_image", request.getImageUrl());
                        } else {
                            log.warn("marketingmsg template requires image URL, using default");
                            templateData.put("header_image", "https://picsum.photos/600/400");
                        }

                        // Add both message parameters
                        templateData.put("param1", request.getMessageParam());

                        if (request.getMessageParam2() != null && !request.getMessageParam2().trim().isEmpty()) {
                            templateData.put("param2", request.getMessageParam2());
                        } else {
                            log.warn("marketingmsg template requires 2 parameters, second parameter is missing");
                        }
                    } else {
                        // For other templates (like test), just send the message param
                        templateData.put("param1", request.getMessageParam());
                    }

                    // Send WhatsApp message
                    boolean sent = sendMarketingMessage(
                            customer.getMobileNumber(),
                            request.getTemplateName(),
                            templateData
                    );

                    if (sent) {
                        successCount++;
                        log.debug("Message sent successfully to customer {}", customer.getId());
                    } else {
                        failureCount++;
                        log.warn("Failed to send message to customer {}", customer.getId());
                    }

                    // Add a small delay to avoid rate limiting (100ms between messages)
                    Thread.sleep(100);

                } catch (Exception e) {
                    log.error("Error sending message to customer {}", customer.getId(), e);
                    failureCount++;
                }
            }

            String resultMessage = String.format(
                    "Marketing messages sent: %d successful, %d failed out of %d total customers",
                    successCount, failureCount, targetCustomers.size()
            );

            log.info(resultMessage);

            return MarketingMessageResponse.builder()
                    .success(successCount > 0)
                    .message(resultMessage)
                    .totalCustomers(targetCustomers.size())
                    .successCount(successCount)
                    .failureCount(failureCount)
                    .templateUsed(request.getTemplateName())
                    .messageParam(request.getMessageParam())
                    .build();

        } catch (Exception e) {
            log.error("Error in bulk marketing message send", e);
            return MarketingMessageResponse.builder()
                    .success(false)
                    .message("Error sending marketing messages: " + e.getMessage())
                    .totalCustomers(0)
                    .successCount(0)
                    .failureCount(0)
                    .templateUsed(request.getTemplateName())
                    .messageParam(request.getMessageParam())
                    .build();
        }
    }

    /**
     * Get target customers based on audience selection
     */
    private List<Customer> getTargetCustomers(String targetAudience) {
        if ("ALL_CUSTOMERS".equalsIgnoreCase(targetAudience)) {
            // Get all active customers with SMS notifications enabled
            return customerRepository.findAll().stream()
                    .filter(Customer::getIsActive)
                    .filter(customer -> customer.getSmsNotifications() != null && customer.getSmsNotifications())
                    .filter(customer -> customer.getMobileNumber() != null && !customer.getMobileNumber().trim().isEmpty())
                    .collect(Collectors.toList());
        } else {
            // Parse comma-separated customer IDs
            try {
                List<Long> customerIds = Arrays.stream(targetAudience.split(","))
                        .map(String::trim)
                        .map(Long::parseLong)
                        .collect(Collectors.toList());

                return customerRepository.findAllById(customerIds).stream()
                        .filter(Customer::getIsActive)
                        .filter(customer -> customer.getMobileNumber() != null && !customer.getMobileNumber().trim().isEmpty())
                        .collect(Collectors.toList());
            } catch (NumberFormatException e) {
                log.error("Invalid customer IDs in target audience: {}", targetAudience, e);
                return Collections.emptyList();
            }
        }
    }

    /**
     * Send a single marketing message via WhatsApp
     */
    private boolean sendMarketingMessage(String mobileNumber, String templateName, Map<String, Object> templateData) {
        try {
            // Use the WhatsAppNotificationService's generic message sender
            // We'll use reflection to access the private method, or we can modify the service
            // For now, let's create a custom implementation similar to the existing service

            return whatsAppNotificationService.sendMarketingMessage(
                    mobileNumber,
                    templateName,
                    templateData
            );
        } catch (Exception e) {
            log.error("Error sending marketing message to {}", mobileNumber, e);
            return false;
        }
    }

    /**
     * Get list of available marketing templates
     */
    public List<TemplateInfo> getAvailableTemplates() {
        List<TemplateInfo> templates = new ArrayList<>();

        templates.add(TemplateInfo.builder()
                .templateName("test")
                .displayName("Test Template")
                .description("Test marketing message template")
                .parameterDescription("Message content for {{1}} placeholder")
                .build());

        templates.add(TemplateInfo.builder()
                .templateName("marketingmsg")
                .displayName("Marketing Message")
                .description("Main marketing message template")
                .parameterDescription("Marketing message content for {{1}} placeholder")
                .build());

        return templates;
    }

    /**
     * Get customer statistics for marketing
     */
    public Map<String, Object> getMarketingStats() {
        Map<String, Object> stats = new HashMap<>();

        long totalCustomers = customerRepository.count();
        long activeCustomers = customerRepository.findByIsActive(true).size();
        long smsEnabledCustomers = customerRepository.findBySmsNotifications(true).size();

        // Count customers with valid mobile numbers
        long customersWithMobile = customerRepository.findAll().stream()
                .filter(customer -> customer.getMobileNumber() != null && !customer.getMobileNumber().trim().isEmpty())
                .count();

        stats.put("totalCustomers", totalCustomers);
        stats.put("activeCustomers", activeCustomers);
        stats.put("smsEnabledCustomers", smsEnabledCustomers);
        stats.put("customersWithMobile", customersWithMobile);
        stats.put("eligibleForMarketing",
                customerRepository.findAll().stream()
                        .filter(Customer::getIsActive)
                        .filter(customer -> customer.getSmsNotifications() != null && customer.getSmsNotifications())
                        .filter(customer -> customer.getMobileNumber() != null && !customer.getMobileNumber().trim().isEmpty())
                        .count());

        return stats;
    }
}
