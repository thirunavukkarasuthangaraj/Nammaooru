package com.shopmanagement.service;

import com.shopmanagement.dto.order.DeliverySlot;
import com.shopmanagement.entity.DeliveryHours;
import com.shopmanagement.entity.Order;
import com.shopmanagement.repository.DeliveryHoursRepository;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.repository.ShopRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Builds the delivery windows a customer may choose.
 *
 * Windows are sliced from the shop's DELIVERY hours, never invented and never taken from
 * opening hours. That is the whole safety argument: a shop open 9 to 9 that delivers only
 * 10 to 7 can never be offered an 8pm window, because no such window is generated.
 *
 * A window is offered only when all of these hold:
 *   - it falls inside delivery hours for that day, outside any break
 *   - there is still time to prepare for it (preparation time + release lead)
 *   - the shop has not already filled it (max orders per slot)
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DeliverySlotService {

    private final DeliveryHoursRepository deliveryHoursRepository;
    private final OrderRepository orderRepository;
    private final ShopRepository shopRepository;
    private final SettingService settingService;
    private final BusinessHoursService businessHoursService;

    private static final DateTimeFormatter TIME_LABEL = DateTimeFormatter.ofPattern("h:mm a");

    private int setting(String key, int fallback) {
        try {
            return Integer.parseInt(settingService.getSettingValue(key, String.valueOf(fallback)));
        } catch (NumberFormatException e) {
            return fallback;
        }
    }

    /**
     * Windows this shop can still honour, soonest first, with an express option at the
     * front when the order could genuinely be delivered now.
     */
    @Transactional(readOnly = true)
    public List<DeliverySlot> getAvailableSlots(Long shopId) {
        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new RuntimeException("Shop not found"));

        int slotMinutes = setting("order.slot.length_minutes", 120);
        int daysAhead = setting("order.slot.days_ahead", 3);
        int leadMinutes = setting("order.scheduled.release_lead_minutes", 60);
        int prepMinutes = shop.getPreparationTimeMinutes() != null
                ? shop.getPreparationTimeMinutes() : 20;
        int capacity = shop.getMaxOrdersPerSlot() != null ? shop.getMaxOrdersPerSlot() : 10;

        LocalDateTime now = LocalDateTime.now();
        // Nothing can be delivered sooner than it can be prepared, and the shop needs the
        // order in hand before the window opens.
        LocalDateTime earliest = now.plusMinutes(prepMinutes + leadMinutes);

        List<DeliverySlot> slots = new ArrayList<>();

        if (isExpressPossible(shop, now, prepMinutes)) {
            slots.add(DeliverySlot.builder()
                    .express(true)
                    .available(true)
                    .dayLabel("Today")
                    .timeLabel("Deliver now")
                    .build());
        }

        for (int dayOffset = 0; dayOffset < daysAhead; dayOffset++) {
            LocalDate date = now.toLocalDate().plusDays(dayOffset);
            Optional<DeliveryHours> hoursOpt =
                    deliveryHoursRepository.findByShopIdAndDayOfWeek(shopId, date.getDayOfWeek());

            // No row for a day means this shop does not deliver that day. Absence is a
            // decision here, not a gap to paper over with a default.
            if (hoursOpt.isEmpty()) continue;

            DeliveryHours hours = hoursOpt.get();
            if (Boolean.FALSE.equals(hours.getIsOpen())) continue;

            boolean allDay = Boolean.TRUE.equals(hours.getIs24Hours());
            LocalTime open = allDay ? LocalTime.MIDNIGHT : hours.getOpenTime();
            LocalTime close = allDay ? LocalTime.of(23, 59) : hours.getCloseTime();
            if (open == null || close == null || !open.isBefore(close)) continue;

            for (LocalTime start = open;
                 !start.plusMinutes(slotMinutes).isAfter(close);
                 start = start.plusMinutes(slotMinutes)) {

                LocalTime end = start.plusMinutes(slotMinutes);
                LocalDateTime from = LocalDateTime.of(date, start);
                LocalDateTime until = LocalDateTime.of(date, end);

                if (from.isBefore(earliest)) continue;
                if (overlapsBreak(hours, start, end)) continue;

                long booked = orderRepository.countScheduledInSlot(shopId, from, Order.OrderStatus.SCHEDULED);

                slots.add(DeliverySlot.builder()
                        .from(from)
                        .until(until)
                        .dayLabel(dayLabel(date, now.toLocalDate()))
                        .timeLabel(start.format(TIME_LABEL) + " - " + end.format(TIME_LABEL))
                        .booked((int) booked)
                        .capacity(capacity)
                        .available(booked < capacity)
                        .express(false)
                        .build());
            }
        }

        return slots;
    }

    /**
     * Express is offered only when the shop is open, delivery hours are current, and the
     * order would be ready before delivery stops for the day.
     */
    private boolean isExpressPossible(Shop shop, LocalDateTime now, int prepMinutes) {
        if (!businessHoursService.isShopOpenNow(shop.getId())) return false;

        Optional<DeliveryHours> hoursOpt = deliveryHoursRepository
                .findByShopIdAndDayOfWeek(shop.getId(), now.getDayOfWeek());
        if (hoursOpt.isEmpty()) return false;

        DeliveryHours hours = hoursOpt.get();
        if (Boolean.FALSE.equals(hours.getIsOpen())) return false;
        if (Boolean.TRUE.equals(hours.getIs24Hours())) return true;
        if (hours.getOpenTime() == null || hours.getCloseTime() == null) return false;

        LocalTime nowTime = now.toLocalTime();
        LocalTime readyAt = nowTime.plusMinutes(prepMinutes);
        return !nowTime.isBefore(hours.getOpenTime())
                && readyAt.isBefore(hours.getCloseTime())
                && !overlapsBreak(hours, nowTime, readyAt);
    }

    private boolean overlapsBreak(DeliveryHours hours, LocalTime start, LocalTime end) {
        if (hours.getBreakStartTime() == null || hours.getBreakEndTime() == null) return false;
        return start.isBefore(hours.getBreakEndTime()) && end.isAfter(hours.getBreakStartTime());
    }

    private String dayLabel(LocalDate date, LocalDate today) {
        if (date.equals(today)) return "Today";
        if (date.equals(today.plusDays(1))) return "Tomorrow";
        return date.format(DateTimeFormatter.ofPattern("EEE, d MMM"));
    }

    /**
     * Re-check a window the customer picked, at the moment the order is placed.
     *
     * Never trust the window the app sends. An app left open overnight will happily
     * submit a window that has since passed or filled up.
     */
    @Transactional(readOnly = true)
    public void validateSlot(Long shopId, LocalDateTime from, LocalDateTime until) {
        if (from == null || until == null || !from.isBefore(until)) {
            throw new RuntimeException("Please choose a delivery time.");
        }

        boolean stillOffered = getAvailableSlots(shopId).stream()
                .anyMatch(s -> !s.isExpress()
                        && from.equals(s.getFrom())
                        && until.equals(s.getUntil())
                        && s.isAvailable());

        if (!stillOffered) {
            throw new RuntimeException(
                    "That delivery time is no longer available. Please pick another slot.");
        }
    }
}
