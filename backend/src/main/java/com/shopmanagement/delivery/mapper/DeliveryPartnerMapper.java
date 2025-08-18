package com.shopmanagement.delivery.mapper;

import com.shopmanagement.delivery.dto.DeliveryPartnerResponse;
import com.shopmanagement.delivery.dto.OrderAssignmentResponse;
import com.shopmanagement.delivery.dto.DeliveryTrackingResponse;
import com.shopmanagement.delivery.entity.DeliveryPartner;
import com.shopmanagement.delivery.entity.OrderAssignment;
import com.shopmanagement.delivery.entity.DeliveryTracking;
import com.shopmanagement.delivery.repository.DeliveryPartnerDocumentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class DeliveryPartnerMapper {

    private final DeliveryPartnerDocumentRepository documentRepository;

    public DeliveryPartnerResponse toResponse(DeliveryPartner partner) {
        if (partner == null) {
            return null;
        }

        // Get document verification status
        Long totalDocuments = documentRepository.countTotalDocumentsByPartner(partner.getId());
        Long verifiedDocuments = documentRepository.countVerifiedDocumentsByPartner(partner.getId());

        return DeliveryPartnerResponse.builder()
                .id(partner.getId())
                .partnerId(partner.getPartnerId())
                .fullName(partner.getFullName())
                .phoneNumber(partner.getPhoneNumber())
                .alternatePhone(partner.getAlternatePhone())
                .email(partner.getEmail())
                .dateOfBirth(partner.getDateOfBirth())
                .gender(partner.getGender())
                .addressLine1(partner.getAddressLine1())
                .addressLine2(partner.getAddressLine2())
                .city(partner.getCity())
                .state(partner.getState())
                .postalCode(partner.getPostalCode())
                .country(partner.getCountry())
                .vehicleType(partner.getVehicleType())
                .vehicleNumber(partner.getVehicleNumber())
                .vehicleModel(partner.getVehicleModel())
                .vehicleColor(partner.getVehicleColor())
                .licenseNumber(partner.getLicenseNumber())
                .licenseExpiryDate(partner.getLicenseExpiryDate())
                .bankAccountNumber(maskBankAccount(partner.getBankAccountNumber()))
                .bankIfscCode(partner.getBankIfscCode())
                .bankName(partner.getBankName())
                .accountHolderName(partner.getAccountHolderName())
                .maxDeliveryRadius(partner.getMaxDeliveryRadius())
                .status(partner.getStatus())
                .verificationStatus(partner.getVerificationStatus())
                .isOnline(partner.getIsOnline())
                .isAvailable(partner.getIsAvailable())
                .rating(partner.getRating())
                .totalDeliveries(partner.getTotalDeliveries())
                .successfulDeliveries(partner.getSuccessfulDeliveries())
                .totalEarnings(partner.getTotalEarnings())
                .successRate(partner.getSuccessRate())
                .currentLatitude(partner.getCurrentLatitude())
                .currentLongitude(partner.getCurrentLongitude())
                .lastLocationUpdate(partner.getLastLocationUpdate())
                .emergencyContactName(partner.getEmergencyContactName())
                .emergencyContactPhone(partner.getEmergencyContactPhone())
                .profileImageUrl(partner.getProfileImageUrl())
                .createdAt(partner.getCreatedAt())
                .updatedAt(partner.getUpdatedAt())
                .createdBy(partner.getCreatedBy())
                .updatedBy(partner.getUpdatedBy())
                .totalDocuments(totalDocuments)
                .verifiedDocuments(verifiedDocuments)
                .allDocumentsVerified(totalDocuments > 0 && totalDocuments.equals(verifiedDocuments))
                .build();
    }

    public OrderAssignmentResponse toAssignmentResponse(OrderAssignment assignment) {
        if (assignment == null) {
            return null;
        }

        // Calculate timing information
        Long totalTimeMinutes = null;
        Long deliveryTimeMinutes = null;
        Boolean isDelayed = false;

        if (assignment.getDeliveryTime() != null && assignment.getAssignedAt() != null) {
            totalTimeMinutes = Duration.between(assignment.getAssignedAt(), assignment.getDeliveryTime()).toMinutes();
        }

        if (assignment.getDeliveryTime() != null && assignment.getPickupTime() != null) {
            deliveryTimeMinutes = Duration.between(assignment.getPickupTime(), assignment.getDeliveryTime()).toMinutes();
        }

        // Get latest tracking info
        BigDecimal currentLatitude = null;
        BigDecimal currentLongitude = null;
        LocalDateTime lastLocationUpdate = null;
        BigDecimal distanceToDestination = null;
        LocalDateTime estimatedArrivalTime = null;

        try {
            if (assignment.getTrackingPoints() != null && !assignment.getTrackingPoints().isEmpty()) {
                DeliveryTracking latestTracking = assignment.getTrackingPoints().get(0);
                currentLatitude = latestTracking.getLatitude();
                currentLongitude = latestTracking.getLongitude();
                lastLocationUpdate = latestTracking.getTrackedAt();
                distanceToDestination = latestTracking.getDistanceToDestination();
                estimatedArrivalTime = latestTracking.getEstimatedArrivalTime();
            }
        } catch (Exception e) {
            // Ignore lazy loading errors - tracking points will be empty
        }

        return OrderAssignmentResponse.builder()
                .id(assignment.getId())
                .orderId(assignment.getOrder().getId())
                .orderNumber(assignment.getOrder().getOrderNumber())
                .partnerId(assignment.getDeliveryPartner().getId())
                .partnerName(assignment.getDeliveryPartner().getFullName())
                .partnerPhone(assignment.getDeliveryPartner().getPhoneNumber())
                .assignedAt(assignment.getAssignedAt())
                .assignedBy(assignment.getAssignedBy() != null ? assignment.getAssignedBy().getId() : null)
                .assignedByName(assignment.getAssignedBy() != null ? assignment.getAssignedBy().getFullName() : null)
                .assignmentType(assignment.getAssignmentType())
                .status(assignment.getStatus())
                .acceptedAt(assignment.getAcceptedAt())
                .pickupTime(assignment.getPickupTime())
                .deliveryTime(assignment.getDeliveryTime())
                .pickupLatitude(assignment.getPickupLatitude())
                .pickupLongitude(assignment.getPickupLongitude())
                .deliveryLatitude(assignment.getDeliveryLatitude())
                .deliveryLongitude(assignment.getDeliveryLongitude())
                .deliveryFee(assignment.getDeliveryFee())
                .partnerCommission(assignment.getPartnerCommission())
                .rejectionReason(assignment.getRejectionReason())
                .deliveryNotes(assignment.getDeliveryNotes())
                .customerRating(assignment.getCustomerRating())
                .customerFeedback(assignment.getCustomerFeedback())
                .currentLatitude(currentLatitude)
                .currentLongitude(currentLongitude)
                .lastLocationUpdate(lastLocationUpdate)
                .distanceToDestination(distanceToDestination)
                .estimatedArrivalTime(estimatedArrivalTime)
                .totalTimeMinutes(totalTimeMinutes)
                .deliveryTimeMinutes(deliveryTimeMinutes)
                .isDelayed(isDelayed)
                .createdAt(assignment.getCreatedAt())
                .updatedAt(assignment.getUpdatedAt())
                .build();
    }

    public DeliveryTrackingResponse toTrackingResponse(DeliveryTracking tracking) {
        if (tracking == null) {
            return null;
        }

        OrderAssignment assignment = tracking.getOrderAssignment();
        DeliveryPartner partner = assignment.getDeliveryPartner();

        return DeliveryTrackingResponse.builder()
                .id(tracking.getId())
                .assignmentId(assignment.getId())
                .orderNumber(assignment.getOrder().getOrderNumber())
                .latitude(tracking.getLatitude())
                .longitude(tracking.getLongitude())
                .accuracy(tracking.getAccuracy())
                .altitude(tracking.getAltitude())
                .speed(tracking.getSpeed())
                .heading(tracking.getHeading())
                .trackedAt(tracking.getTrackedAt())
                .batteryLevel(tracking.getBatteryLevel())
                .isMoving(tracking.getIsMoving())
                .estimatedArrivalTime(tracking.getEstimatedArrivalTime())
                .distanceToDestination(tracking.getDistanceToDestination())
                .partnerName(partner.getFullName())
                .partnerPhone(partner.getPhoneNumber())
                .vehicleType(partner.getVehicleType().toString())
                .vehicleNumber(partner.getVehicleNumber())
                .customerName(assignment.getOrder().getCustomer().getFullName())
                .customerPhone(assignment.getOrder().getCustomer().getMobileNumber())
                .deliveryAddress(assignment.getOrder().getDeliveryAddress())
                .orderStatus(assignment.getOrder().getStatus().toString())
                .assignmentStatus(assignment.getStatus().toString())
                .build();
    }

    public List<DeliveryTrackingResponse.TrackingPoint> toTrackingPoints(List<DeliveryTracking> trackingList) {
        if (trackingList == null) {
            return List.of();
        }

        return trackingList.stream()
                .map(tracking -> DeliveryTrackingResponse.TrackingPoint.builder()
                        .latitude(tracking.getLatitude())
                        .longitude(tracking.getLongitude())
                        .trackedAt(tracking.getTrackedAt())
                        .speed(tracking.getSpeed())
                        .isMoving(tracking.getIsMoving())
                        .build())
                .collect(Collectors.toList());
    }

    private String maskBankAccount(String accountNumber) {
        if (accountNumber == null || accountNumber.length() <= 4) {
            return accountNumber;
        }
        return "*".repeat(accountNumber.length() - 4) + accountNumber.substring(accountNumber.length() - 4);
    }
}