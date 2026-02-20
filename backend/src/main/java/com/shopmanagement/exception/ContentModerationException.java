package com.shopmanagement.exception;

public class ContentModerationException extends RuntimeException {

    public ContentModerationException(String message) {
        super(message);
    }

    public ContentModerationException(String message, Throwable cause) {
        super(message, cause);
    }
}
