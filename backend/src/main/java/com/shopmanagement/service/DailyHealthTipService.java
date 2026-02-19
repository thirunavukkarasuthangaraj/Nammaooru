package com.shopmanagement.service;

import com.shopmanagement.entity.Customer;
import com.shopmanagement.entity.HealthTipQueue;
import com.shopmanagement.entity.Notification;
import com.shopmanagement.entity.User;
import com.shopmanagement.entity.UserFcmToken;
import com.shopmanagement.repository.CustomerRepository;
import com.shopmanagement.repository.HealthTipQueueRepository;
import com.shopmanagement.repository.NotificationRepository;
import com.shopmanagement.repository.UserFcmTokenRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class DailyHealthTipService {

    private final GeminiSearchService geminiSearchService;
    private final UserRepository userRepository;
    private final CustomerRepository customerRepository;
    private final UserFcmTokenRepository userFcmTokenRepository;
    private final FirebaseNotificationService firebaseNotificationService;
    private final NotificationRepository notificationRepository;
    private final HealthTipQueueRepository healthTipQueueRepository;

    private static final String HEALTH_TIP_TITLE = "\uD83C\uDF3F \u0B87\u0BA9\u0BCD\u0BB1\u0BC8\u0BAF \u0B86\u0BB0\u0BCB\u0B95\u0BCD\u0B95\u0BBF\u0BAF \u0B95\u0BC1\u0BB1\u0BBF\u0BAA\u0BCD\u0BAA\u0BC1";

    private static final String GEMINI_PROMPT_SINGLE =
            "Generate a short, practical health tip in Tamil (\u0BA4\u0BAE\u0BBF\u0BB4\u0BCD). " +
            "Topic: daily wellness, nutrition, exercise, or traditional Tamil health practices " +
            "(\u0B9A\u0BBF\u0BA4\u0BCD\u0BA4 \u0BAE\u0BB0\u0BC1\u0BA4\u0BCD\u0BA4\u0BC1\u0BB5\u0BAE\u0BCD, \u0BA8\u0BBE\u0B9F\u0BCD\u0B9F\u0BC1 \u0BB5\u0BC8\u0BA4\u0BCD\u0BA4\u0BBF\u0BAF\u0BAE\u0BCD). " +
            "Keep it under 2 sentences. Just the tip in Tamil, no title or English. " +
            "Also suggest one popular Tamil health YouTube doctor's video topic related to the tip " +
            "(e.g., Dr. Sivaraman, Dr. Ku. Sivaraman, Arogyam TV). " +
            "Format: first the tip, then on a new line: '\uD83C\uDFA5 YouTube: [doctor name] - [video topic in Tamil]'";

    private static final String GEMINI_PROMPT_WEEKLY =
            "Generate 7 different short, practical health tips in Tamil (\u0BA4\u0BAE\u0BBF\u0BB4\u0BCD), one for each day of the week. " +
            "Topics: daily wellness, nutrition, exercise, traditional Tamil health practices " +
            "(\u0B9A\u0BBF\u0BA4\u0BCD\u0BA4 \u0BAE\u0BB0\u0BC1\u0BA4\u0BCD\u0BA4\u0BC1\u0BB5\u0BAE\u0BCD, \u0BA8\u0BBE\u0B9F\u0BCD\u0B9F\u0BC1 \u0BB5\u0BC8\u0BA4\u0BCD\u0BA4\u0BBF\u0BAF\u0BAE\u0BCD). " +
            "Each tip should be different and cover a different topic. Keep each under 2 sentences. " +
            "For each tip, suggest one popular Tamil health YouTube doctor's video topic " +
            "(e.g., Dr. Sivaraman, Dr. Ku. Sivaraman, Arogyam TV). " +
            "Format each tip as:\n" +
            "---\n" +
            "[tip in Tamil]\n" +
            "\uD83C\uDFA5 YouTube: [doctor name] - [video topic in Tamil]\n" +
            "---\n" +
            "Separate each tip with --- on its own line. No English, no numbering, no titles.";

    private static final List<String> FALLBACK_TIPS = Arrays.asList(
            "\u0BA4\u0BBF\u0BA9\u0BAE\u0BC1\u0BAE\u0BCD \u0B95\u0BBE\u0BB2\u0BC8\u0BAF\u0BBF\u0BB2\u0BCD \u0B92\u0BB0\u0BC1 \u0B95\u0BCD\u0BB3\u0BBE\u0BB8\u0BCD \u0BB5\u0BC6\u0BA4\u0BC1\u0BB5\u0BC6\u0BA4\u0BC1\u0BAA\u0BCD\u0BAA\u0BBE\u0BA9 \u0BA8\u0BC0\u0BB0\u0BCD \u0B95\u0BC1\u0B9F\u0BBF\u0BAA\u0BCD\u0BAA\u0BA4\u0BC1 \u0B89\u0B9F\u0BB2\u0BCD \u0B86\u0BB0\u0BCB\u0B95\u0BCD\u0B95\u0BBF\u0BAF\u0BA4\u0BCD\u0BA4\u0BBF\u0BB1\u0BCD\u0B95\u0BC1 \u0BAE\u0BBF\u0B95\u0BB5\u0BC1\u0BAE\u0BCD \u0BA8\u0BB2\u0BCD\u0BB2\u0BA4\u0BC1.\n\uD83C\uDFA5 YouTube: Dr. Sivaraman - \u0BA4\u0BA3\u0BCD\u0BA3\u0BC0\u0BB0\u0BCD \u0B95\u0BC1\u0B9F\u0BBF\u0BAA\u0BCD\u0BAA\u0BA4\u0BB0\u0BCD \u0BAA\u0BAF\u0BA9\u0BCD\u0B95\u0BB3\u0BCD",
            "\u0BA4\u0BBF\u0BA9\u0BAE\u0BC1\u0BAE\u0BCD 30 \u0BA8\u0BBF\u0BAE\u0BBF\u0B9F\u0BAE\u0BCD \u0BA8\u0B9F\u0BAA\u0BCD\u0BAA\u0BAF\u0BBF\u0BB1\u0BCD\u0B9A\u0BBF \u0B9A\u0BC6\u0BAF\u0BCD\u0BAF\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD. \u0B87\u0BA4\u0BC1 \u0B87\u0BA4\u0BAF \u0BA8\u0BCB\u0BAF\u0BCD\u0B95\u0BB3\u0BC8 \u0BA4\u0B9F\u0BC1\u0B95\u0BCD\u0B95\u0BC1\u0BAE\u0BCD.\n\uD83C\uDFA5 YouTube: Dr. Ku. Sivaraman - \u0BA8\u0B9F\u0BAA\u0BCD\u0BAA\u0BAF\u0BBF\u0BB1\u0BCD\u0B9A\u0BBF\u0BAF\u0BBF\u0BA9\u0BCD \u0BAA\u0BAF\u0BA9\u0BCD\u0B95\u0BB3\u0BCD",
            "\u0B87\u0BB0\u0BB5\u0BC1 \u0B89\u0BA3\u0BB5\u0BBF\u0BB2\u0BCD \u0BAE\u0B9E\u0BCD\u0B9A\u0BB3\u0BCD \u0BA4\u0BA3\u0BCD\u0BA3\u0BC0\u0BB0\u0BCD \u0B9A\u0BC7\u0BB0\u0BCD\u0BA4\u0BCD\u0BA4\u0BC1 \u0B95\u0BC1\u0B9F\u0BBF\u0BAA\u0BCD\u0BAA\u0BA4\u0BC1 \u0B9A\u0BC0\u0BB0\u0BA3\u0BA4\u0BCD\u0BA4\u0BBF\u0BB1\u0BCD\u0B95\u0BC1 \u0BA8\u0BB2\u0BCD\u0BB2\u0BA4\u0BC1.\n\uD83C\uDFA5 YouTube: Arogyam TV - \u0BAE\u0B9E\u0BCD\u0B9A\u0BB3\u0BCD \u0BA4\u0BA3\u0BCD\u0BA3\u0BC0\u0BB0\u0BCD \u0BAA\u0BAF\u0BA9\u0BCD\u0B95\u0BB3\u0BCD",
            "\u0BA4\u0BC1\u0BB3\u0B9A\u0BBF \u0B87\u0BB2\u0BC8 \u0B89\u0B9F\u0BB2\u0BBF\u0BB2\u0BCD \u0BB5\u0BBF\u0B9F\u0BAE\u0BBF\u0BA9\u0BCD \u0B9A\u0BBF \u0B89\u0BB1\u0BCD\u0BAA\u0BA4\u0BCD\u0BA4\u0BBF\u0BAF\u0BC8 \u0BA4\u0BC2\u0BA3\u0BCD\u0B9F\u0BC1\u0B95\u0BBF\u0BB1\u0BA4\u0BC1. \u0BA4\u0BBF\u0BA9\u0BAE\u0BC1\u0BAE\u0BCD 15 \u0BA8\u0BBF\u0BAE\u0BBF\u0B9F\u0BAE\u0BCD \u0BB5\u0BC6\u0BAF\u0BBF\u0BB2\u0BBF\u0BB2\u0BCD \u0BA8\u0BBF\u0BB1\u0BCD\u0BAA\u0BA4\u0BC1 \u0BA8\u0BB2\u0BCD\u0BB2\u0BA4\u0BC1.\n\uD83C\uDFA5 YouTube: Dr. Sivaraman - \u0BB5\u0BBF\u0B9F\u0BAE\u0BBF\u0BA9\u0BCD D \u0BAA\u0BB1\u0BCD\u0BB1\u0BBE\u0B95\u0BCD\u0B95\u0BC1\u0BB1\u0BC8",
            "\u0B95\u0BC0\u0BB0\u0BC8 \u0BAA\u0BB4\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B89\u0B9F\u0BB2\u0BBF\u0BB2\u0BCD \u0BA8\u0BCB\u0BAF\u0BCD \u0B8E\u0BA4\u0BBF\u0BB0\u0BCD\u0BAA\u0BCD\u0BAA\u0BC1 \u0B9A\u0B95\u0BCD\u0BA4\u0BBF\u0BAF\u0BC8 \u0B85\u0BA4\u0BBF\u0B95\u0BB0\u0BBF\u0B95\u0BCD\u0B95\u0BC1\u0BAE\u0BCD. \u0BA4\u0BBF\u0BA9\u0BAE\u0BC1\u0BAE\u0BCD \u0B92\u0BB0\u0BC1 \u0BAA\u0B99\u0BCD\u0B95\u0BC1 \u0B95\u0BC0\u0BB0\u0BC8 \u0B9A\u0BBE\u0BAA\u0BCD\u0BAA\u0BBF\u0B9F\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD.\n\uD83C\uDFA5 YouTube: Arogyam TV - \u0B95\u0BC0\u0BB0\u0BC8\u0BAF\u0BBF\u0BA9\u0BCD \u0BAE\u0BB0\u0BC1\u0BA4\u0BCD\u0BA4\u0BC1\u0BB5 \u0BAA\u0BAF\u0BA9\u0BCD\u0B95\u0BB3\u0BCD",
            "\u0B87\u0BB0\u0BB5\u0BC1 \u0B89\u0BA3\u0BB5\u0BBF\u0BB1\u0BCD\u0B95\u0BC1\u0BAA\u0BCD \u0BAA\u0BBF\u0BB1\u0B95\u0BC1 \u0B89\u0B9F\u0BA9\u0B9F\u0BBF\u0BAF\u0BBE\u0B95 10 \u0BA8\u0BBF\u0BAE\u0BBF\u0B9F\u0BAE\u0BCD \u0BA8\u0B9F\u0BAA\u0BCD\u0BAA\u0BA4\u0BC1 \u0B9A\u0BC0\u0BB0\u0BA3\u0BA4\u0BCD\u0BA4\u0BBF\u0BB1\u0BCD\u0B95\u0BC1 \u0BA8\u0BB2\u0BCD\u0BB2\u0BA4\u0BC1.\n\uD83C\uDFA5 YouTube: Dr. Ku. Sivaraman - \u0B9A\u0BBE\u0BAA\u0BCD\u0BAA\u0BBF\u0B9F\u0BC1\u0BB5\u0BA4\u0BB1\u0BCD\u0B95\u0BC1\u0BAA\u0BCD \u0BAA\u0BBF\u0BB1\u0B95\u0BC1 \u0BA8\u0B9F\u0BAA\u0BCD\u0BAA\u0BA4\u0BC1",
            "\u0BA4\u0BBF\u0BA9\u0BAE\u0BC1\u0BAE\u0BCD \u0B92\u0BB0\u0BC1 \u0B95\u0BC8\u0BAA\u0BCD\u0BAA\u0BBF\u0B9F\u0BBF \u0BAA\u0BB4\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B9A\u0BBE\u0BAA\u0BCD\u0BAA\u0BBF\u0B9F\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD. \u0B87\u0BA4\u0BC1 \u0BA8\u0BCB\u0BAF\u0BCD \u0B8E\u0BA4\u0BBF\u0BB0\u0BCD\u0BAA\u0BCD\u0BAA\u0BC1 \u0B9A\u0B95\u0BCD\u0BA4\u0BBF\u0BAF\u0BC8 \u0B85\u0BA4\u0BBF\u0B95\u0BB0\u0BBF\u0B95\u0BCD\u0B95\u0BC1\u0BAE\u0BCD.\n\uD83C\uDFA5 YouTube: Dr. Sivaraman - \u0BAA\u0BB4\u0B99\u0BCD\u0B95\u0BB3\u0BBF\u0BA9\u0BCD \u0BAE\u0BB0\u0BC1\u0BA4\u0BCD\u0BA4\u0BC1\u0BB5 \u0BAA\u0BAF\u0BA9\u0BCD\u0B95\u0BB3\u0BCD",
            "\u0B87\u0BB0\u0BB5\u0BC1 \u0B89\u0BA3\u0BB5\u0BBF\u0BB2\u0BCD \u0BAA\u0BC2\u0BA3\u0BCD\u0B9F\u0BC1, \u0BAA\u0BB1\u0B99\u0BCD\u0B95\u0BBF\u0BAA\u0BCD\u0BAA\u0BC2 \u0B9A\u0BC7\u0BB0\u0BCD\u0BA4\u0BCD\u0BA4\u0BC1 \u0B9A\u0BBE\u0BAA\u0BCD\u0BAA\u0BBF\u0B9F\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD. \u0B87\u0BB5\u0BC8 \u0B9A\u0BC0\u0BB0\u0BA3\u0BAE\u0BCD \u0BAE\u0BB1\u0BCD\u0BB1\u0BC1\u0BAE\u0BCD \u0BA8\u0BCB\u0BAF\u0BCD \u0B8E\u0BA4\u0BBF\u0BB0\u0BCD\u0BAA\u0BCD\u0BAA\u0BC1 \u0B9A\u0B95\u0BCD\u0BA4\u0BBF\u0BAF\u0BC8 \u0BA4\u0BB0\u0BC1\u0BAE\u0BCD.\n\uD83C\uDFA5 YouTube: Arogyam TV - \u0BA8\u0BBE\u0B9F\u0BCD\u0B9F\u0BC1 \u0BB5\u0BC8\u0BA4\u0BCD\u0BA4\u0BBF\u0BAF\u0BAE\u0BCD \u0B89\u0BA3\u0BB5\u0BC1 \u0B95\u0BC1\u0BB1\u0BBF\u0BAA\u0BCD\u0BAA\u0BC1\u0B95\u0BB3\u0BCD",
            "\u0B85\u0BA4\u0BBF\u0B95\u0BAE\u0BBE\u0B95 \u0B9A\u0BB0\u0BCD\u0B95\u0BCD\u0B95\u0BB0\u0BC8 \u0B9A\u0BBE\u0BAA\u0BCD\u0BAA\u0BBF\u0B9F\u0BC1\u0BB5\u0BA4\u0BC8 \u0BA4\u0BB5\u0BBF\u0BB0\u0BCD\u0BA4\u0BCD\u0BA4\u0BC1, \u0BB5\u0BC6\u0BB2\u0BCD\u0BB2\u0BAE\u0BCD \u0B9A\u0BBE\u0BAA\u0BCD\u0BAA\u0BBF\u0B9F\u0BC1\u0B99\u0BCD\u0B95\u0BB3\u0BCD. \u0B87\u0BA4\u0BC1 \u0BA8\u0BC0\u0BB0\u0BBF\u0BB4\u0BBF\u0BB5\u0BC1 \u0BA8\u0BCB\u0BAF\u0BCD\u0B95\u0BB3\u0BC8 \u0BA4\u0B9F\u0BC1\u0B95\u0BCD\u0B95\u0BC1\u0BAE\u0BCD.\n\uD83C\uDFA5 YouTube: Dr. Ku. Sivaraman - \u0B9A\u0BB0\u0BCD\u0B95\u0BCD\u0B95\u0BB0\u0BC8 \u0BA8\u0BCB\u0BAF\u0BCD \u0BA4\u0B9F\u0BC1\u0BAA\u0BCD\u0BAA\u0BC1 \u0B95\u0BC1\u0BB1\u0BBF\u0BAA\u0BCD\u0BAA\u0BC1\u0B95\u0BB3\u0BCD",
            "\u0BA4\u0BBF\u0BA9\u0BAE\u0BC1\u0BAE\u0BCD 7-8 \u0BAE\u0BA3\u0BBF \u0BA8\u0BC7\u0BB0\u0BAE\u0BCD \u0BA4\u0BC2\u0B99\u0BCD\u0B95\u0BC1\u0BB5\u0BA4\u0BC1 \u0B89\u0B9F\u0BB2\u0BCD \u0BAE\u0BB1\u0BCD\u0BB1\u0BC1\u0BAE\u0BCD \u0BAE\u0BA9 \u0B86\u0BB0\u0BCB\u0B95\u0BCD\u0B95\u0BBF\u0BAF\u0BA4\u0BCD\u0BA4\u0BBF\u0BB1\u0BCD\u0B95\u0BC1 \u0BAE\u0BBF\u0B95\u0BB5\u0BC1\u0BAE\u0BCD \u0B85\u0BB5\u0B9A\u0BBF\u0BAF\u0BAE\u0BCD.\n\uD83C\uDFA5 YouTube: Dr. Sivaraman - \u0BA4\u0BC2\u0B95\u0BCD\u0B95\u0BAE\u0BBF\u0BA9\u0BCD\u0BAE\u0BC8 \u0BAE\u0BB1\u0BCD\u0BB1\u0BC1\u0BAE\u0BCD \u0B86\u0BB0\u0BCB\u0B95\u0BCD\u0B95\u0BBF\u0BAF\u0BAE\u0BCD"
    );

    // ===== SCHEDULED JOB: Picks next APPROVED tip from queue and sends at 6 AM =====

    @Scheduled(cron = "0 0 6 * * *", zone = "Asia/Kolkata")
    @Transactional
    public void sendDailyHealthTip() {
        log.info("Starting daily health tip notification job...");

        try {
            // Pick next approved tip from queue
            Optional<HealthTipQueue> nextTipOpt = healthTipQueueRepository
                    .findFirstByStatusOrderByScheduledDateAscCreatedAtAsc(HealthTipQueue.TipStatus.APPROVED);

            if (nextTipOpt.isEmpty()) {
                log.warn("No approved health tips in queue. Skipping today's notification.");
                return;
            }

            HealthTipQueue tipEntry = nextTipOpt.get();
            String healthTip = tipEntry.getMessage();
            log.info("Sending queued health tip ID {}: {}", tipEntry.getId(),
                    healthTip.substring(0, Math.min(80, healthTip.length())) + "...");

            // Send to opted-in customers
            Map<String, Object> result = sendToOptedInCustomers(healthTip, Notification.SenderType.SYSTEM, "system");

            // Mark as SENT
            tipEntry.setStatus(HealthTipQueue.TipStatus.SENT);
            tipEntry.setSentAt(LocalDateTime.now());
            healthTipQueueRepository.save(tipEntry);

            log.info("Daily health tip (queue ID {}) sent successfully: {}", tipEntry.getId(), result);

        } catch (Exception e) {
            log.error("Failed to send daily health tip notification", e);
        }
    }

    // ===== ADMIN: Generate a week of tips for review =====

    @Transactional
    public List<Map<String, Object>> generateWeeklyTips() {
        log.info("Admin generating weekly health tips for review");

        List<String> tips = generateMultipleHealthTips(7);
        LocalDate startDate = LocalDate.now().plusDays(1); // Start from tomorrow

        List<HealthTipQueue> queueEntries = new ArrayList<>();
        for (int i = 0; i < tips.size(); i++) {
            HealthTipQueue entry = HealthTipQueue.builder()
                    .message(tips.get(i))
                    .status(HealthTipQueue.TipStatus.PENDING)
                    .scheduledDate(startDate.plusDays(i))
                    .build();
            queueEntries.add(entry);
        }

        List<HealthTipQueue> saved = healthTipQueueRepository.saveAll(queueEntries);
        log.info("Generated {} health tips for the week", saved.size());

        return saved.stream().map(this::mapToResponse).collect(Collectors.toList());
    }

    // ===== ADMIN: View queue (all tips with status) =====

    public List<Map<String, Object>> getQueue() {
        List<HealthTipQueue> pending = healthTipQueueRepository
                .findByStatusOrderByCreatedAtAsc(HealthTipQueue.TipStatus.PENDING);
        List<HealthTipQueue> approved = healthTipQueueRepository
                .findByStatusOrderByScheduledDateAsc(HealthTipQueue.TipStatus.APPROVED);

        List<HealthTipQueue> combined = new ArrayList<>(pending);
        combined.addAll(approved);

        return combined.stream().map(this::mapToResponse).collect(Collectors.toList());
    }

    // ===== ADMIN: Edit a tip in the queue =====

    @Transactional
    public Map<String, Object> editQueuedTip(Long tipId, String newMessage) {
        HealthTipQueue tip = healthTipQueueRepository.findById(tipId)
                .orElseThrow(() -> new RuntimeException("Health tip not found with ID: " + tipId));

        if (tip.getStatus() == HealthTipQueue.TipStatus.SENT) {
            throw new RuntimeException("Cannot edit a tip that has already been sent");
        }

        tip.setMessage(newMessage);
        healthTipQueueRepository.save(tip);
        log.info("Admin edited health tip ID {}", tipId);
        return mapToResponse(tip);
    }

    // ===== ADMIN: Approve a tip =====

    @Transactional
    public Map<String, Object> approveTip(Long tipId, String approvedBy) {
        HealthTipQueue tip = healthTipQueueRepository.findById(tipId)
                .orElseThrow(() -> new RuntimeException("Health tip not found with ID: " + tipId));

        if (tip.getStatus() == HealthTipQueue.TipStatus.SENT) {
            throw new RuntimeException("This tip has already been sent");
        }

        tip.setStatus(HealthTipQueue.TipStatus.APPROVED);
        tip.setApprovedBy(approvedBy);
        tip.setApprovedAt(LocalDateTime.now());
        healthTipQueueRepository.save(tip);

        log.info("Admin {} approved health tip ID {}", approvedBy, tipId);
        return mapToResponse(tip);
    }

    // ===== ADMIN: Reject a tip =====

    @Transactional
    public Map<String, Object> rejectTip(Long tipId) {
        HealthTipQueue tip = healthTipQueueRepository.findById(tipId)
                .orElseThrow(() -> new RuntimeException("Health tip not found with ID: " + tipId));

        if (tip.getStatus() == HealthTipQueue.TipStatus.SENT) {
            throw new RuntimeException("Cannot reject a tip that has already been sent");
        }

        tip.setStatus(HealthTipQueue.TipStatus.REJECTED);
        healthTipQueueRepository.save(tip);

        log.info("Admin rejected health tip ID {}", tipId);
        return mapToResponse(tip);
    }

    // ===== ADMIN: Send a specific tip immediately =====

    @Transactional
    public Map<String, Object> sendTipNow(Long tipId, String sentBy) {
        HealthTipQueue tip = healthTipQueueRepository.findById(tipId)
                .orElseThrow(() -> new RuntimeException("Health tip not found with ID: " + tipId));

        if (tip.getStatus() == HealthTipQueue.TipStatus.SENT) {
            throw new RuntimeException("This tip has already been sent");
        }

        Map<String, Object> result = sendToOptedInCustomers(tip.getMessage(), Notification.SenderType.ADMIN, sentBy);

        tip.setStatus(HealthTipQueue.TipStatus.SENT);
        tip.setSentAt(LocalDateTime.now());
        tip.setApprovedBy(sentBy);
        tip.setApprovedAt(LocalDateTime.now());
        healthTipQueueRepository.save(tip);

        log.info("Admin {} sent health tip ID {} immediately", sentBy, tipId);
        return result;
    }

    // ===== ADMIN: View sent history =====

    public Page<Map<String, Object>> getHealthTipHistory(int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Notification> tips = notificationRepository.findHealthTipHistory(pageable);
        return tips.map(n -> Map.<String, Object>of(
                "id", n.getId(),
                "title", n.getTitle(),
                "message", n.getMessage(),
                "sentAt", n.getCreatedAt().toString(),
                "sentBy", n.getSenderType() != null ? n.getSenderType().name() : "SYSTEM"
        ));
    }

    // ===== ADMIN: Queue stats =====

    public Map<String, Object> getQueueStats() {
        return Map.of(
                "pending", healthTipQueueRepository.countByStatus(HealthTipQueue.TipStatus.PENDING),
                "approved", healthTipQueueRepository.countByStatus(HealthTipQueue.TipStatus.APPROVED),
                "sent", healthTipQueueRepository.countByStatus(HealthTipQueue.TipStatus.SENT),
                "rejected", healthTipQueueRepository.countByStatus(HealthTipQueue.TipStatus.REJECTED)
        );
    }

    // ===== Internal: Send health tip to all opted-in customers =====

    private Map<String, Object> sendToOptedInCustomers(String message, Notification.SenderType senderType, String createdBy) {
        List<User> optedInUsers = userRepository.findByRoleAndHealthTipNotificationsEnabledTrue(User.UserRole.USER);
        if (optedInUsers.isEmpty()) {
            log.info("No opted-in customers found for health tip notification");
            return Map.of("success", true, "pushSuccess", 0, "pushFailed", 0, "notificationsSaved", 0);
        }

        List<Long> userIds = optedInUsers.stream().map(User::getId).collect(Collectors.toList());
        List<UserFcmToken> fcmTokens = userFcmTokenRepository.findActiveTokensByUserIds(userIds);

        int successCount = 0;
        int failCount = 0;
        Map<String, String> data = Map.of("type", "health_tip", "category", "HEALTH_TIP");

        for (UserFcmToken fcmToken : fcmTokens) {
            try {
                firebaseNotificationService.sendNotificationWithData(
                        HEALTH_TIP_TITLE, message, fcmToken.getFcmToken(), data);
                successCount++;
            } catch (Exception e) {
                log.error("Failed to send health tip to token: {}...",
                        fcmToken.getFcmToken().substring(0, Math.min(20, fcmToken.getFcmToken().length())), e);
                failCount++;
            }
        }

        // Map User mobile numbers to Customer IDs (notifications are fetched by Customer ID)
        List<String> mobileNumbers = optedInUsers.stream()
                .map(User::getMobileNumber)
                .filter(m -> m != null && !m.isEmpty())
                .collect(Collectors.toList());
        Map<String, Long> mobileToCustomerId = customerRepository.findByMobileNumberIn(mobileNumbers).stream()
                .collect(Collectors.toMap(Customer::getMobileNumber, Customer::getId, (a, b) -> a));

        List<Notification> notifications = new ArrayList<>();
        for (User user : optedInUsers) {
            Long customerId = mobileToCustomerId.get(user.getMobileNumber());
            if (customerId != null) {
                notifications.add(Notification.builder()
                        .title(HEALTH_TIP_TITLE)
                        .message(message)
                        .type(Notification.NotificationType.HEALTH_TIP)
                        .priority(Notification.NotificationPriority.LOW)
                        .recipientId(customerId)
                        .recipientType(Notification.RecipientType.CUSTOMER)
                        .senderType(senderType)
                        .icon("health")
                        .category("HEALTH_TIP")
                        .isPushSent(true)
                        .createdBy(createdBy)
                        .updatedBy(createdBy)
                        .build());
            }
        }
        notificationRepository.saveAll(notifications);

        return Map.of(
                "success", true,
                "pushSuccess", successCount,
                "pushFailed", failCount,
                "notificationsSaved", notifications.size()
        );
    }

    // ===== Internal: Generate multiple tips =====

    private List<String> generateMultipleHealthTips(int count) {
        List<String> tips = new ArrayList<>();

        try {
            if (geminiSearchService.isEnabled()) {
                String response = geminiSearchService.generateText(GEMINI_PROMPT_WEEKLY);
                // Parse response by --- separator
                String[] parts = response.split("---");
                for (String part : parts) {
                    String trimmed = part.trim();
                    if (!trimmed.isEmpty()) {
                        tips.add(trimmed);
                    }
                }
            }
        } catch (Exception e) {
            log.warn("Gemini AI failed for weekly tip generation: {}", e.getMessage());
        }

        // Fill remaining with fallback tips if needed
        List<String> shuffledFallbacks = new ArrayList<>(FALLBACK_TIPS);
        java.util.Collections.shuffle(shuffledFallbacks);
        int fallbackIndex = 0;
        while (tips.size() < count && fallbackIndex < shuffledFallbacks.size()) {
            tips.add(shuffledFallbacks.get(fallbackIndex++));
        }

        return tips.subList(0, Math.min(tips.size(), count));
    }

    private Map<String, Object> mapToResponse(HealthTipQueue tip) {
        Map<String, Object> map = new java.util.HashMap<>();
        map.put("id", tip.getId());
        map.put("message", tip.getMessage());
        map.put("status", tip.getStatus().name());
        map.put("scheduledDate", tip.getScheduledDate() != null ? tip.getScheduledDate().toString() : null);
        map.put("sentAt", tip.getSentAt() != null ? tip.getSentAt().toString() : null);
        map.put("approvedBy", tip.getApprovedBy());
        map.put("approvedAt", tip.getApprovedAt() != null ? tip.getApprovedAt().toString() : null);
        map.put("createdAt", tip.getCreatedAt() != null ? tip.getCreatedAt().toString() : null);
        return map;
    }
}
