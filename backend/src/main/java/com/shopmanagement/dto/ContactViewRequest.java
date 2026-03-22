package com.shopmanagement.dto;

import lombok.Data;

@Data
public class ContactViewRequest {
    private String postType;
    private Long postId;
    private String postTitle;
    private String sellerPhone;
    private Long ownerUserId; // post owner — to send push notification
}
