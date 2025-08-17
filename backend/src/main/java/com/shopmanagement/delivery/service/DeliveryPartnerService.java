package com.shopmanagement.delivery.service;

import com.shopmanagement.delivery.dto.*;
import com.shopmanagement.delivery.entity.DeliveryPartner;
import com.shopmanagement.delivery.mapper.DeliveryPartnerMapper;
import com.shopmanagement.delivery.repository.DeliveryPartnerRepository;
import com.shopmanagement.delivery.repository.DeliveryPartnerDocumentRepository;
import com.shopmanagement.entity.User;
import com.shopmanagement.dto.user.UserRequest;
import com.shopmanagement.service.UserService;
import com.shopmanagement.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class DeliveryPartnerService {

    private final DeliveryPartnerRepository deliveryPartnerRepository;
    private final DeliveryPartnerDocumentRepository documentRepository;
    private final UserService userService;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final DeliveryPartnerMapper mapper;

    @Transactional
    public DeliveryPartnerResponse registerPartner(DeliveryPartnerRegistrationRequest request) {
        log.info("Registering new delivery partner: {}", request.getEmail());

        // Validate unique constraints
        validateUniqueFields(request);

        // Create user account
        User user = createUserAccount(request);

        // Create delivery partner
        DeliveryPartner partner = createDeliveryPartner(request, user);

        DeliveryPartner savedPartner = deliveryPartnerRepository.save(partner);
        log.info("Successfully registered delivery partner with ID: {}", savedPartner.getPartnerId());

        return mapper.toResponse(savedPartner);
    }

    public Optional<DeliveryPartnerResponse> getPartnerById(Long id) {
        return deliveryPartnerRepository.findById(id)
                .map(mapper::toResponse);
    }

    public Optional<DeliveryPartnerResponse> getPartnerByPartnerId(String partnerId) {
        return deliveryPartnerRepository.findByPartnerId(partnerId)
                .map(mapper::toResponse);
    }

    public Optional<DeliveryPartnerResponse> getPartnerByUserId(Long userId) {
        return deliveryPartnerRepository.findByUserId(userId)
                .map(mapper::toResponse);
    }

    public Page<DeliveryPartnerResponse> getAllPartners(Pageable pageable) {
        return deliveryPartnerRepository.findAll(pageable)
                .map(mapper::toResponse);
    }

    public Page<DeliveryPartnerResponse> searchPartners(String searchTerm, Pageable pageable) {
        return deliveryPartnerRepository.searchPartners(searchTerm, pageable)
                .map(mapper::toResponse);
    }

    public List<DeliveryPartnerResponse> getPartnersByStatus(DeliveryPartner.PartnerStatus status) {
        return deliveryPartnerRepository.findByStatus(status)
                .stream()
                .map(mapper::toResponse)
                .toList();
    }

    public List<DeliveryPartnerResponse> getAvailablePartners() {
        return deliveryPartnerRepository.findAvailablePartners()
                .stream()
                .map(mapper::toResponse)
                .toList();
    }

    public List<DeliveryPartnerResponse> getNearbyPartners(BigDecimal latitude, BigDecimal longitude) {
        return deliveryPartnerRepository.findNearbyAvailablePartners(latitude, longitude)
                .stream()
                .map(mapper::toResponse)
                .toList();
    }

    @Transactional
    public DeliveryPartnerResponse updatePartnerStatus(Long partnerId, DeliveryPartner.PartnerStatus status) {
        DeliveryPartner partner = getPartnerEntity(partnerId);
        partner.setStatus(status);
        partner.setUpdatedBy("system"); // Should be set to current user

        if (status == DeliveryPartner.PartnerStatus.ACTIVE) {
            log.info("Partner {} activated", partner.getPartnerId());
        } else {
            partner.setIsOnline(false);
            partner.setIsAvailable(false);
            log.info("Partner {} status changed to {}", partner.getPartnerId(), status);
        }

        DeliveryPartner savedPartner = deliveryPartnerRepository.save(partner);
        return mapper.toResponse(savedPartner);
    }

    @Transactional
    public DeliveryPartnerResponse updateVerificationStatus(Long partnerId, 
                                                          DeliveryPartner.VerificationStatus status) {
        DeliveryPartner partner = getPartnerEntity(partnerId);
        partner.setVerificationStatus(status);
        partner.setUpdatedBy("system"); // Should be set to current user

        log.info("Partner {} verification status changed to {}", partner.getPartnerId(), status);

        DeliveryPartner savedPartner = deliveryPartnerRepository.save(partner);
        return mapper.toResponse(savedPartner);
    }

    @Transactional
    public DeliveryPartnerResponse updateOnlineStatus(Long partnerId, boolean isOnline) {
        DeliveryPartner partner = getPartnerEntity(partnerId);
        partner.setIsOnline(isOnline);
        
        if (!isOnline) {
            partner.setIsAvailable(false);
        }

        log.info("Partner {} is now {}", partner.getPartnerId(), isOnline ? "online" : "offline");

        DeliveryPartner savedPartner = deliveryPartnerRepository.save(partner);
        return mapper.toResponse(savedPartner);
    }

    @Transactional
    public DeliveryPartnerResponse updateAvailabilityStatus(Long partnerId, boolean isAvailable) {
        DeliveryPartner partner = getPartnerEntity(partnerId);
        
        if (isAvailable && !partner.getIsOnline()) {
            throw new IllegalStateException("Partner must be online to become available");
        }
        
        partner.setIsAvailable(isAvailable);
        log.info("Partner {} availability changed to {}", partner.getPartnerId(), isAvailable);

        DeliveryPartner savedPartner = deliveryPartnerRepository.save(partner);
        return mapper.toResponse(savedPartner);
    }

    @Transactional
    public DeliveryPartnerResponse updateLocation(Long partnerId, BigDecimal latitude, BigDecimal longitude) {
        DeliveryPartner partner = getPartnerEntity(partnerId);
        partner.setCurrentLatitude(latitude);
        partner.setCurrentLongitude(longitude);
        partner.setLastLocationUpdate(LocalDateTime.now());

        DeliveryPartner savedPartner = deliveryPartnerRepository.save(partner);
        return mapper.toResponse(savedPartner);
    }

    @Transactional
    public void updateDeliveryStats(Long partnerId, boolean successful) {
        DeliveryPartner partner = getPartnerEntity(partnerId);
        partner.setTotalDeliveries(partner.getTotalDeliveries() + 1);
        
        if (successful) {
            partner.setSuccessfulDeliveries(partner.getSuccessfulDeliveries() + 1);
        }

        deliveryPartnerRepository.save(partner);
        log.info("Updated delivery stats for partner {}: total={}, successful={}", 
                partner.getPartnerId(), partner.getTotalDeliveries(), partner.getSuccessfulDeliveries());
    }

    @Transactional
    public void updateEarnings(Long partnerId, BigDecimal amount) {
        DeliveryPartner partner = getPartnerEntity(partnerId);
        partner.setTotalEarnings(partner.getTotalEarnings().add(amount));
        deliveryPartnerRepository.save(partner);
        
        log.info("Updated earnings for partner {}: total={}", 
                partner.getPartnerId(), partner.getTotalEarnings());
    }

    public Long getPartnerCountByStatus(DeliveryPartner.PartnerStatus status) {
        return deliveryPartnerRepository.countByStatus(status);
    }

    public List<DeliveryPartnerResponse> getPartnersWithExpiringLicenses(int days) {
        java.time.LocalDate targetDate = java.time.LocalDate.now().plusDays(days);
        return deliveryPartnerRepository.findPartnersWithExpiringLicenses(targetDate)
                .stream()
                .map(mapper::toResponse)
                .toList();
    }

    // Private helper methods

    private void validateUniqueFields(DeliveryPartnerRegistrationRequest request) {
        if (deliveryPartnerRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new IllegalArgumentException("Email already registered");
        }
        
        if (deliveryPartnerRepository.findByPhoneNumber(request.getPhoneNumber()).isPresent()) {
            throw new IllegalArgumentException("Phone number already registered");
        }
        
        if (deliveryPartnerRepository.findByVehicleNumber(request.getVehicleNumber()).isPresent()) {
            throw new IllegalArgumentException("Vehicle number already registered");
        }
        
        if (deliveryPartnerRepository.findByLicenseNumber(request.getLicenseNumber()).isPresent()) {
            throw new IllegalArgumentException("License number already registered");
        }
    }

    private User createUserAccount(DeliveryPartnerRegistrationRequest request) {
        User user = User.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .firstName(request.getFullName().split(" ")[0])
                .lastName(request.getFullName().contains(" ") ? 
                         request.getFullName().substring(request.getFullName().indexOf(" ") + 1) : "")
                .mobileNumber(request.getPhoneNumber())
                .role(User.UserRole.DELIVERY_PARTNER)
                .status(User.UserStatus.PENDING_VERIFICATION)
                .isActive(true)
                .build();

        User createdUser = userRepository.save(User.builder()
                .username(request.getEmail().split("@")[0])
                .email(request.getEmail())
                .password(passwordEncoder.encode("password"))
                .firstName(request.getFullName().split(" ")[0])
                .lastName(request.getFullName().contains(" ") ? request.getFullName().substring(request.getFullName().indexOf(" ") + 1) : "")
                .mobileNumber(request.getPhoneNumber())
                .role(User.UserRole.DELIVERY_PARTNER)
                .status(User.UserStatus.ACTIVE)
                .emailVerified(false)
                .mobileVerified(false)
                .isActive(true)
                .build());
        return createdUser;
    }

    private DeliveryPartner createDeliveryPartner(DeliveryPartnerRegistrationRequest request, User user) {
        return DeliveryPartner.builder()
                .user(user)
                .fullName(request.getFullName())
                .phoneNumber(request.getPhoneNumber())
                .alternatePhone(request.getAlternatePhone())
                .email(request.getEmail())
                .dateOfBirth(request.getDateOfBirth())
                .gender(request.getGender())
                .addressLine1(request.getAddressLine1())
                .addressLine2(request.getAddressLine2())
                .city(request.getCity())
                .state(request.getState())
                .postalCode(request.getPostalCode())
                .country(request.getCountry())
                .vehicleType(request.getVehicleType())
                .vehicleNumber(request.getVehicleNumber())
                .vehicleModel(request.getVehicleModel())
                .vehicleColor(request.getVehicleColor())
                .licenseNumber(request.getLicenseNumber())
                .licenseExpiryDate(request.getLicenseExpiryDate())
                .bankAccountNumber(request.getBankAccountNumber())
                .bankIfscCode(request.getBankIfscCode())
                .bankName(request.getBankName())
                .accountHolderName(request.getAccountHolderName())
                .maxDeliveryRadius(request.getMaxDeliveryRadius())
                .emergencyContactName(request.getEmergencyContactName())
                .emergencyContactPhone(request.getEmergencyContactPhone())
                .build();
    }

    private DeliveryPartner getPartnerEntity(Long partnerId) {
        return deliveryPartnerRepository.findById(partnerId)
                .orElseThrow(() -> new IllegalArgumentException("Delivery partner not found: " + partnerId));
    }
}