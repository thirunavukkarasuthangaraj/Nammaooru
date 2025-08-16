package com.shopmanagement.dto.analytics;

import com.shopmanagement.entity.Analytics;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AnalyticsRequest {
    
    @NotNull(message = "Period type is required")
    private Analytics.PeriodType periodType;
    
    @NotNull(message = "Start date is required")
    private LocalDateTime startDate;
    
    @NotNull(message = "End date is required")
    private LocalDateTime endDate;
    
    private Long shopId;
    
    private String category;
    
    private Analytics.MetricType metricType;
}