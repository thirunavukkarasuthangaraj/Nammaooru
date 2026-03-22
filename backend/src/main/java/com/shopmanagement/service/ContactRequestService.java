package com.shopmanagement.service;

import com.shopmanagement.entity.ContactRequest;
import com.shopmanagement.entity.User;
import com.shopmanagement.entity.UserFcmToken;
import com.shopmanagement.repository.ContactRequestRepository;
import com.shopmanagement.repository.UserFcmTokenRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class ContactRequestService {

    private final ContactRequestRepository contactRequestRepository;
    private final UserRepository userRepository;
    private final UserFcmTokenRepository userFcmTokenRepository;
    private final FirebaseNotificationService firebaseNotificationService;

    @Transactional
    public ContactRequest sendRequest(Long requesterUserId, String postType, Long postId,
                                      String postTitle, Long postOwnerUserId) {
        // Check duplicate
        Optional<ContactRequest> existing = contactRequestRepository
                .findByRequesterUserIdAndPostTypeAndPostId(requesterUserId, postType, postId);
        if (existing.isPresent()) {
            return existing.get(); // already sent
        }

        String requesterName = null;
        String requesterPhone = null;
        try {
            User requester = userRepository.findById(requesterUserId).orElse(null);
            if (requester != null) {
                String fn = requester.getFirstName() != null ? requester.getFirstName() : "";
                String ln = requester.getLastName() != null ? requester.getLastName() : "";
                requesterName = (fn + " " + ln).trim();
                if (requesterName.isEmpty()) requesterName = requester.getUsername();
                requesterPhone = requester.getMobileNumber();
            }
        } catch (Exception e) {
            log.warn("Could not fetch requester details: {}", e.getMessage());
        }

        ContactRequest request = ContactRequest.builder()
                .requesterUserId(requesterUserId)
                .requesterName(requesterName)
                .requesterPhone(requesterPhone)
                .postType(postType)
                .postId(postId)
                .postTitle(postTitle)
                .postOwnerUserId(postOwnerUserId)
                .status("PENDING")
                .build();

        ContactRequest saved = contactRequestRepository.save(request);

        // Notify post owner
        sendNotificationToUser(postOwnerUserId,
                "தொடர்பு கோரிக்கை / Contact Request",
                (requesterName != null ? requesterName : "ஒருவர்") + " உங்களை தொடர்பு கொள்ள விரும்புகிறார்",
                Map.of("type", "CONTACT_REQUEST", "requestId", saved.getId().toString()));

        return saved;
    }

    @Transactional
    public ContactRequest respond(Long requestId, Long ownerUserId, boolean approved) {
        ContactRequest req = contactRequestRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("Request not found: " + requestId));

        if (!req.getPostOwnerUserId().equals(ownerUserId)) {
            throw new RuntimeException("Not authorized to respond to this request");
        }

        req.setStatus(approved ? "APPROVED" : "DENIED");
        req.setRespondedAt(LocalDateTime.now());
        ContactRequest saved = contactRequestRepository.save(req);

        // Notify requester
        if (approved) {
            sendNotificationToUser(req.getRequesterUserId(),
                    "கோரிக்கை அனுமதிக்கப்பட்டது / Request Approved",
                    "உங்கள் தொடர்பு கோரிக்கை அனுமதிக்கப்பட்டது. இப்போது தொடர்பு கொள்ளலாம்.",
                    Map.of("type", "REQUEST_APPROVED", "requestId", requestId.toString(),
                           "postType", req.getPostType(), "postId", req.getPostId().toString()));
        } else {
            sendNotificationToUser(req.getRequesterUserId(),
                    "கோரிக்கை நிராகரிக்கப்பட்டது / Request Denied",
                    "உங்கள் தொடர்பு கோரிக்கை நிராகரிக்கப்பட்டது.",
                    Map.of("type", "REQUEST_DENIED", "requestId", requestId.toString()));
        }

        return saved;
    }

    public List<ContactRequest> getIncomingRequests(Long ownerUserId) {
        return contactRequestRepository.findByPostOwnerUserIdOrderByCreatedAtDesc(ownerUserId);
    }

    public List<ContactRequest> getPendingRequests(Long ownerUserId) {
        return contactRequestRepository.findByPostOwnerUserIdAndStatusOrderByCreatedAtDesc(ownerUserId, "PENDING");
    }

    public List<ContactRequest> getMyOutgoingRequests(Long requesterUserId) {
        return contactRequestRepository.findByRequesterUserIdOrderByCreatedAtDesc(requesterUserId);
    }

    public Optional<ContactRequest> getMyRequestForPost(Long requesterUserId, String postType, Long postId) {
        return contactRequestRepository.findByRequesterUserIdAndPostTypeAndPostId(requesterUserId, postType, postId);
    }

    public long countPendingForOwner(Long ownerUserId) {
        return contactRequestRepository.countByPostOwnerUserIdAndStatus(ownerUserId, "PENDING");
    }

    private void sendNotificationToUser(Long userId, String title, String body, Map<String, String> data) {
        try {
            List<UserFcmToken> tokens = userFcmTokenRepository.findActiveTokensByUserId(userId);
            for (UserFcmToken token : tokens) {
                firebaseNotificationService.sendNotificationWithData(title, body, token.getFcmToken(), data);
            }
        } catch (Exception e) {
            log.warn("Failed to send notification to user {}: {}", userId, e.getMessage());
        }
    }
}
