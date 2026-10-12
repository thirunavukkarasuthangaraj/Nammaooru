package com.shopmanagement.service;

import com.shopmanagement.entity.BusinessHours;
import com.shopmanagement.entity.DeliveryHours;
import com.shopmanagement.repository.BusinessHoursRepository;
import com.shopmanagement.repository.DeliveryHoursRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * When a shop can DELIVER, as opposed to when it is open.
 *
 * Kept deliberately thin and shaped like BusinessHoursService, because the web screen for
 * editing these is a copy of the opening-hours screen and the two should behave the same.
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class DeliveryHoursService {

    private final DeliveryHoursRepository deliveryHoursRepository;
    private final BusinessHoursRepository businessHoursRepository;

    @Transactional(readOnly = true)
    public List<DeliveryHours> getByShop(Long shopId) {
        return deliveryHoursRepository.findByShopId(shopId);
    }

    @Transactional(readOnly = true)
    public Optional<DeliveryHours> getByShopAndDay(Long shopId, DayOfWeek day) {
        return deliveryHoursRepository.findByShopIdAndDayOfWeek(shopId, day);
    }

    /**
     * Replace a shop's whole week in one call.
     *
     * The web screen edits seven days together, so saving them one at a time would leave
     * a half-updated week visible if the browser died mid-save.
     */
    public List<DeliveryHours> replaceWeek(Long shopId, List<DeliveryHours> week) {
        deliveryHoursRepository.deleteByShopId(shopId);
        deliveryHoursRepository.flush();

        List<DeliveryHours> saved = new ArrayList<>();
        for (DeliveryHours row : week) {
            row.setId(null);
            row.setShopId(shopId);
            saved.add(deliveryHoursRepository.save(row));
        }
        log.info("Replaced delivery hours for shop {} ({} days)", shopId, saved.size());
        return saved;
    }

    /**
     * Copy the shop's opening hours across as its delivery hours.
     *
     * Backs the "Same as opening hours" toggle. Most shops never need the two to differ,
     * so the screen defaults to this rather than making every shop fill in a second form.
     */
    public List<DeliveryHours> copyFromBusinessHours(Long shopId) {
        List<BusinessHours> opening = businessHoursRepository.findByShopId(shopId);
        if (opening.isEmpty()) {
            log.warn("Shop {} has no opening hours to copy from", shopId);
            return List.of();
        }

        List<DeliveryHours> week = new ArrayList<>();
        for (BusinessHours bh : opening) {
            week.add(DeliveryHours.builder()
                    .shopId(shopId)
                    .dayOfWeek(bh.getDayOfWeek())
                    .openTime(bh.getOpenTime())
                    .closeTime(bh.getCloseTime())
                    .breakStartTime(bh.getBreakStartTime())
                    .breakEndTime(bh.getBreakEndTime())
                    .isOpen(bh.getIsOpen() == null || bh.getIsOpen())
                    .is24Hours(Boolean.TRUE.equals(bh.getIs24Hours()))
                    .createdBy("system")
                    .updatedBy("system")
                    .build());
        }
        return replaceWeek(shopId, week);
    }

    /**
     * True when this shop's delivery hours are identical to its opening hours, which is
     * what the screen's "Same as opening hours" toggle reflects on load.
     */
    @Transactional(readOnly = true)
    public boolean matchesBusinessHours(Long shopId) {
        List<DeliveryHours> delivery = deliveryHoursRepository.findByShopId(shopId);
        List<BusinessHours> opening = businessHoursRepository.findByShopId(shopId);
        if (delivery.size() != opening.size() || delivery.isEmpty()) return false;

        for (BusinessHours bh : opening) {
            Optional<DeliveryHours> match = delivery.stream()
                    .filter(d -> d.getDayOfWeek() == bh.getDayOfWeek())
                    .findFirst();
            if (match.isEmpty()) return false;
            DeliveryHours dh = match.get();
            if (!sameTime(dh.getOpenTime(), bh.getOpenTime())) return false;
            if (!sameTime(dh.getCloseTime(), bh.getCloseTime())) return false;
            if (!sameTime(dh.getBreakStartTime(), bh.getBreakStartTime())) return false;
            if (!sameTime(dh.getBreakEndTime(), bh.getBreakEndTime())) return false;
        }
        return true;
    }

    private boolean sameTime(java.time.LocalTime a, java.time.LocalTime b) {
        return a == null ? b == null : a.equals(b);
    }
}
