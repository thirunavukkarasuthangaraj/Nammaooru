package com.shopmanagement.service;

import com.shopmanagement.entity.BusinessHours;
import com.shopmanagement.repository.BusinessHoursRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

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
        DayOfWeek currentDay = DayOfWeek.from(java.time.LocalDate.now());
        Optional<BusinessHours> businessHours = businessHoursRepository
            .findOpenHoursByShopIdAndDay(shopId, currentDay);
        
        return businessHours.map(BusinessHours::isOpenNow).orElse(false);
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