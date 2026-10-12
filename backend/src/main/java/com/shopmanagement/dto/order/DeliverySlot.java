package com.shopmanagement.dto.order;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * One offerable delivery window, derived from the shop's own business hours.
 *
 * Generated rather than configured: slicing the shop's real opening hours means a window
 * can never be offered for a time nobody is there, which is the failure that makes
 * scheduled delivery worse than refusing the order.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeliverySlot {

    private LocalDateTime from;
    private LocalDateTime until;

    /** "Today", "Tomorrow", or the date - for grouping the list in the app. */
    private String dayLabel;

    /** "9:00 AM - 11:00 AM" */
    private String timeLabel;

    /** False when the window is already at its order limit; shown greyed out, not hidden. */
    private boolean available;

    /** Orders already booked into this window, so the app can show "2 left". */
    private int booked;

    private int capacity;

    /**
     * True for the express option: the shop is open now and the order can arrive before
     * it closes. Carries no window; it follows the normal immediate pipeline.
     */
    private boolean express;
}
