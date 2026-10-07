package com.shopmanagement.dto.user;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Lightweight row for admin "pick a customer" autocompletes (e.g. the push
 * notification sender). {@code id} is the {@code users.id} of a role=USER
 * account, which is what notification recipientId / FCM token lookup expects.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerPickerResponse {

    private Long id;
    private String fullName;
    private String mobileNumber;
    private String email;

    /** Best-effort "village/area, city, pincode" from the linked customer record; may be null. */
    private String location;
}
