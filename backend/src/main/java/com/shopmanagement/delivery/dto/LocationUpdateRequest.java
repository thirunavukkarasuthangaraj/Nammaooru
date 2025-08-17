package com.shopmanagement.delivery.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class LocationUpdateRequest {

    @NotNull(message = "Assignment ID is required")
    private Long assignmentId;

    @NotNull(message = "Latitude is required")
    @DecimalMin(value = "-90.0", message = "Latitude must be between -90 and 90")
    @DecimalMax(value = "90.0", message = "Latitude must be between -90 and 90")
    private BigDecimal latitude;

    @NotNull(message = "Longitude is required")
    @DecimalMin(value = "-180.0", message = "Longitude must be between -180 and 180")
    @DecimalMax(value = "180.0", message = "Longitude must be between -180 and 180")
    private BigDecimal longitude;

    @DecimalMin(value = "0.0", message = "Accuracy must be non-negative")
    private BigDecimal accuracy;

    private BigDecimal altitude;

    @DecimalMin(value = "0.0", message = "Speed must be non-negative")
    private BigDecimal speed;

    @DecimalMin(value = "0.0", message = "Heading must be between 0 and 360")
    @DecimalMax(value = "360.0", message = "Heading must be between 0 and 360")
    private BigDecimal heading;

    private LocalDateTime trackedAt;

    @Min(value = 0, message = "Battery level must be between 0 and 100")
    @Max(value = 100, message = "Battery level must be between 0 and 100")
    private Integer batteryLevel;

    private Boolean isMoving;

    private LocalDateTime estimatedArrivalTime;

    @DecimalMin(value = "0.0", message = "Distance to destination must be non-negative")
    private BigDecimal distanceToDestination;
}