package com.shopmanagement.service;

import com.shopmanagement.entity.BusinessHours;
import com.shopmanagement.repository.BusinessHoursRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class BusinessHoursService {
    
    private final BusinessHoursRepository businessHoursRepository;
    
    public List<BusinessHours> getAllBusinessHoursByShop(Long shopId) {
        log.debug("Getting all business hours for shop ID: {}", shopId);
        return businessHoursRepository.findByShopIdOrderByDayOfWeek(shopId);
    }
    
    public List<BusinessHours> getOpenHoursByShop(Long shopId) {
        log.debug("Getting open hours for shop ID: {}", shopId);
        return businessHoursRepository.findOpenHoursByShopId(shopId);
    }
    
    public Optional<BusinessHours> getBusinessHoursByShopAndDay(Long shopId, DayOfWeek dayOfWeek) {
        log.debug("Getting business hours for shop ID: {} and day: {}", shopId, dayOfWeek);
        return businessHoursRepository.findByShopIdAndDayOfWeek(shopId, dayOfWeek);
    }
    
    public BusinessHours createBusinessHours(BusinessHours businessHours) {
        log.debug("Creating business hours for shop ID: {} and day: {}", 
                 businessHours.getShopId(), businessHours.getDayOfWeek());
        
        validateBusinessHours(businessHours);
        
        if (businessHoursRepository.existsByShopIdAndDayOfWeek(
                businessHours.getShopId(), businessHours.getDayOfWeek())) {
            throw new IllegalArgumentException(
                String.format("Business hours already exist for shop %d on %s", 
                             businessHours.getShopId(), businessHours.getDayOfWeek()));
        }
        
        return businessHoursRepository.save(businessHours);
    }
    
    public BusinessHours updateBusinessHours(Long id, BusinessHours updatedBusinessHours) {
        log.debug("Updating business hours with ID: {}", id);
        
        BusinessHours existingBusinessHours = businessHoursRepository.findById(id)
            .orElseThrow(() -> new EntityNotFoundException("Business hours not found with ID: " + id));
        
        validateBusinessHours(updatedBusinessHours);
        
        existingBusinessHours.setDayOfWeek(updatedBusinessHours.getDayOfWeek());
        existingBusinessHours.setOpenTime(updatedBusinessHours.getOpenTime());
        existingBusinessHours.setCloseTime(updatedBusinessHours.getCloseTime());
        existingBusinessHours.setIsOpen(updatedBusinessHours.getIsOpen());
        existingBusinessHours.setIs24Hours(updatedBusinessHours.getIs24Hours());
        existingBusinessHours.setBreakStartTime(updatedBusinessHours.getBreakStartTime());
        existingBusinessHours.setBreakEndTime(updatedBusinessHours.getBreakEndTime());
        existingBusinessHours.setSpecialNote(updatedBusinessHours.getSpecialNote());
        
        return businessHoursRepository.save(existingBusinessHours);
    }
    
    public void deleteBusinessHours(Long id) {
        log.debug("Deleting business hours with ID: {}", id);
        
        if (!businessHoursRepository.existsById(id)) {
            throw new EntityNotFoundException("Business hours not found with ID: " + id);
        }
        
        businessHoursRepository.deleteById(id);
    }
    
    public void deleteAllBusinessHoursByShop(Long shopId) {
        log.debug("Deleting all business hours for shop ID: {}", shopId);
        businessHoursRepository.deleteByShopId(shopId);
    }
    
    public boolean isShopOpenNow(Long shopId) {
        return isShopOpenNow(shopId, ZoneId.systemDefault());
    }
    
    public boolean isShopOpenNow(Long shopId, ZoneId timeZone) {
        LocalDateTime now = LocalDateTime.now(timeZone);
        DayOfWeek currentDay = now.getDayOfWeek();

        Optional<BusinessHours> businessHours = businessHoursRepository
            .findOpenHoursByShopIdAndDay(shopId, currentDay);

        // If no business hours configured, default to OPEN (available)
        // This allows shops without configured hours to be available
        return businessHours.map(hours -> isCurrentlyOpen(hours, now.toLocalTime())).orElse(true);
    }
    
    public Map<String, Object> getShopOpenStatus(Long shopId) {
        LocalDateTime now = LocalDateTime.now();
        DayOfWeek currentDay = now.getDayOfWeek();
        LocalTime currentTime = now.toLocalTime();
        
        Optional<BusinessHours> businessHours = businessHoursRepository
            .findOpenHoursByShopIdAndDay(shopId, currentDay);
        
        Map<String, Object> status = new HashMap<>();
        
        if (businessHours.isEmpty()) {
            status.put("isOpen", false);
            status.put("status", "CLOSED");
            status.put("message", "Business hours not configured for today");
            status.put("nextOpenTime", getNextOpenTime(shopId, now));
            return status;
        }
        
        BusinessHours hours = businessHours.get();
        boolean isCurrentlyOpen = isCurrentlyOpen(hours, currentTime);
        
        status.put("isOpen", isCurrentlyOpen);
        status.put("businessHours", hours);
        status.put("currentTime", currentTime);
        status.put("currentDay", currentDay.toString());
        
        if (!hours.getIsOpen()) {
            status.put("status", "CLOSED");
            status.put("message", "Closed today");
            status.put("nextOpenTime", getNextOpenTime(shopId, now));
        } else if (hours.getIs24Hours()) {
            status.put("status", "OPEN_24H");
            status.put("message", "Open 24 hours");
        } else if (isCurrentlyOpen) {
            if (isInBreakTime(hours, currentTime)) {
                status.put("status", "ON_BREAK");
                status.put("message", "On break");
                status.put("breakEndTime", hours.getBreakEndTime());
            } else {
                status.put("status", "OPEN");
                status.put("message", "Currently open");
                status.put("closeTime", hours.getCloseTime());
            }
        } else {
            if (currentTime.isBefore(hours.getOpenTime())) {
                status.put("status", "OPENS_LATER");
                status.put("message", "Opens later today");
                status.put("openTime", hours.getOpenTime());
            } else {
                status.put("status", "CLOSED_FOR_DAY");
                status.put("message", "Closed for the day");
                status.put("nextOpenTime", getNextOpenTime(shopId, now));
            }
        }
        
        return status;
    }
    
    private boolean isCurrentlyOpen(BusinessHours hours, LocalTime currentTime) {
        if (!hours.getIsOpen()) return false;
        if (hours.getIs24Hours()) return true;
        
        boolean withinBusinessHours = currentTime.isAfter(hours.getOpenTime()) && 
                                     currentTime.isBefore(hours.getCloseTime());
        
        if (!withinBusinessHours) return false;
        
        // Check if in break time
        return !isInBreakTime(hours, currentTime);
    }
    
    private boolean isInBreakTime(BusinessHours hours, LocalTime currentTime) {
        return hours.getBreakStartTime() != null && 
               hours.getBreakEndTime() != null &&
               currentTime.isAfter(hours.getBreakStartTime()) && 
               currentTime.isBefore(hours.getBreakEndTime());
    }
    
    private Map<String, Object> getNextOpenTime(Long shopId, LocalDateTime from) {
        LocalDate searchDate = from.toLocalDate();
        
        // Search for next 7 days
        for (int i = 0; i < 7; i++) {
            if (i > 0) {
                searchDate = searchDate.plusDays(1);
            }
            
            DayOfWeek dayOfWeek = searchDate.getDayOfWeek();
            Optional<BusinessHours> businessHours = businessHoursRepository
                .findOpenHoursByShopIdAndDay(shopId, dayOfWeek);
            
            if (businessHours.isPresent() && businessHours.get().getIsOpen()) {
                BusinessHours hours = businessHours.get();
                LocalDateTime nextOpen;
                
                if (hours.getIs24Hours()) {
                    nextOpen = searchDate.atStartOfDay();
                } else {
                    nextOpen = searchDate.atTime(hours.getOpenTime());
                }
                
                // If it's today and the time hasn't passed yet
                if (searchDate.equals(from.toLocalDate()) && nextOpen.isBefore(from)) {
                    continue;
                }
                
                return Map.of(
                    "date", searchDate,
                    "time", hours.getOpenTime(),
                    "dayOfWeek", dayOfWeek.toString(),
                    "dateTime", nextOpen
                );
            }
        }
        
        return Map.of("message", "No upcoming open times found");
    }
    
    public List<Map<String, Object>> getWeeklySchedule(Long shopId) {
        List<BusinessHours> allHours = businessHoursRepository.findByShopIdOrderByDayOfWeek(shopId);
        
        return allHours.stream().map(hours -> {
            Map<String, Object> dayInfo = new HashMap<>();
            dayInfo.put("dayOfWeek", hours.getDayOfWeek().toString());
            dayInfo.put("dayName", hours.getDayOfWeek().toString());
            dayInfo.put("isOpen", hours.getIsOpen());
            
            if (hours.getIsOpen()) {
                if (hours.getIs24Hours()) {
                    dayInfo.put("schedule", "24 Hours");
                    dayInfo.put("is24Hours", true);
                } else {
                    dayInfo.put("openTime", hours.getOpenTime());
                    dayInfo.put("closeTime", hours.getCloseTime());
                    dayInfo.put("schedule", hours.getOpenTime() + " - " + hours.getCloseTime());
                    dayInfo.put("is24Hours", false);
                    
                    if (hours.getBreakStartTime() != null && hours.getBreakEndTime() != null) {
                        dayInfo.put("breakTime", hours.getBreakStartTime() + " - " + hours.getBreakEndTime());
                    }
                }
            } else {
                dayInfo.put("schedule", "Closed");
            }
            
            dayInfo.put("specialNote", hours.getSpecialNote());
            return dayInfo;
        }).collect(Collectors.toList());
    }
    
    public List<BusinessHours> createDefaultBusinessHours(Long shopId) {
        log.debug("Creating default business hours for shop ID: {}", shopId);
        
        List<BusinessHours> defaultHours = List.of(
            createDefaultHour(shopId, DayOfWeek.MONDAY),
            createDefaultHour(shopId, DayOfWeek.TUESDAY),
            createDefaultHour(shopId, DayOfWeek.WEDNESDAY),
            createDefaultHour(shopId, DayOfWeek.THURSDAY),
            createDefaultHour(shopId, DayOfWeek.FRIDAY),
            createDefaultHour(shopId, DayOfWeek.SATURDAY),
            createDefaultHour(shopId, DayOfWeek.SUNDAY)
        );
        
        return businessHoursRepository.saveAll(defaultHours);
    }
    
    private BusinessHours createDefaultHour(Long shopId, DayOfWeek dayOfWeek) {
        LocalTime defaultOpenTime = LocalTime.of(9, 0);
        LocalTime defaultCloseTime = LocalTime.of(21, 0);
        boolean isWeekend = dayOfWeek == DayOfWeek.SATURDAY || dayOfWeek == DayOfWeek.SUNDAY;
        
        return BusinessHours.builder()
            .shopId(shopId)
            .dayOfWeek(dayOfWeek)
            .openTime(defaultOpenTime)
            .closeTime(defaultCloseTime)
            .isOpen(!isWeekend)
            .is24Hours(false)
            .build();
    }
    
    private void validateBusinessHours(BusinessHours businessHours) {
        if (businessHours.getShopId() == null) {
            throw new IllegalArgumentException("Shop ID cannot be null");
        }
        
        if (businessHours.getDayOfWeek() == null) {
            throw new IllegalArgumentException("Day of week cannot be null");
        }
        
        if (businessHours.getIsOpen() && !businessHours.getIs24Hours()) {
            if (businessHours.getOpenTime() == null) {
                throw new IllegalArgumentException("Open time cannot be null when shop is open and not 24 hours");
            }
            
            if (businessHours.getCloseTime() == null) {
                throw new IllegalArgumentException("Close time cannot be null when shop is open and not 24 hours");
            }
            
            if (businessHours.getOpenTime().isAfter(businessHours.getCloseTime())) {
                throw new IllegalArgumentException("Open time cannot be after close time");
            }
        }
        
        if (businessHours.getBreakStartTime() != null && businessHours.getBreakEndTime() != null) {
            if (businessHours.getBreakStartTime().isAfter(businessHours.getBreakEndTime())) {
                throw new IllegalArgumentException("Break start time cannot be after break end time");
            }
            
            if (businessHours.getOpenTime() != null && businessHours.getCloseTime() != null) {
                if (businessHours.getBreakStartTime().isBefore(businessHours.getOpenTime()) ||
                    businessHours.getBreakEndTime().isAfter(businessHours.getCloseTime())) {
                    throw new IllegalArgumentException("Break times must be within business hours");
                }
            }
        }
    }
}