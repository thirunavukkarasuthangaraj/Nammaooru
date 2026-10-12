package com.shopmanagement.service;

import com.shopmanagement.entity.Order;
import com.shopmanagement.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Hands scheduled orders to the shop when their delivery window approaches.
 *
 * A scheduled order is an ordinary order that stays invisible until its time. It sits in
 * SCHEDULED, which keeps it out of the shop owner's pending list and, just as importantly,
 * stops the till ringing: that app now alerts like an incoming call for every new pending
 * order, so a midnight order for a 10am window would wake someone at midnight and then
 * look ten hours overdue.
 *
 * This job performs the single transition that ends that. Once an order reaches PENDING it
 * travels the existing pipeline unchanged - preparation, driver assignment, delivery.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ScheduledOrderReleaseService {

    private final OrderRepository orderRepository;
    private final SettingService settingService;
    private final ShopOrderNotificationService shopOrderNotificationService;

    /**
     * Every five minutes. The window only needs to be accurate to within the release lead
     * (an hour by default), so polling more often buys nothing.
     */
    @Scheduled(cron = "0 */5 * * * *")
    @Transactional
    public void releaseDueOrders() {
        if (!Boolean.parseBoolean(
                settingService.getSettingValue("order.scheduled.enabled", "true"))) {
            return;
        }

        int leadMinutes;
        try {
            leadMinutes = Integer.parseInt(
                    settingService.getSettingValue("order.scheduled.release_lead_minutes", "60"));
        } catch (NumberFormatException e) {
            leadMinutes = 60;
        }

        // Release anything whose window starts within the lead time. A 10am delivery with a
        // 60 minute lead reaches the shop at 9am, giving them time to prepare; handing it
        // over at 10am would be useless.
        LocalDateTime releaseBefore = LocalDateTime.now().plusMinutes(leadMinutes);

        List<Order> due = orderRepository.findScheduledDueForRelease(releaseBefore);
        if (due.isEmpty()) return;

        int released = 0;
        for (Order order : due) {
            try {
                order.setStatus(Order.OrderStatus.PENDING);
                order.setUpdatedBy("scheduler");
                orderRepository.save(order);

                // Only now does the shop hear about it. Deliberately after the save, so a
                // failed notification cannot leave an order that rang but never moved.
                notifyShop(order);
                released++;
            } catch (Exception e) {
                // One bad order must not stop the rest of the batch.
                log.error("Failed to release scheduled order {}", order.getId(), e);
            }
        }

        log.info("Released {} scheduled order(s) due before {}", released, releaseBefore);
    }

    private void notifyShop(Order order) {
        try {
            shopOrderNotificationService.notifyNewOrder(order);
        } catch (Exception e) {
            log.error("Scheduled order {} released but the shop was not notified",
                    order.getId(), e);
        }
    }
}
