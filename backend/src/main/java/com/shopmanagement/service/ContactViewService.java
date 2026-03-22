package com.shopmanagement.service;

import com.shopmanagement.dto.ContactViewRequest;
import com.shopmanagement.entity.ContactView;
import com.shopmanagement.entity.User;
import com.shopmanagement.entity.UserFcmToken;
import com.shopmanagement.repository.ContactViewRepository;
import com.shopmanagement.repository.UserFcmTokenRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class ContactViewService {

    private final ContactViewRepository contactViewRepository;
    private final UserRepository userRepository;
    private final UserFcmTokenRepository userFcmTokenRepository;
    private final FirebaseNotificationService firebaseNotificationService;

    @Transactional
    public ContactView logView(Long viewerUserId, ContactViewRequest req) {
        String viewerName = null;
        String viewerPhone = null;

        try {
            User viewer = userRepository.findById(viewerUserId).orElse(null);
            if (viewer != null) {
                String firstName = viewer.getFirstName() != null ? viewer.getFirstName() : "";
                String lastName = viewer.getLastName() != null ? viewer.getLastName() : "";
                viewerName = (firstName + " " + lastName).trim();
                if (viewerName.isEmpty()) {
                    viewerName = viewer.getUsername();
                }
                viewerPhone = viewer.getMobileNumber();
            }
        } catch (Exception e) {
            log.warn("Could not fetch viewer details for userId {}: {}", viewerUserId, e.getMessage());
        }

        ContactView contactView = ContactView.builder()
                .viewerUserId(viewerUserId)
                .viewerName(viewerName)
                .viewerPhone(viewerPhone)
                .postType(req.getPostType())
                .postId(req.getPostId())
                .postTitle(req.getPostTitle())
                .sellerPhone(req.getSellerPhone())
                .build();

        ContactView saved = contactViewRepository.save(contactView);

        // Send push notification to post owner
        if (req.getOwnerUserId() != null && !req.getOwnerUserId().equals(viewerUserId)) {
            try {
                List<UserFcmToken> tokens = userFcmTokenRepository.findActiveTokensByUserId(req.getOwnerUserId());
                String title = "உங்கள் தொலைபேசி எண் பார்க்கப்பட்டது";
                String body = (viewerName != null ? viewerName : "ஒருவர்") + " உங்கள் தொலைபேசி எண்ணை பார்த்தார்";
                Map<String, String> data = Map.of(
                    "type", "CONTACT_VIEWED",
                    "postType", req.getPostType() != null ? req.getPostType() : "",
                    "postId", req.getPostId() != null ? req.getPostId().toString() : ""
                );
                for (UserFcmToken token : tokens) {
                    firebaseNotificationService.sendNotificationWithData(title, body, token.getFcmToken(), data);
                }
            } catch (Exception e) {
                log.warn("Failed to send contact view notification to owner {}: {}", req.getOwnerUserId(), e.getMessage());
            }
        }

        return saved;
    }

    public Page<ContactView> getAll(Pageable pageable) {
        return contactViewRepository.findAllByOrderByViewedAtDesc(pageable);
    }

    public List<ContactView> getByPost(String postType, Long postId) {
        return contactViewRepository.findByPostTypeAndPostIdOrderByViewedAtDesc(postType, postId);
    }

    @Transactional
    public void blockUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));
        user.setStatus(User.UserStatus.SUSPENDED);
        user.setIsActive(false);
        userRepository.save(user);
        log.info("User {} blocked (status=SUSPENDED, isActive=false)", userId);
    }
}
